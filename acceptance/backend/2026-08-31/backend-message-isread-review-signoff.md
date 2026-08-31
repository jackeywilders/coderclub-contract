# MESSAGEVO-ISREAD-D2 MessageVO 补 isRead——后端评审复核签署

> 角色：后端评审（B-Review）
> 签署日期：2026-08-31
> 任务书：`pm/requirements/2026-08-31/messagevo-isread-implementation-task.md`
> 提案：`proposals/backend/2026-08-31/messagevo-isread-item-proposal.md`（PR #136，B-Review 起草）
> 回执：`handoff/backend-to-frontend/2026-08-31/backend-message-isread-report.md` + `-summary.json`（PR #148，receiptCommitSha `bd960b6`，已合入 main）
> 工作底稿：`designs/backend/2026-08-31/backend-message-isread-review-workpaper.md`
> 状态：**签署通过，转 PM 验收**

## 1. 复核结论

✅ **复核通过，签署本回执。** 实施 `f6c23a0`（CoderClub PR #21，6 commits）经人链核验与独立复验与提案/任务书相符：

- [x] **枚举**：`MessageIsReadEnum`（domain 层）`READ(1)`/`UNREAD(2)`，`@JsonValue` 于 `getCode()`——HTTP 序列化输出数字 1/2；`of()` null 安全
- [x] **读取时点状态透传**：`MessageBO`/`MessageVO` 补 `isRead`（enum，MapStruct 自动映射）；domain `page()` 组装处 `of(e.getIsRead())` 一行透传——**组装先于 `markReadByIds`**，返回置已读前原值，置读时机零改动
- [x] **entity/DTO 不动**：`ShareMessageEntity.isRead`（Integer）与 `MessagePageQueryDTO.isRead`（筛选 Integer）保持现状
- [x] **契约测试判别性**：`getMessages` 用例补断言 `$.data.list[0].isRead` = **2（数字）**（漏透传/误值/@JsonValue 失效均必失败）
- [x] **domain 时序**：`ShareMessageDomainServiceImplTest` 新增 InOrder 用例（`is_read=2` → BO.isRead=UNREAD；`pageByToId` 先于 `markReadByIds`）
- [x] **源契约文档**：`MessageVO` schema + getMessages 200 example 登记 `isRead`（integer，example 2）；**75 路径不变**；LF SHA `26AEC009… → 57C2D6EE…`
- [x] **独立复验（本会话实跑，附着 `f6c23a0`）**：全量 install 通过；CircleContractTest **23/23**；ShareMessageDomainServiceImplTest **8/8**；BUILD SUCCESS exit 0；字节态 SHA `57C2D6EE…` 独立重算逐字一致
- [x] **CI 双绿**：run 33409870319（GitHub API 逐 job 核实 build-and-test + sensitive-scan）
- [x] **边界遵守**：只读 VO 扩展向后兼容（fromId D3 先例同构）；`unRead`/未读 tab 筛选不变；前端零改动；`api/` 快照与 status 未动（快照微同步由 PM 验收批次执行）

## 2. 规则 9 完成通知四字段（自检）

| 字段 | 值 |
| --- | --- |
| 实施提交 SHA | `f6c23a0`（`f6c23a04e96f61e435ffdd28646fc4e092b5df1a`，6 commits） |
| 回执提交 SHA | `bd960b6`（交接仓库 PR #148 回执提交，已合入 main） |
| PR 号 | CoderClub PR #21——**已合入 main（merge `72d12dd3`，2026-08-31，B-Review 复核通过后执行授权合入）** |
| R2 状态 | **实施 R2 达成**（已合入 CoderClub main，main tip 核验 `72d12dd3`）；本签署随交接仓库流程合入 main |

## 3. 延后项与观察项（打包转 PM 验收，不阻塞）

| # | 项 | 处置标注 |
| --- | --- | --- |
| 1 | `of()` 越域值静默映射 UNREAD（DB 值域 1/2，javadoc 已注明） | 可选 warn-log 延后，接受 |
| 2 | `desc` 无序列化路径（@JsonValue 接管） | 语义元数据保留，接受 |
| 3 | sibling 用例裸 verify 置读（本批 InOrder 已覆盖时序） | 观察项，接受 |
| 4 | 快照微同步（`MessageVO.isRead` 采纳，75 路径不变） | PM 验收批次执行 |

## 4. 关联

- 任务书 · 提案 PR #136 · 立项决策 PR #135 · 回执 PR #148 · 实施 CoderClub PR #21（merged `72d12dd3`）
- 后续：PM 验收 → 快照微同步（`MessageVO.isRead` 采纳）→ F-Impl 消息页条目渲染（未读高亮/圆点）

签署：后端评审（B-Review），2026-08-31
