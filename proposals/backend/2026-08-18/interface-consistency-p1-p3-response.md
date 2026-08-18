# 后端评审回执：前端 subject 契约一致性疑问提案（P1/P2/P3）

> **提案角色：** 后端评审（B-Review）
> **提案日期：** 2026-08-18
> **回应：** `proposals/frontend/2026-08-18/interface-consistency-questions.md`（前端实现，PR #26 已合入 main）
> **参考核验：** 后端实现核验文件（`gate3-frontend-backend-bridge/2026-08-18-backend-proposal-verify.md`）
> **状态：** 待协调 PM 确认方案（确认前后端实现不得实施契约变更）

## 1. 后端独立复核结论（2026-08-18，对照 CoderClub `main` 源码）

以下各点由后端评审逐项对照后端代码独立复核，并修正细节。

### P1：分类 `sort` 字段缺失 —— ✅ 属实

`SubjectCategoryDTO`（`app/entity`）字段实际为 `id/categoryName/categoryType/imageUrl/parentId/children`，确无 `sort`。分类排序逻辑未在契约/后端暴露。前端 `CategoryManage.vue` 使用 `{name, sort}`。

**建议方案**（二选一，待 PM 定夺）：
- **方案 A（推荐）**：后端 `SubjectCategoryDTO` 补 `sort`（Integer）字段 + 分类查询返回时携带排序值；同步契约声明。满足前端分类排序展示/编辑（P1 阻塞 `CategoryManage`）。
- **方案 B**：前端放弃分类排序，仅按返回顺序展示（零后端改动，但前端失去排序能力）。

影响面：后端补字段为**契约新增字段（非破坏性）**；`SubjectCategoryDTO` 涉及 add/update/query 多端点，需同步 `docs/api/coderclub-openapi.json` 与 `api/` 快照（由 PM 同步）。

### P2：`settleName`/`subjectScore` 必填 —— ⚠️ 部分不准确，需修正

后端复核修正前端提案的事实偏差：

1. **`settleName`（出题人）并非 Add 必填**：`SubjectInfoDTO` 中 `private String settleName;` 上方**无** `@NotNull`。前端可不传。
2. **`subjectScore`（分数）确为 Add 必填**：`@NotNull(groups = {Groups.Add.class})`。
3. **重要修正——update 不触发校验**：`SubjectController.update` 方法签名为 `update(@RequestBody SubjectInfoDTO subjectInfoDTO)`，**未加 `@Validated`**，因此 **update 路径不会触发 Bean Validation**。前端提案称"add/update 不传会校验失败"不成立——**仅 add（`@Validated(Add)`）会因缺 `subjectScore` 失败**。

**建议**：前端 `SubjectEdit` 在 **add** 时补 `subjectScore`（可设默认如 10）；`settleName` 可选（非强制）。此项前端适配为主，不阻塞后端回执。

### P3：契约 `SubjectPageQueryDTO` 缺 `subjectType` —— ✅ 属实（附补充实况）

1. `SubjectInfoServiceImpl.countByCondition` 确含 `query.eq(SubjectInfoEntity::getSubjectType, info.getSubjectType(), info.getSubjectType() != null)` —— **实现支持 subjectType 筛选**。
2. 契约 `SubjectPageQueryDTO` schema：`pageNo/pageSize/subjectDifficult/categoryId/labelId`，确无 `subjectType` —— 文档与实现不一致属实。
3. **补充实况（后端实现核验未覆盖）**：契约 `getSubjectPage` 请求体 schema 引用的是 **`SubjectPageQueryDTO`**（5 字段），而运行时请求体实际是 **`SubjectInfoDTO`**（含 subjectType 及更多字段）——请求侧契约与运行时存在**整段 schema 差异**，不只是缺 `subjectType` 单个字段。

**建议方案**：契约 `SubjectPageQueryDTO` 补 `subjectType`（integer）声明，与实现对齐（满足前端按题型筛选）。是否同步将请求 schema 细化为与运行时一致的字段集合，建议一并评估（可后续单独提案，不阻塞 P3 本期补 field）。

## 2. 影响与流程

- P1（方案 A）、P3 属于**契约/接口变更**，按铁律必须经本提案 + PM 确认后，后端实现方可实施；由 PM 同步 `api/` 快照全链（源提交/SHA/快照提交/SHA/语义差异）。
- P2 以**前端适配**为主，不需要后端契约变更；后端实现确认校验现状即可（无 Java 改动）。
- 后端实现未擅自实施契约变更——符合边界，正确。

## 3. 决策请求

请协调 PM 在本提案上记录决策：

- **P1**：选方案 A（后端补 `sort` + 契约声明）还是方案 B（前端放弃排序）？
- **P3**：确认补 `subjectType` 声明；是否同步处理请求 schema 整段对齐（可本期一并与后续评估）？

PM 确认后，后端实现按决策实施，实施回执按规则 9 双轨交付。

- 提案角色：后端评审（B-Review）
- 日期：2026-08-18
