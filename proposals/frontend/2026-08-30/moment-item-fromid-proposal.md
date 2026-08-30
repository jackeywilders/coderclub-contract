# 前端圈子模块契约疑问提案（D3）——MomentItemVO 缺创建人标识字段

> **角色：** 前端实现（F-Impl）
> **日期：** 2026-08-30
> **收件：** 协调 PM / 后端评审（B-Review）/ 后端实现（B-Impl）
> **用途：** A8 阶段三圈子模块（第一批，taskId=A8-P3-FE）实现过程中，任务书 T2「本人动态显示删除入口」无法基于当前契约可靠判定动态创建人，需契约确认或补字段后实施。
> **来源依据：** 契约快照 `api/coderclub-openapi.json`（AE967C70，74 paths，specSha256 `ae967c70fbf0ca69085d2429cb586b0a3c83bdab9fb9f28d7a5a8b01f17e4f68`）；任务书 `pm/requirements/2026-08-30/phase3-frontend-circle-task.md`（交接仓库 PR #106）。

---

## D3：`MomentItemVO` 无创建人标识字段（本人动态判定不可靠）

**现状（前端）**：任务书 T2 要求「本人动态显示删除入口」。动态列表响应 VO `MomentItemVO`（快照 AE967C70）字段为 `id / circleId / content / picUrlList / replyCount / nickName / avatar / createdTime`——**无创建人标识字段**（如 `fromId` / `userId`）。对比同快照 `CommentNodeVO` **存在** `fromId: string`（标识串），评论者本人判定可用 `fromId === String(当前用户 id)` 精确匹配。

**契约/后端实况**：`CommentNodeVO.fromId` 语义为登录标识串（后端 `StpUtil.getLoginIdAsString()`，`fromIsMomentAuthor` 同源）；`MomentItemVO` 未暴露等价字段。后端 `moment/remove` 接口按「仅本人可删」鉴权（非本人返回 400）。

**本批临时兜底（误判面说明）**：前端仅能按

```
nickName === 当前用户昵称 || nickName === String(当前用户 id)   // 昵称降级=标识串时按 id 串匹配
```

临时判定（已实现于 `src/utils/circle.ts` `canDeleteMoment`）。**误判面**：昵称重复场景——非本人动态因昵称撞名而错误显示删除入口；但删除动作受后端 `moment/remove`「仅本人」400 兜底保护（错误提示而非数据损坏），且该判定仅影响 UI 入口显示。

**建议方案**：后端 `MomentItemVO` 补充 `fromId: string` 字段（与 `CommentNodeVO.fromId` 同源，即 `StpUtil.getLoginIdAsString()`），前端改用精确匹配，删除临时兜底判定。新增字段向后兼容（动态列表为只读响应 VO，旧客户端不受影响）。

**影响范围**：`src/types/circle.d.ts` `MomentItemVO`、`src/utils/circle.ts` `canDeleteMoment`、`src/views/circle/components/MomentCard.vue` 删除入口显示。

**来源提交哈希**：前端 A8-P3-FE 圈子模块实现分支 `feat/frontend-a8-p3-circle`（`6cdfdd3` interceptor → `b47921c` 基线 74，其中 `98f52b8` 动态流 / `21f4a82` API 层 + 类型）。临时兜底实现见 `src/utils/circle.ts`。

---

## 待确认汇总

| # | 疑问 | 建议方案 | 阻塞项 |
|---|------|---------|--------|
| D3 | `MomentItemVO` 缺创建人标识字段 | 后端补 `fromId: string`（与 `CommentNodeVO.fromId` 同源）；前端改精确匹配 | 无硬阻塞（本批临时兜底 + 后端 400 兜底；待字段落地后移除临时判定） |

请协调 PM/后端确认回执；本批已按临时兜底交付，`fromId` 字段落地后前端一行切换，不影响契约其他消费。
