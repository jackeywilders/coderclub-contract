# MOMENT-ITEM-FROMID MomentItemVO 补 fromId——后端评审复核工作底稿

> 角色：后端评审（B-Review）
> 日期：2026-08-30
> 任务书：`pm/requirements/2026-08-30/moment-item-fromid-implementation-task.md`（已派发，PR #106 批次）
> 提案/决策：`proposals/frontend/2026-08-30/moment-item-fromid-proposal.md`（D3，PR #111，R2 main `b07ea765`）· `pm/reviews/2026-08-30/moment-item-fromid-decision.md`（PR #114，确认建议方案）
> 回执：`handoff/backend-to-frontend/2026-08-30/backend-moment-item-fromid-report.md` + `-summary.json`（PR #119，head `4592191`，已合入 main）
> 实施：CoderClub PR #18（head `1fbf0ad`，6 commits，**本会话复核通过后已合入 main `86a09e7e`，R2 达成**）

## 1. 人链核验：实施提交存在性与一致性

| 项 | 证据 | 结果 |
| --- | --- | --- |
| 提交对象 | `git cat-file -t 1fbf0ad83f…` 成功（走 7892 代理 fetch `feat/backend-moment-fromid`）；远端 PR #18 head 与本地对象一致 | ✅ |
| CI | PR #18 head `1fbf0ad`：build-and-test ✅（job 99288424752，run 33323104704）+ sensitive-scan ✅（job 99288424642）——GitHub API 逐 job 核实 | ✅ |
| 提交数 | **6 commits**（spec + plan + VO/组装实现 + 判别性断言修复 + openapi 登记 + 审查文档同步）——与回执一致 | ✅ |
| summary 一致性 | `implementationCommitSha=1fbf0ad`、PR #18、`sourceDoc lfSha256After=26AEC009…`、pathCount 75→75 与回执一致 | ✅ |
| PR #18 合入 | 本会话独立复核（CI 双绿 + 代码级复核 + 独立测试复验全过）后以 merge 方式合入 main（merge `86a09e7e`，B-Review 授权合入人身份）——**R2 达成**（main tip 核验 `86a09e7e`） | ✅ |

## 2. 代码级复核（对照回执 §2 与提案 D3 建议方案，实读源码 @ `1fbf0ad`）

| 核对项 | 证据 | 结果 |
| --- | --- | --- |
| **VO 字段** | `MomentItemVO.java` `nickName` 前插入 `private String fromId;`（javadoc：与 CommentNodeVO.fromId 同源；前端「本人动态」精确判定）；`MomentBO` 无同名属性 → 不参与 MapStruct 自动映射 | ✅ |
| **组装取值** | `ShareMomentController.getMoments` map lambda `vo.setFromId(bo.getCreatedBy());`——**取动态创建人登录标识**（`MomentBO.createdBy` 直取，与 createdTime 手动补齐先例同形态）；**未取** `StpUtil.getLoginIdAsString()`（当前查看者） | ✅ |
| **判别性断言** | `CircleContractTest.getMoments_返回分页与epoch毫秒`：`bo.setCreatedBy("2002")` + 断言 `$.data.list[0].fromId` = `"2002"`——与登录标识 `"2001"` 错开，误取 StpUtil 必失败（核心约束回归锚定） | ✅ |
| **源契约文档** | openapi `MomentItemVO` schema 补 `fromId`（string，description 注明与 CommentNodeVO.fromId 同源语义）+ getMoments 200 example 补 `"fromId": "2001"`；**路径数不变（75）**、schemas 119 | ✅ |
| **边界** | diff 仅 3 个代码文件（VO/Controller/Test）+ 2 个 superpowers 文档 + openapi 1 个；域层/其他端点/鉴权/错误码/`CommentNodeVO`/双键消费者零改动；`api/` 快照与 sync-manifest 未动（快照微同步由 PM 验收批次执行）；前端代码零改动 | ✅ |

## 3. 独立复验（本底稿复核时执行，附着 `1fbf0ad`）

采用 `git archive` 提取实施快照至隔离目录 `G:\Dev\backend\Club\CoderClub-review-1fbf0ad`（不动主工作区，无 worktree 操作），实跑：

| 命令/动作 | 结果 |
| --- | --- |
| 全量 `mvn install -DskipTests -q` | 通过（依赖链完整进入测试阶段） |
| CircleContractTest（含判别性 fromId 断言） | **23/23，零失败** |
| circle domain（ShareComment 11 + ShareMessage 7 + ShareMoment 10 + AuthUserDirectory 5 + SensitiveWord/WordFilter 等） | **42/42，零失败** |
| CircleApplicationContextTest（starter context） | **1/1** |
| BUILD | **SUCCESS，exit 0** |
| 源文档字节态 SHA | `git cat-file blob 1fbf0ad…:docs/api/coderclub-openapi.json`（LF 字节态）SHA256 = `26AEC009C4A823629DCC1D6EB5984773791BC3380407F846AAA7D4308F12CC90`——与回执 after 值逐字一致（before `24DC8414…` 为本批基线，本底稿复算吻合） |

## 4. 任务书措辞歧义核查（回执 §2.2 澄清点）

- **任务书 §1.2 字面**："circle 域动态列表组装处取**当前登录标识**填充 `fromId`"。
- **提案 D3 / PM 决策语义**：`fromId` = **动态创建人登录标识**（决策理由 1：契约缺口 = `MomentItemVO` 缺创建人标识字段，前端「本人动态显示删除入口」无法判定；建议方案 = 与 `CommentNodeVO.fromId` 同源，即创建人侧登录标识串）。
- **实现取 `bo.getCreatedBy()`（创建人）**，非当前查看者——符合提案/决策意图；若误按任务书字面取当前查看者，`fromId === String(当前用户 id)` 判定将恒真（所有动态误显删除入口），判别性断言（2002 vs 2001）已将该错误路径锚定为必失败。**B-Impl 澄清方向正确，签署采纳**。

## 5. 延后项核查（回执 §5，均为 Minor、不阻塞）

| # | 项 | 复核意见 |
| --- | --- | --- |
| 1 | openapi schema `fromId` 多行展开格式 vs 相邻短属性单行紧凑（纯风格） | 表述性，无 schema 语义影响；可随后续 openapi 编辑批次压缩，接受延后 |
| 2 | CircleContractTest 注入真实 MapStruct converter（非 mock） | 既有套件形态，非本批引入；真实映射更贴近运行时，维持观察 |
| 3 | openapi 200 example `fromId: "2001"` 与测试登录标识数值重合 | 示例展示值与实现文件一致；测试用判别性 `"2002"`，无语义问题，接受 |

## 6. 复核结论

**通过，签署。** 回执声明（6 提交、LF SHA `26AEC009`、75 路径不变、判别性断言、测试数字、边界遵守、快照衔接）与人链核验、代码实读、独立复验逐项一致；任务书措辞歧义澄清方向正确（判别性断言锚定创建人取值）；PR #18 已按授权合入 main（`86a09e7e`），R2 达成。未发现 [必须修复]/[建议修改] 问题。

## 7. 关联

- 任务书 · 提案 PR #111 · PM 决策 PR #114 · 回执 PR #119（head `4592191`）· 实施 CoderClub PR #18（merged `86a09e7e`）
- 后续：PM 验收 → 快照微同步（`MomentItemVO.fromId` 采纳，75 路径不变）→ F-Impl 小批（前端一行切换移除 D3 昵称临时兜底）
