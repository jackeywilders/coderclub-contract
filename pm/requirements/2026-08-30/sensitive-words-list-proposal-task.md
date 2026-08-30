# 任务书：敏感词词库 list 端点契约提案（B-Review，单提案）

> 派发角色：协调 PM
> 派发日期：2026-08-30
> 执行角色：后端评审（B-Review）
> 背景：grill 共识（2026-08-30）——阶段三前端按全量 11 端点消费（含管理端敏感词管理页），但现有契约下 **remove 端点需要词 `id` 而无任何 list/查询端点，id 不可经 API 发现**（A8-P3-BE 回执 §6.4 / B-Review 签署 §3 观察项 4 已登记）：管理端只能加词、删词须查库，不可运营；词库盘点/审计同样依赖直查数据库。经 PM 评估需增补 list 端点。

## 1. 契约变更（提案须明示）

- **新增端点**：`POST /circle/sensitive/words/list`（管理端，与既有 save/remove 同域）。
- **鉴权**：`@SaCheckRole("admin_user")` 对齐既有两管理端点（403 语义由既有 NotRoleException 映射承接）。
- **响应**：词条目含 `id / word / type(1=黑名单 2=白名单) / createdTime`（如提案评估认为运营/审计需要，可评估增补 `createdBy` 等，提案明示即可，PM 确认时拍板）。
- **查询口径**：**分页（对齐全仓 PageInfo 口径）或全量列表**——由 B-Review 按词库量级与前端表格形态评估后在提案明示，两种方案均可接受。
- **语义**：只读，不触碰词库缓存重建（与 save/remove 的重建语义区分）。
- **契约面**：74→**75** 路径；新增响应 schema（及分页 wrapper schema，如走分页）。

## 2. 边界

- 不改 save/remove 既有语义与契约；X6 圈子管理另案不变；不涉及 C 端任何端点。
- 快照同步由 PM 在实现验收批次执行（实现回执后微同步 74→75）。

## 3. 交付与回执（规则 9）

1. 单提案落 `proposals/backend/2026-08-30/sensitive-words-list-proposal.md`，经 `codex/backend-contract` PR 合入交接仓库 main。
2. 完成通知带四字段告知 PM；PM 确认后派发 B-Impl 小实现 → 验收 → 快照 75 → F-Impl 第二批（管理端敏感词管理页，任务书届时另发）。

## 4. 验收标准

- [ ] 提案：端点定义（方法/路径/鉴权/查询口径/响应 schema）+ 量级评估 + 受影响端点登记（无）完整
- [ ] 未改 `api/` 快照与 `sync-manifest`；未改运行时源
- [ ] 合入 main + 通知四字段

## 5. 关联

- grill 共识（2026-08-30，用户确认）· A8-P3-BE 回执 PR #97（观察项 4）· 签署 PR #100 §3 · F-Impl 阶段三第一批任务书（同批派发 `pm/requirements/2026-08-30/phase3-frontend-circle-task.md`）
