# 任务书：MomentItemVO.fromId 前端切换（F-Impl 小批）

> 派发角色：协调 PM
> 派发日期：2026-08-30
> 执行角色：前端实现（F-Impl）
> 依据：`MomentItemVO.fromId` 已合入后端（CoderClub PR #18 merge `86a09e7e`）并采纳进快照 **74417DD8**（75 路径）；PM 决策 `pm/reviews/2026-08-30/moment-item-fromid-decision.md`（PR #114，确认建议方案："前端改精确匹配 `fromId === String(当前用户 id)`，移除昵称临时兜底判定"）
> 批次：小批次（单分支单 PR）；F-Impl 第二批（管理端敏感词管理页）任务书仍执行中，本小批与其并行或穿插

## 1. 任务明细

1. **类型**：`src/types/circle.d.ts` 的 `MomentItemVO` 补 `fromId: string`（与快照 74417DD8 一致；`api:check` 基线仍 75）。
2. **判定切换**：`src/utils/circle.ts` `canDeleteMoment` 由昵称降级判定（`nickName === 昵称 || nickName === String(当前用户 id)`）切换为**精确匹配** `fromId === String(当前用户 id)`；移除昵称降级分支（D3 提案建议方案：字段落地后前端一行切换）。
3. **消费点核对**：`MomentCard.vue` 删除入口显示（`canDeleteMoment` 调用方）无需结构改动，仅判定语义升级；动态流/评论树零改动（评论侧本就 `fromId` 精确匹配）。
4. **单测更新**：`src/utils/circle.ts` 相关用例改为 fromId 精确匹配断言（含 fromId 缺失/不匹配 → 不显示删除入口）；既有用例零回归。
5. **验证**：build / test / lint / api:check（75，No changes）全绿 + CI SUCCESS。

## 2. 交付与回执（规则 9）

1. 建议分支 `feat/frontend-a8-p3-fromid-switch`（或等价命名）→ CoderClubFront PR；CI 绿后由用户/F-Review 合入（仓库惯例）。
2. 回执双轨：`handoff/frontend-to-backend/` 按创建日期目录（Markdown + `*-summary.json` 模板字段齐全），完成通知四字段（实施 SHA / 回执 SHA / PR 号 / R2 状态）。

## 3. 约束

- 仅切换 `canDeleteMoment` 判定 + 类型补字段 + 单测；不触碰其他页面/端点/契约；`MomentItemVO` 其余字段零改动。
- 消费契约以快照 `74417DD8` 为准；发现契约问题先写 `proposals/frontend/` 交 PM。
- 规则 8 敏感信息占位符与 Conventional Commits 照常。

## 4. 关联

- 提案 PR #111 · PM 决策 PR #114 · fromId 实现验收（PR #121）· 快照 `74417DD8`（75 路径）· F-Impl 第一批回执 PR #112 §6 待确认项 2（D3）
