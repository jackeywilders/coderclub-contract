# A2 getSubjectPage 请求体运行时收窄——后端评审复核签署

> 角色：后端评审（B-Review）
> 签署日期：2026-08-26
> 任务书：`pm/requirements/2026-08-26/getSubjectPage-runtime-narrowing-implementation-task.md`（PR #49）
> 回执：`handoff/backend-to-frontend/2026-08-26/backend-a2-getSubjectPage-narrowing-report.md` + `-summary.json`
> 工作底稿：`designs/backend/2026-08-26/a2-getSubjectPage-narrowing-review-workpaper.md`
> 状态：**签署通过，转 PM 验收**

## 1. 复核结论

✅ **复核通过，签署本回执。** 实施提交 `6b2aedd`（CoderClub PR #8）经人链核验与独立复验逐项与任务书验收标准相符：

- [x] `SubjectController.page` 请求体为 `SubjectPageQueryDTO`，`@AutoMapper` 显式映射 6 字段（pageNo/pageSize/subjectDifficult/categoryId/labelId/subjectType）→ `SubjectInfoBO`；service/Domain 链路不变
- [x] `SubjectContractTest` **52/52 回归通过**（51 基线 + 1 新增），新增用例 `getSubjectPage_shouldIgnoreExtraFields_andNotReturn400` 验证多余字段静默忽略、**不返回 400**（行为保持硬条件）
- [x] 真实请求验证：回执 §4 A/B 组（登录门禁 401、6 字段筛选 total=28→6、多余字段不 400），mock + 真实双验证齐备
- [x] `docs/api/coderclub-openapi.json` `SubjectPageQueryDTO` description 已更新；LF 字节态 SHA before `05933BEA` / after `A8C6A460`，与回执 §5 一致；零字段/结构/路径变更
- [x] 回执双轨落 `handoff/backend-to-frontend/2026-08-26/`（PR #50/#51 合入交接仓库 main `d286439`，R2）
- [x] 边界检查：未改交接仓库 `api/` 快照与 `status/sync-manifest.json`；未动其他端点/鉴权/错误码；未新增契约字段

## 2. 规则 9 完成通知四字段（自检）

| 字段 | 值 |
| --- | --- |
| 实施提交 SHA | `6b2aedd`（`6b2aeddbb775f5039fa50a3feaa779f05e6fe0ed`，CoderClub `feat/backend-a2-getSubjectPage-narrow`） |
| 回执提交 SHA | 回执终稿 `258821e`（PR #51 合入 main `d286439`）；summary 记录 `4bcf820`（初版，早于终稿修订——见工作底稿 §4 [仅供参考]） |
| PR 号 | 实施：CoderClub PR #8；回执：交接仓库 PR #50/#51 |
| R2 状态 | 回执：已合入交接仓库 main（PR #50/#51）；实施：PR #8 未合入 CoderClub main（open，CI 全绿，合入由用户/后端评审执行） |

## 3. 关联

- 决策：`pm/reviews/2026-08-26/getSubjectPage-schema-alignment-decision.md`（PR #41）
- 提案：`proposals/backend/2026-08-26/getSubjectPage-request-schema-alignment-proposal.md`（PR #40）
- 本签署：`acceptance/backend/2026-08-26/a2-getSubjectPage-narrowing-review-signoff.md`

签署：后端评审（B-Review），2026-08-26