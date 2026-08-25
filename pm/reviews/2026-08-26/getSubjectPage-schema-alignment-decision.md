# PM 决策：getSubjectPage 请求 Schema 整段对齐（A2）

> **决策角色：** 协调 PM
> **决策日期：** 2026-08-26
> **提案：** `proposals/backend/2026-08-26/getSubjectPage-request-schema-alignment-proposal.md`（后端评审，PR #40，merge commit `c95f922`）
> **任务书：** `pm/requirements/2026-08-26/getSubjectPage-schema-alignment-proposal-task.md`（PR #39）
> **状态：** 已定案；实施阶段待前端 A3 合入 main 后由 PM 另行派发后端实现

## 1. 远程核验与事实复核（规则 9）

- **R2 生效性**：PR #40 已合入 `main`（merged_at 2026-08-25T15:49:35Z，merge commit `c95f922` 为 `origin/main` 顶端；`git merge-base --is-ancestor` 判定通过）。
- **契约侧**（快照 `0DAE8D3A`）：`getSubjectPage` 请求体 `$ref: SubjectPageQueryDTO`；该 schema 为 6 字段——`pageNo`/`pageSize`/`subjectDifficult`/`categoryId`/`labelId`/`subjectType`（含 P3 补充的 `subjectType`）✓
- **运行时侧**（协调 PM 只读核验 CoderClub main）：
  - `SubjectController.page`（`SubjectController.java:161-166`）：`@RequestBody @Validated(Groups.PageQuery) SubjectInfoDTO`——宽入 ✓
  - `countByCondition`（`SubjectInfoServiceImpl.java:31-49`）：仅 `categoryId`/`labelId`/`subjectType`/`subjectDifficult` + `isDeleted` 筛选，无 `subjectName` ✓
  - `queryByPage` XML（`SubjectInfoMapper.xml:24-56`）：同 4 维度筛选，无 `subject_name` 条件 ✓
  - 运行时无 `subjectName` 筛选，前端 `keyword` 为死参数（现被静默忽略）✓
- **结论**：提案 §1.2「运行时实际生效筛选字段与契约 6 字段逐字一致」成立，事实无误。

## 2. 决策

**采纳案 B/C（运行时收窄对齐契约）：** `getSubjectPage` 请求体以契约 `SubjectPageQueryDTO` 为唯一 schema；运行时 `SubjectController.page` 收窄（请求体 `SubjectInfoDTO` → `SubjectPageQueryDTO`，converter 显式映射 6 字段 → BO）；契约与 `api/` 快照**零结构变更**。

理由：

1. **契约即真相**：契约 6 字段与运行时实际生效筛选字段逐字一致，契约声明本来就是正确声明；案 A 反而把 8 个「宽入但忽略」的冗余字段制度化，误导前端字段可用性。
2. **零快照变更**：案 B/C 不动契约 → 前端基线 `0DAE8D3A` 不漂移，与「实施待 A3 合入」的并行策略一致；对比案 A 需 PM 重做快照全链同步（+1 引用变更）。
3. **前端无破坏**：前端现传参 = 契约 6 字段；多余字段（`keyword`/`subjectName` 等）在 Spring Boot 默认忽略未知属性配置下仍被忽略（不报 400），行为与现状一致。
4. **改动集中**：controller 收窄 + 显式映射 + `SubjectContractTest` 适配，回归基线明确（51/51）。

否决案 A：契约变宽 + 快照全链重同步 + 冗余字段制度化，收益（文档不再误导）远低于成本。

## 3. 附带条件（实施阶段必须满足）

1. **行为保持**：收窄后多余字段仍须被静默忽略（验证 `FAIL_ON_UNKNOWN_PROPERTIES` 默认行为），不得因收窄把现有前端请求变为 400。
2. **源文档描述更新**：后端 `docs/api/coderclub-openapi.json` 中 `SubjectPageQueryDTO` 的 description 现注明「实际绑定 SubjectInfoDTO，此处仅展示常用过滤字段」——实施后更新为请求体即该 DTO；PM 随后对 `api/` 快照做同款 description 微同步（+1 文本差异，按 P1/P3 模式全链记录）。
3. **边界不扩展**：不新增 `subjectName` 搜索等新能力；前端 `keyword` 死参数由前端实现随 A3 收敛清理（前端侧移除，属前端基线，不需契约变更）。
4. **实施时机**：前端 A3（frontend contract convergence）合入 main 后，PM 派发后端实现实施任务书；实施回执按规则 9 双轨（Markdown + `*-summary.json`）。

## 4. state 枚举演进（verification-workflow §7）

- `status/pm.json` `state`：`gate3-p1p3-accepted-snapshot-synced` → **`gate3-a2-proposal-decided`**（A2 提案已定案，实施待 A3 后派发）。
- 与 governance-check 白名单规则一致：`m4AcceptanceReports` 01-06 均有关闭验收、`m4-03Supplement.status=covered`——新 state 无冲突。

## 5. 关联

- 提案：`proposals/backend/2026-08-26/getSubjectPage-request-schema-alignment-proposal.md`
- 前端 A3：`pm/requirements/2026-08-26/frontend-contract-convergence-task.md`
- 实施任务书：待 A3 合入后派发（执行人：后端实现）

## 6. 版本记录

- 2026-08-26：创建（A2 提案审核定案，采纳案 B/C）。
