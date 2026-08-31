# MESSAGEVO-ISREAD-D2 MessageVO 补 isRead——后端评审复核工作底稿

> 角色：后端评审（B-Review）
> 日期：2026-08-31
> 任务书：`pm/requirements/2026-08-31/messagevo-isread-implementation-task.md`；提案 `proposals/backend/2026-08-31/messagevo-isread-item-proposal.md`（PR #136，本会话起草）；立项决策 PR #135 + 确认决策
> 回执：`handoff/backend-to-frontend/2026-08-31/backend-message-isread-report.md` + `-summary.json`（PR #148，head 已合入 main，receiptCommitSha=`bd960b6`）
> 实施：CoderClub PR #21（head `f6c23a0`，6 commits；**本会话复核通过后已合入 main `72d12dd3`，R2 达成**）

## 1. 人链核验：实施提交存在性与一致性

| 项 | 证据 | 结果 |
| --- | --- | --- |
| 提交对象 | `git cat-file -t f6c23a0` 成功（走 7892 代理 fetch `feat/backend-message-isread`）；远端 PR #21 head 与本地对象一致 | ✅ |
| CI | PR #21 head `f6c23a0`：build-and-test ✅（job 99546452815，run 33409870319）+ sensitive-scan ✅（job 99546452372）——GitHub API 逐 job 核实 | ✅ |
| 提交数 | **6 commits**（spec + plan + 枚举/透传 + openapi + 最终审查修复波）——与回执一致 | ✅ |
| summary 一致性 | `implementationCommitSha=f6c23a0`、`receiptCommitSha=bd960b6`、PR #21、`lfSha256After=57C2D6EE…`、pathCount 75→75 与回执一致 | ✅ |
| PR #21 合入 | 本会话独立复核（CI 双绿 + 代码级复核 + 独立测试复验全过）后以 merge 方式合入 main（merge `72d12dd3`，B-Review 授权合入人身份）——**R2 达成**（main tip 核验 `72d12dd3`） | ✅ |

## 2. 代码级复核（对照提案 Q1-Q4 共识与回执，实读源码 @ `f6c23a0`）

| 核对项 | 证据 | 结果 |
| --- | --- | --- |
| **枚举** | `MessageIsReadEnum`（domain 层 `enums` 包）：`READ(1,"已读")`/`UNREAD(2,"未读")`；`getCode()` 标注 **Jackson `@JsonValue`**（HTTP 序列化输出数字 1/2，杜绝枚举名）；静态 `of(Integer)` null 安全（null→null；1→READ；其余→UNREAD） | ✅ |
| **BO** | `MessageBO` 补 `isRead`（enum）；`ShareMessageDomainServiceImpl.page()` 组装循环 `bo.setIsRead(MessageIsReadEnum.of(e.getIsRead()))`——**组装先于 `markReadByIds`**（`if (!bos.isEmpty())` 块），天然返回读取时点（置已读前）原值；置读时机零改动 | ✅ |
| **VO** | `MessageVO` 补 `isRead`（enum）——与 BO 同名同型，MapStruct-Plus `@AutoMapper` 自动映射零配置 | ✅ |
| **entity/DTO 不动** | `ShareMessageEntity.isRead`（Integer 列映射）与 `MessagePageQueryDTO.isRead`（请求筛选 Integer）保持现状（infra 不反向依赖 domain；请求侧零耦合） | ✅ |
| **契约测试判别性** | `CircleContractTest.getMessages_返回分页与格式化时间`：mock BO `setIsRead(UNREAD)` → 断言 `$.data.list[0].isRead` = **2（数字）**——漏透传/误值/@JsonValue 失效均必失败（双轴锚定透传+序列化） | ✅ |
| **domain 时序** | `ShareMessageDomainServiceImplTest` 新增用例：mock infra `is_read=2` → `page()` 返回 `BO.isRead=UNREAD`；**`InOrder`** 验证 `pageByToId` 先于 `markReadByIds`（组装先于置读，最终审查修复波强化） | ✅ |
| **源契约文档** | openapi `MessageVO` schema 补 `isRead`（integer/int32，description 注明读取时点语义、与读取即已读兼容，example 2）+ getMessages 200 example `"isRead": 2`；**75 路径不变** | ✅ |
| **边界** | 只读 VO 新增字段向后兼容（fromId D3 先例同构）；`unRead`/未读 tab 筛选语义不变；前端零改动；`api/` 快照与 status 未动（快照微同步由 PM 验收批次执行） | ✅ |

## 3. 独立复验（本底稿复核时执行，附着 `f6c23a0`）

采用 `git archive` 提取实施快照至隔离目录（不动主工作区），实跑：

| 命令/动作 | 结果 |
| --- | --- |
| 全量 `mvn install -DskipTests -q` | 通过（依赖链完整进入测试阶段） |
| CircleContractTest（含判别性 isRead=2 数字断言） | **23/23，零失败** |
| ShareMessageDomainServiceImplTest（含 InOrder 时序用例） | **8/8，零失败** |
| BUILD | **SUCCESS，exit 0** |
| 源文档字节态 SHA | `git cat-file blob f6c23a0:docs/api/coderclub-openapi.json`（LF 字节态）SHA256 = `57C2D6EE12D071CD6799718D7F772DAE10587C5FD7B876443CDAB06CF29E91D4`——与回执 after 逐字一致（before `26AEC009…`）；paths=75、schemas=119、isRead.type=integer/example=2 实测 |

## 4. 延后项核查（回执 openFindings 3 项，均为 Minor/可选，不阻塞）

| # | 项 | 复核意见 |
| --- | --- | --- |
| 1 | `of()` 越域值（0/3/负）静默映射 UNREAD | DB 值域 1/2、javadoc 已注明；如需脏值可见性可加 warn-log（可选延后），接受 |
| 2 | `desc` 无序列化路径（@JsonValue 接管） | 保留为语义元数据，无运行时影响，接受 |
| 3 | sibling 用例 `getMessages_结构化展开…` 仍用裸 verify 置读 | 本批 InOrder 用例已覆盖时序契约，观察项接受 |

## 5. 复核结论

**通过，签署。** 回执声明（6 提交、LF SHA `57C2D6EE`、75 路径不变、判别断言 + InOrder 时序、测试数字、边界遵守）与人链核验、代码实读、独立复验逐项一致，且与 D2 提案（本会话起草）Q1-Q4 共识完全吻合；PR #21 已按授权合入 main（`72d12dd3`），R2 达成。未发现 [必须修复]/[建议修改] 问题。

## 6. 关联

- 任务书 · 提案 PR #136 · 立项决策 PR #135 · 回执 PR #148（receiptCommitSha `bd960b6`）· 实施 CoderClub PR #21（merged `72d12dd3`）
- 后续：PM 验收 → 快照微同步（`MessageVO.isRead` 采纳，75 路径不变）→ F-Impl 消息页条目渲染（未读高亮/圆点）
