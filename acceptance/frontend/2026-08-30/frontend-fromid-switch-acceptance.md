# 前端评审签署：MomentItemVO.fromId 前端切换小批（A8-P3-FE D3，canDeleteMoment 精确匹配）

> **签署角色：** 前端评审（F-Review）
> **签署日期：** 2026-08-31
> **任务书：** `pm/requirements/2026-08-30/moment-fromid-frontend-switch-task.md`（派发 PR #122，taskId=A8-P3-FE-D3-fromid-switch，小批）
> **回执：** `handoff/frontend-to-backend/2026-08-30/frontend-fromid-switch-report.md` + `-summary.json`（PR #128，commit `42e5f68b`，双轨齐全）
> **实现：** 前端仓库 PR #19（`feat/frontend-a8-p3-fromid-switch`，5 commits，merge `d9f18bb`，2026-08-31）

## 1. 规则 9 远端证据（人链核验，MCP + git fetch 双通道）

| 字段 | 值 |
| --- | --- |
| 实施提交 SHA | `497f09e`（head；链路：`f4c128b` 设计/计划 / `7c21ecc` 基线 74417dd8 / `86fb5af` 类型 / `ed12997` 判定切换 / `497f09e` 最终审查修复：CommentSection isMyMoment 协调方裁定项） |
| 合并提交 SHA | `d9f18bb`（Merge pull request #19，merge message 含 F-Review 复核结论留痕） |
| 回执提交 SHA | `42e5f68b`（PR #128，已合入 main） |
| PR 号 | 前端仓库 **#19**；交接仓库 #128 |
| R2 状态 | ✅ 均已合入 `main`（前端 main HEAD=`d9f18bb`，`497f09e` 为 ancestor，MCP + `git fetch origin` 双通道核验；交接仓库 PR #128 已合入） |
| 契约快照 SHA-256 | `74417dd8ecdf835be33688bc14c1a4ca8e3d11bdd8f9559056ebe86ed0f85182`（75 端点，基线 75 一致，端点数与 main 基线 6262F444 无冲突） |

> **决策依据**：PM 决策 `pm/reviews/2026-08-30/moment-item-fromid-decision.md`（PR #114）：确认 `MomentItemVO` 补 `fromId`、前端改精确匹配；后端实现 `86a09e7` 已合入、快照采纳 `74417DD8`。

## 2. 复核结论

✅ **A8-P3-FE D3 fromId 小批复核通过，同意签署。** 本人动态判定由昵称/ID 临时兜底切换为 `fromId === String(当前用户 id)` 精确匹配（移除昵称降级分支），`MomentItemVO` 类型补 `fromId`，调用点与单测同步更新，基线 75（74417DD8）一致；协调方裁定项（评论树 `isMyMoment()` 同口径切换）与 PM 决策精神一致；回执双轨齐全、验证全绿，不阻塞签署。

## 3. 人链核验明细（F-Review 逐项验证：代码审查 + 本机四命令 + 远端 blob 核验）

### 判定切换 ✅

- `src/utils/circle.ts` `canDeleteMoment`：签名由 `(moment: Pick<MomentItemVO,'nickName'>, myId, myNickName)` 改为 `(moment: Pick<MomentItemVO,'fromId'>, myId)`；逻辑 `if (!myId) return false; return moment.fromId === String(myId)`——**精确匹配、无昵称兜底、无 id 时守卫拒绝**（D3 建议方案落地）✓。

### 类型与调用点 ✅

- `src/types/circle.d.ts` `MomentItemVO` 补 `fromId: string`（动态创建人登录标识，与 `CommentNodeVO.fromId` 同源）✓；其余字段零改动。
- `MomentCard.vue`：`canDeleteMoment(props.moment, userStore.userInfo?.id ?? 0)` 调用点同步（移除 myNickName 实参）✓。
- `CommentSection.vue` `isMyMoment()`：`props.moment.fromId === String(info!.id)`（协调方裁定，与 canDeleteMoment 同口径，消除同源昵称碰撞误判；`497f09e`）✓——评论树结构/渲染零改动。

### 单测 ✅

- `src/__tests__/circle.test.ts` `canDeleteMoment` 4 断言更新：fromId 匹配 → true；fromId 缺失 → false；他人 fromId → false；无当前用户 id → false——语义完整覆盖 ✓。

### 基线 ✅

- `api-docs-baseline.json`：`specSha256` = `74417dd8ecdf…`、`endpointCount=75`（`7c21ecc` 同步）；与 main 基线 6262F444 端点数一致、无端点冲突；`npm run api:check` 输出 `Endpoints: 75`、`No API contract changes detected` ✓。

## 4. 验证证据（本机四命令独立复验 + CI；闭环 F-Impl 沙箱缺口）

| 命令 | 本机结果（2026-08-31，`feat/frontend-a8-p3-fromid-switch` = head `497f09e`，F-Review 独立复验） | CI |
| --- | --- | --- |
| `npm run build` | ✅ vue-tsc --noEmit + vite build exit 0（**F-Review 本机补验**，F-Impl 沙箱拦截项） | ✅ |
| `npm test` | ✅ **53/53 pass**（8 suites，含既有用例零回归；**标准命令直跑**，F-Impl 沙箱拦截项） | ✅ |
| `npm run api:check` | ✅ SHA `74417dd8…`，75 endpoints，No changes | ✅ |
| `npm run lint`（全量 `--fix=false`） | ✅ exit 0 | ✅ |
| 前端 CI `check`（PR #19） | — | ✅ SUCCESS（run 33347239581，2026-08-31T01:20:15Z，含 `497f09e` 后重跑） |

**rebase 一致性**（F-Impl 回执登记，F-Review 抽核）：分支 rebase 至最新 main（7905579，含敏感词批 #18 合入），rebase 后 tree 与 rebase 前逐位一致（`a859b77c`）；`origin/main..HEAD` diff 仅 7 个 fromId 文件——与 F-Review 本地 diff 核验一致。

## 5. 已知待确认项 / 备注（不阻塞签署）

1. **协调方裁定项**（`497f09e`）：评论树 `isMyMoment()` 动态作者判定顺带切换为 fromId 精确匹配，超出任务书「评论树零改动」字面——与 PM 决策 PR #114「精确匹配、移除昵称兜底」精神一致，F-Review 认可并登记（建议 PM 验收时确认口径）。
2. **F-Impl 沙箱缺口闭环**：`npm test` 原命令与 vite build 由 F-Review 本机补验（53/53、build exit 0）；CI 亦全绿——闭环。
3. **回执通道降级说明**（F-Impl 登记）：回执经 gh API 提交（本地 git 写沙箱受限），提交 `42e5f68b` 已在 main 核验——R1/R2 均成立。
4. 基线 75 端点数与第二批 6262F444 一致，无基线冲突；fromId 字段为只读 VO 扩展，向后兼容。

**以上确认项建议 PM 验收时按回执口径登记；协调方裁定项建议一并确认。**

## 6. 签署意见

✅ **签署通过**。A8-P3-FE D3 fromId 小批实施与回执满足任务书验收标准（判定切换精确、类型/调用/单测/基线同步、本机四命令全绿、CI success），同意转协调 PM 验收（D3 闭环：临时兜底移除）。

## 7. 版本记录

- 2026-08-31：创建（前端评审签署，转 PM 验收；前端 PR #19 已合入 `d9f18bb`）。
