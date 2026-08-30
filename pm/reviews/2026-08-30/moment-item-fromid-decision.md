# PM 决策：MomentItemVO 补 fromId 提案评审（D3）

> 决策角色：协调 PM
> 决策日期：2026-08-30
> 提案：`proposals/frontend/2026-08-30/moment-item-fromid-proposal.md`（PR #111，实施提交 `f32b066`，R2 main `b07ea765`，MCP 核验）
> 来源：A8-P3-FE 第一批回执（PR #112，`handoff/frontend-to-backend/2026-08-30/frontend-circle-report.md` §6 待确认项 2）
> 状态：**提案建议方案确认；后端实现派发暂缓（随下一排期）**

## 1. 决策结果

| 项 | 内容 | 决策 |
| --- | --- | --- |
| D3 | `MomentItemVO` 缺创建人标识字段，前端「本人动态显示删除入口」无法可靠判定 | ✅ **确认建议方案**：后端 `MomentItemVO` 补 `fromId: string`（与 `CommentNodeVO.fromId` 同源，即 `StpUtil.getLoginIdAsString()`）；前端改用精确匹配 `fromId === String(当前用户 id)`，移除昵称临时兜底判定 |

## 2. 决策理由

1. **契约缺口属实**：同快照 `CommentNodeVO` 已暴露 `fromId`（评论者本人判定先例），`MomentItemVO` 缺失等价字段；任务书 T2「本人动态显示删除入口」在契约层面无法可靠支撑——属契约不完整，不是前端实现缺陷。
2. **方案兼容性**：新增字段属只读响应 VO 扩展，向后兼容（旧客户端不受影响）；与既有 `CommentNodeVO.fromId` 同源同语义，无新鉴权/错误码/兼容性策略问题。
3. **临时兜底可接受（本批）**：前端 `nickName === 昵称 || === String(id)` 判定误判面仅 UI 入口显示（昵称重复场景），删除动作受后端 `moment/remove`「仅本人」400 兜底保护（错误提示而非数据损坏）；**无硬阻塞**，前端一行切换即可落地可靠判定。
4. **排期安排**：用户已指示 F-Impl 第二批派发暂缓；`fromId` 后端实现（1 个 VO 字段 + 1 处组装）属独立小项，**随下一实现轮排期派发**（可与敏感词管理页第二批或其配套批次并行评估），本批不派发。

## 3. 关联待评估项（另记，不阻塞）

- **D2**：`MessageVO` 无 `isRead` 条目级字段——前端以「全部/未读」筛选 tab 表达状态；是否立项由 F-Review/PM 评估，不构成契约阻塞。

## 4. 关联

- 提案 PR #111（R2 main `b07ea765`）· A8-P3-FE 第一批回执 PR #112 · F-Impl 前端 PR #17（CI 绿，待合入）
- 决策人：协调 PM，2026-08-30
