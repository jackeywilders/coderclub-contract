# MOMENT-ITEM-FROMID MomentItemVO 补 fromId——后端评审复核签署

> 角色：后端评审（B-Review）
> 签署日期：2026-08-30
> 任务书：`pm/requirements/2026-08-30/moment-item-fromid-implementation-task.md`
> 提案/决策：`proposals/frontend/2026-08-30/moment-item-fromid-proposal.md`（D3，PR #111）· `pm/reviews/2026-08-30/moment-item-fromid-decision.md`（PR #114，确认建议方案）
> 回执：`handoff/backend-to-frontend/2026-08-30/backend-moment-item-fromid-report.md` + `-summary.json`（PR #119，head `4592191`，已合入 main）
> 工作底稿：`designs/backend/2026-08-30/moment-item-fromid-review-workpaper.md`
> 状态：**签署通过，转 PM 验收**

## 1. 复核结论

✅ **复核通过，签署本回执。** 实施 `1fbf0ad`（CoderClub PR #18，6 commits）经人链核验与独立复验与提案/决策相符：

- [x] **任务 1（VO）**：`MomentItemVO` 补 `fromId: string`——语义 = 动态创建人登录标识（与 `CommentNodeVO.fromId` 同源）；供前端「本人动态」精确判定（`fromId === String(当前用户 id)`）
- [x] **任务 2（组装）**：`getMoments` map lambda `vo.setFromId(bo.getCreatedBy())` 手动补齐——**取动态创建人**（非当前查看者；任务书字面措辞歧义澄清方向正确，与提案 D3/PM 决策意图一致）；域层零改动
- [x] **任务 3（契约测试）**：`CircleContractTest.getMoments_返回分页与epoch毫秒` 补判别性断言 `bo.setCreatedBy("2002")` + fromId=`"2002"`（与登录标识 `"2001"` 错开——误取 StpUtil 必失败，核心约束回归锚定）
- [x] **任务 4（源契约文档）**：`MomentItemVO` schema + getMoments 200 example 双处登记 `fromId`（string）；路径数不变（75）；LF SHA `24DC8414… → 26AEC009…`（`git cat-file` 字节态独立计算，逐字一致）
- [x] **独立复验（本会话实跑，附着 `1fbf0ad`）**：全量 install 通过；CircleContractTest **23/23**；circle domain **42/42**；CircleApplicationContextTest **1/1**；BUILD SUCCESS exit 0
- [x] **CI 双绿**：run 33323104704（GitHub API 逐 job 核实 build-and-test + sensitive-scan）
- [x] **边界遵守**：diff 仅 3 个代码文件 + 2 个 superpowers 文档 + openapi 1 个；不动 `CommentNodeVO`/双键消费者；无运行时 DDL；`api/` 快照与 sync-manifest 未动（快照微同步由 PM 验收批次执行）；前端零改动

## 2. 规则 9 完成通知四字段（自检）

| 字段 | 值 |
| --- | --- |
| 实施提交 SHA | `1fbf0ad`（`1fbf0ad83f4270c735b6de95b24db51538f4d1bc`，6 commits） |
| 回执提交 SHA | `4592191`（交接仓库 PR #119 head，已合入 main） |
| PR 号 | CoderClub PR #18——**已合入 main（merge `86a09e7e`，2026-08-30，B-Review 复核通过后执行授权合入）** |
| R2 状态 | **实施 R2 达成**（已合入 CoderClub main，main tip 核验 `86a09e7e`）；本签署随交接仓库流程合入 main |

## 3. 任务书措辞歧义核查（随附说明）

任务书 §1.2 字面为「取当前登录标识填充 `fromId`」，与提案 D3 / PM 决策语义（`fromId` = **动态创建人**登录标识，供前端本人动态判定）存在字面歧义。实现取 `bo.getCreatedBy()`（创建人）符合决策意图；判别性断言（2002 vs 2001）已将「误取当前查看者」路径锚定为必失败，回归有保障。

## 4. 延后项与观察项（打包转 PM 验收，不阻塞）

| # | 项 | 处置标注 |
| --- | --- | --- |
| 1 | openapi schema `fromId` 多行展开 vs 相邻短属性单行紧凑（Minor，纯风格） | 接受延后，可随后续 openapi 编辑批次压缩 |
| 2 | CircleContractTest 注入真实 MapStruct converter（Minor 观察） | 既有套件形态，非本批引入，维持观察 |
| 3 | openapi 200 example `fromId: "2001"` 与测试登录标识数值重合（Minor 表述性） | 示例展示值与实现文件一致；测试用判别性 `"2002"`，接受 |
| 4 | 快照微同步（`MomentItemVO.fromId` 采纳，75 路径不变） | PM 验收批次执行 |

## 5. 关联

- 任务书 · 提案 PR #111 · PM 决策 PR #114 · 回执 PR #119（head `4592191`）· 实施 CoderClub PR #18（merged `86a09e7e`）
- 后续：PM 验收 → 快照微同步（`MomentItemVO.fromId` 采纳）→ F-Impl 小批（前端一行切换移除 D3 昵称临时兜底）

签署：后端评审（B-Review），2026-08-30