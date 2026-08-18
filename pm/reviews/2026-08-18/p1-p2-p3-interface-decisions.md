# 协调 PM 决策记录：前端契约一致性疑问 P1 / P2 / P3

> **决策角色：** 协调 PM（PM / 跨项目协调 Codex）
> **决策日期：** 2026-08-18
> **提案：** `proposals/frontend/2026-08-18/interface-consistency-questions.md`（前端实现）
> **后端回执：** `proposals/backend/2026-08-18/interface-consistency-p1-p3-response.md`（后端评审）
> **场景：** Gate 3 前端联调（S2/S3）契约一致性疑问；S1/S2/S3 已由前端评审复核通过并合入，本决策解除 S4/后续字段阻塞。

## 决策摘要

| 项 | 结论 | 依据 / 指派 |
| --- | --- | --- |
| **P1** 分类 `sort` 缺失 | **方案 A：后端补 `sort`（Integer）字段 + 契约声明** | 满足前端分类排序；契约新增字段（非破坏性）；后端评审推荐 A。指派后端实现补字段，PM 后续同步 `api/` 快照全链 |
| **P2** `settleName`/`subjectScore` | **前端适配为主（接受后端回执的修正口径）** | 后端复核：仅 add 路径 `subjectScore` 必填、update 不触发校验、`settleName` 非必填。前端 add 补 `subjectScore`（默认值后端评审建议 10）即可，无后端契约变更 |
| **P3** 查询 schema 缺 `subjectType` | **契约补 `subjectType`（integer）声明**；请求 schema 与运行时整段对齐**后续单独提案**（本期不阻塞） | 后端已支持 `subjectType` 筛选；补声明对齐文档与实现。整段 `SubjectPageQueryDTO`/`SubjectInfoDTO` 对齐另议 |

## 逐项依据

**P1 — 分类排序字段**
- 契约 `SubjectCategoryDTO` 为 `id/categoryName/categoryType/imageUrl/parentId/children`，无 `sort`；前端 `CategoryManage.vue` 使用 `{name, sort}` 展示/编辑排序。
- 决策：**方案 A（补 `sort`）**。理由：分类排序是业务既有需求，前端已实现调用，补字段为新增（非破坏、向后兼容）；满足前端分类排序能力，避免"失去排序"的 B 方案降级。属于契约新增字段，按铁律经本决策 + PM 同步快照。

**P2 — Add/Update 必填字段**
- 后端复核修正前端事实偏差：`settleName` 非必填；`subjectScore` 仅 add（`@Validated(Add)`）必填；**update 方法未加 `@Validated`、不触发校验**。
- 决策：**前端 add 补 `subjectScore`（默认值按后端评审建议 10），`settleName` 可选**。属前端适配，无后端契约变更。要求前端实现按后端回执口径调整 `SubjectEdit`；不阻塞。

**P3 — 查询 schema 缺题型筛选**
- 契约 `SubjectPageQueryDTO` 缺 `subjectType`，后端 `getSubjectPage` 运行时用 `SubjectInfoDTO`（实现支持 `subjectType` 筛选，`countByCondition` 有 `eq(SubjectInfoEntity::getSubjectType,...)`）；请求侧 schema 与运行时存在整段差异。
- 决策：**本期补 `subjectType` 声明**（满足前端按题型筛选）；请求 schema 整段对齐运行时（`SubjectInfoDTO`）**后续单独提案评估**，不阻塞本期。

## 指派与后续

1. **后端实现**：按 P1 补 `SubjectCategoryDTO.sort`（Integer）+ 分类查询返回排序值；契约变更先落 `proposals/backend/` 补充实施提案/回执，经 PR 合入后端 `main`；实施回执按规则 9 双轨交付，含 `docs/api/coderclub-openapi.json` 源更新。
2. **前端实现**：按 P2 补 `SubjectEdit` add 的 `subjectScore`（默认 10）、确认 `settleName` 可选；`sort` 字段待后端补字段后收敛（当前 `sort:0` 带 payload 不破坏，后端 Jackson 忽略未知属性）。
3. **协调 PM（本角色）**：后端实现完成后，同步 `api/` 快照全链（源提交 / SHA-256 / 快照提交 / SHA-256 / 语义差异），并更新 `status/`。
4. 本决策不涉及发布状态（`releaseStatus`/`finalReleaseStatus` 仍 `not-published`，Gate 4 未启动）。

- 决策角色：协调 PM
- 日期：2026-08-18
