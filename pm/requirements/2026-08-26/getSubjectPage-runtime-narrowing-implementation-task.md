# 任务书：getSubjectPage 请求体运行时收窄实施（A2 实施阶段）

> **派发角色：** 协调 PM
> **派发日期：** 2026-08-26
> **执行角色：** 后端实现（B-Impl）
> **复核角色：** 后端评审（B-Review）
> **决策依据：** `pm/reviews/2026-08-26/getSubjectPage-schema-alignment-decision.md`（PR #41 合入 main；采纳案 B/C——运行时收窄对齐契约）
> **提案：** `proposals/backend/2026-08-26/getSubjectPage-request-schema-alignment-proposal.md`（PR #40）
> **前置条件：** 前端 A3 契约收敛已合入并验收关闭（frontend PR #9 `d81e665c` + 收尾 PR #10 `601d778e`；交接仓库验收记录 PR #45/#47）——已满足。

## 1. 目标

把 `getSubjectPage` 运行时行为收窄到与契约一致：请求体从 `SubjectInfoDTO`（宽入，14 字段仅 6 生效）改为 `SubjectPageQueryDTO`（6 字段全生效），**契约与交接仓库 `api/` 快照零结构变更**（前端基线 `0DAE8D3A` 不漂移）。

## 2. 实施边界（仅以下范围，禁止扩大）

1. **controller 收窄**：`SubjectController.page`（`coder-club-subject/coder-club-subject-app-controller/.../app/controller/SubjectController.java:161-166`）请求体类型 `SubjectInfoDTO` → `SubjectPageQueryDTO`；保留 `@Validated(Groups.PageQuery)` 分组（当前为空标记接口，行为不变，保留以防后续分组校验扩展）。
2. **显式映射**：DTO → BO（或沿用现有 converter）显式映射 6 字段：`pageNo`/`pageSize`/`subjectDifficult`/`categoryId`/`labelId`/`subjectType`；service 层接口与 Domain 链路**不变**（仍收 BO）。
3. **行为保持（硬条件）**：收窄后前端现传参（契约 6 字段）行为与现状一致；**多余字段（`subjectName`/`settleName`/`subjectScore` 等）仍须被静默忽略、不得报 400**（Spring Boot 默认 `FAIL_ON_UNKNOWN_PROPERTIES=false`，需在回归中显式验证）。
4. **测试适配**：`SubjectContractTest` 中 page 相关用例的请求体类型断言/构造适配新 DTO；**51/51 基线回归通过**；补 1 条「多余字段被忽略（不 400）」用例。
5. **源文档 description 更新**：后端 `docs/api/coderclub-openapi.json` 中 `SubjectPageQueryDTO` 的 description 现为「实际绑定 SubjectInfoDTO，此处仅展示常用过滤字段」→ 改为「getSubjectPage 请求体即本 DTO，6 字段全部参与筛选」。**此项是 A2 决策附带条件 2（决策文档 §3.2），已获 PM 确认，允许作为实施一部分更新后端源文档；不需另行提案。** 交接仓库 `api/` 快照与 `status/sync-manifest.json` 由 PM 在实施回执后全链同步，**你不得修改**。
6. **真实请求验证**：本地/可用环境验证 6 字段筛选生效、多余字段被忽略（记录请求与响应）。

## 3. 禁止事项

- 不新增 `subjectName` 搜索等新能力（前端 `keyword` 已清理；如需标题搜索另行提案）。
- 不修改其他端点、不动鉴权/错误码/路径；不修改交接仓库 `api/` 快照、`status/sync-manifest.json` 及任何治理文件。
- 不自行扩展契约字段。

## 4. 交付与回执（规则 9 双轨）

1. 实施提交推送到后端仓库（`G:/Dev/backend/Club/CoderClub`），提交信息按 Conventional Commits（如 `refactor(subject): narrow getSubjectPage request body to SubjectPageQueryDTO (A2)`）。
2. 回执双轨提交到交接仓库 `handoff/backend-to-frontend/2026-08-26/`：Markdown 正文（来源与提交哈希表、实施明细、验证证据——51/51 回归输出、行为保持用例结果、真实请求记录、`docs/api` description diff）+ 同目录 `*-summary.json`（按 `_template-task-receipt-summary.json` 模板：`taskId`/`taskTitle`/`receiptPath`/`sourceProject`/`implementationCommitSha`/`receiptCommitSha`/`pullRequestNumber`/`contractSnapshotSha256`（`0dae8d3a`）/`verificationResult`/`verificationDate`）。
3. 完成通知带规则 9 四字段（实施 SHA、回执 SHA、PR 号、R2 状态），告知后端评审复核签署；回执经 `claude/backend-proposals` PR 合入交接仓库 main（governance-check 自动合并）。
4. 后端评审复核签署后通知 PM；PM 验收后做 `api/` 快照 description 微同步 + `sync-manifest` 更新 + `status/backend.json`/`pm.json` 状态推进。

## 5. 验收标准

- [ ] `SubjectController.page` 请求体为 `SubjectPageQueryDTO`，映射显式覆盖 6 字段
- [ ] `SubjectContractTest` 51/51 回归通过；含「多余字段忽略不 400」用例
- [ ] 真实请求：6 字段筛选生效、多余字段（如 `subjectName`）被忽略
- [ ] `docs/api/coderclub-openapi.json` `SubjectPageQueryDTO` description 已更新（附 diff）
- [ ] 回执双轨落 `handoff/backend-to-frontend/2026-08-26/`，通知带四字段远端证据

## 6. 关联

- 决策：`pm/reviews/2026-08-26/getSubjectPage-schema-alignment-decision.md`
- 提案：`proposals/backend/2026-08-26/getSubjectPage-request-schema-alignment-proposal.md`
- 后端评审复核：签署回执（`acceptance/backend/`）后转 PM 验收