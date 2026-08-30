# 任务书：MomentItemVO 补 fromId 小实现（B-Impl）

> 派发角色：协调 PM
> 派发日期：2026-08-30
> 执行角色：后端实现（B-Impl）
> 提案（已 PM 确认）：`proposals/frontend/2026-08-30/moment-item-fromid-proposal.md`（PR #111，R2 main `b07ea765`）；PM 决策：`pm/reviews/2026-08-30/moment-item-fromid-decision.md`（确认建议方案，PR #114）
> 批次：小批次（单分支单 PR）；**本批双轨**——与 F-Impl 第二批（管理端敏感词管理页，`sensitive-words-manage-frontend-task.md`）并行派发

## 1. 任务明细

按提案「建议方案」与决策记录执行：

1. **VO**：`MomentItemVO` 补 `fromId: string` 字段——与 `CommentNodeVO.fromId` **同源**（登录标识串，`StpUtil.getLoginIdAsString()`）；字段语义 = 动态创建人登录标识，供前端「本人动态」精确判定。
2. **组装**：circle 域动态列表组装处取当前登录标识填充 `fromId`（与评论域 `fromId` 组装同源实现，双键消费者不涉及——本批仅补字段）。
3. **契约测试**：+1——`MomentItemVO.fromId` 字段面断言（200 动态列表含 fromId，值 = 登录标识串）；既有 circle 契约测试零回归（对齐 A8-P3-BE 用例形态）。
4. **源契约文档**：`docs/api/coderclub-openapi.json` 中 `MomentItemVO` 登记 `fromId` 字段（string，description 注明与 `CommentNodeVO.fromId` 同源语义）；回执登记 LF SHA before/after（before = `24DC841402BB5E063758A4156FC3AAF8D84609845BC218D92D0DC8FE6C7DD82A`，75 路径）。
5. **快照衔接**：路径数不变（75），schema 字段级变更 → 快照微同步由 PM 验收批次合并执行（与敏感词 list 微同步模式相同）；前端一行切换（移除 D3 临时兜底）为**后续 F-Impl 小批**，不在本任务书范围。

## 2. 交付与回执（规则 9）

1. 分支 `feat/backend-moment-fromid`（或等价命名）→ CoderClub PR；CI 全绿后由用户/B-Review 合入（仓库惯例）。
2. 回执双轨：`handoff/backend-to-frontend/2026-08-30/`（按创建日期，Markdown + `*-summary.json` 模板字段齐全），完成通知四字段。
3. 快照衔接：实现合入后 PM 验收批次微同步（`MomentItemVO.fromId` 登记进快照）。

## 3. 约束

- 仅补 `fromId` 字段 + 组装；不触碰 `MomentItemVO` 既有字段/其他端点/鉴权/错误码；不动 `CommentNodeVO` 与双键消费者。
- 前端代码零改动（前端切换属后续 F-Impl 小批）；不改 `api/` 快照与 `status/sync-manifest.json`（PM 验收后微同步）。
- 规则 8 敏感信息占位符与 Conventional Commits 照常。

## 4. 关联

- 提案 PR #111 · PM 决策 PR #114 · F-Impl 第一批回执 PR #112 §6 待确认项 2（D3）· F-Impl 第二批任务书（同批双轨）
