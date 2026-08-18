# 前端 subject 契约一致性疑问提案（P1/P2/P3）

> **角色：** 前端实现（F-Impl）
> **日期：** 2026-08-18
> **收件：** 协调 PM / 后端评审（B-Review）/ 后端实现（B-Impl）
> **用途：** PR-2（S2-S3）视图字段全量对齐契约过程中发现的契约 schema 与后端实现不一致 / 字段缺失，需确认后实施。
> **来源依据：** `pm/requirements/2026-08-18/frontend-real-api-integration-task.md`（S2）；契约快照 `api/coderclub-openapi.json`（43 paths，SHA `9a97c055…`）；后端源码只读核验（`coder-club-subject` 模块，2026-08-18）。

---

## P1：分类 `sort` 字段缺失

**现状（前端）**：`CategoryManage.vue` 使用 `{ name, sort }` 作为分类表单与树节点字段（分类排序）。
**契约/后端实况**：`SubjectCategoryDTO`（`SubjectCategoryController.java`、`SubjectCategoryDTO.java`）字段为 `id/categoryName/categoryType/imageUrl/parentId/children`——**无 `sort` 字段**。分类排序逻辑未在契约/后端暴露。
**建议方案**：
- 方案 A：后端 `SubjectCategoryDTO` 补 `sort`（Integer）字段，支持前端分类排序展示/编辑。
- 方案 B：前端放弃分类排序字段，仅展示 `categoryName`（按现有返回顺序）。
**影响范围**：`CategoryManage.vue` 表单与树、分类新增/更新 payload。
**来源提交哈希**：后端 `subject_category` 相关满足契约；前端 PR-1 合入 `a855c06`。

## P2：`settleName`（出题人）/ `subjectScore`（分数）为 Add/Update 必填

**现状（前端）**：`SubjectEdit.vue` 表单无出题人/分数字段（mock 时代无）。
**后端实况**：`SubjectInfoDTO.java` 中 `settleName`（出题人）/ `subjectScore`（分数）均标注 `@NotNull(groups = {Add.class})`；`SubjectController.save/update` 用 `SubjectInfoDTO`。前端 add/update 若不传这两个字段，会触发 **Bean Validation 校验失败**。
**建议方案**：确认前端 `SubjectEdit` 表单需补 `subjectScore`（默认分值，如 10）与 `settleName`（出题人，可前端填充或后端回填）。
**影响范围**：`SubjectEdit.vue` 表单、`addSubject/updateSubject` payload。
**来源提交哈希**：后端 `SubjectInfoDTO.java`（@NotNull Add 组）。

## P3：契约 schema `SubjectPageQueryDTO` 缺 `subjectType`

**现状（契约）**：契约 schema `SubjectPageQueryDTO` 声明 `pageNo/pageSize/subjectDifficult/categoryId/labelId`——**缺 `subjectType`**。
**后端实况**：`getSubjectPage`（`SubjectController.page`）请求体是 **`SubjectInfoDTO`**（含 `subjectType`）；`SubjectInfoServiceImpl.countByCondition` 明确支持 `subjectType` 筛选（`query.eq(SubjectInfoEntity::getSubjectType, ...)`）。
**影响**：前端列表/浏览按题型筛选需传 `subjectType`，后端已支持；但契约 schema 未声明该参数（文档与实现不一致）。
**建议方案**：契约 `SubjectPageQueryDTO` 补 `subjectType`（integer）字段声明，与后端实现对齐。
**影响范围**：`SubjectList.vue`/`SubjectBrowse.vue` 查询参数（即将传 `subjectType`）。
**来源提交哈希**：后端 `SubjectInfoServiceImpl.java` `countByCondition`。

---

## 待确认汇总

| # | 疑问 | 建议方案 | 阻塞项 |
|---|------|---------|--------|
| P1 | 分类 sort 缺失 | 后端补 sort 或前端放弃 | `CategoryManage` sort 字段 |
| P2 | settleName/subjectScore 必填 | 前端表单补两字段 | `SubjectEdit` 提交校验 |
| P3 | 查询 schema 缺 subjectType | 契约补声明（前端按 subjectType 传参） | 无（后端已支持，仅文档） |

请协调 PM/后端确认回执；前端 PR-2 视图主体适配（不依赖上述回执的部分）将并行推进，涉及 `sort`/`settleName`/`subjectScore` 的字段标注待回执。
