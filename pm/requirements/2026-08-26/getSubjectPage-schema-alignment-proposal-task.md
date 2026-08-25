# getSubjectPage 请求 Schema 整段对齐提案任务书（交后端评审）

> **任务角色：** 后端评审（B-Review）
> **下发角色：** 协调 PM
> **日期：** 2026-08-26
> **来源：** P3 决策附件项（`pm/reviews/2026-08-18/p1-p2-p3-interface-decisions.md` §P3："请求 schema 与运行时整段对齐**后续单独提案**"）+ 后端评审 BR-1 自报
> **并行说明：** 本任务为**提案阶段**，与前端 A3 契约收敛并行安全；**实施阶段**（如提案确定变更契约）须在 A3 合入后另行派发，避免前端基线反复更新。

## 1. 背景与目标

契约 `getSubjectPage` 请求侧 schema（`SubjectPageQueryDTO`）与后端运行时实际使用的请求体（`SubjectInfoDTO`）存在**整段差异**：

| 维度 | 契约声明（快照 `0DAE8D3A`） | 运行时实际 |
| --- | --- | --- |
| 引用 schema | `SubjectPageQueryDTO`（属性：`pageNo`/`pageSize`/`subjectDifficult`/`categoryId`/`labelId`/`subjectType`） | `SubjectInfoDTO`（`SubjectController.page` 方法签名 `@RequestBody SubjectInfoDTO`）+ `SubjectInfoServiceImpl.countByCondition` 支持按 `subjectType` 等筛选 |
| 差异性质 | 契约只声明分页+部分筛选字段 | 运行时接受更宽的 `SubjectInfoDTO`（含题目详情字段） |

P3 本期已补 `subjectType` 声明（临时收敛）；本提案评估**整段对齐**的终局方案。

## 2. 提案要求（交付 `proposals/backend/2026-08-26/`）

1. **对照两案评估**（至少）：
   - **案 A：契约请求 schema 对齐运行时**——`getSubjectPage` 请求体改引用 `SubjectInfoDTO`（或与运行时一致的全量字段），文档与实现一致；评估影响面（前端已按 `SubjectPageQueryDTO` 调用的兼容性、快照同步、语义差异）。
   - **案 B：运行时收窄对齐契约**——`SubjectController.page` 改收窄请求体为 `SubjectPageQueryDTO`（或独立 Query DTO），实现与文档一致；评估影响面（现有前端传参是否被拒、后端 service 层改动、测试影响）。
   - 两案均需：来源提交哈希、兼容性影响、建议方案、验证方式（按 `proposals/` 既有格式）。
2. **给出推荐**与理由；若两案之外有更优（如新增独立查询 DTO 仅含实际筛选字段），可提出第三案。
3. **明确快照影响**：若需契约变更，标注 `api/coderclub-openapi.json` 快照同步责任（PM 执行）与语义差异预估。
4. **边界**：本提案只针对 `getSubjectPage` 请求 schema；不扩大到其他端点（避免范围蔓延）。

## 3. 交付物与流程

1. 提案文档落 `proposals/backend/2026-08-26/getSubjectPage-request-schema-alignment-proposal.md`（日期目录规则 6）。
2. 经角色分支 `codex/backend-contract` PR 合入交接仓库 main（governance-check 自动合并）。
3. PM 确认方案后，实施阶段另行派发（B-Impl），**待 A3 完成后再动契约**。
4. 提交与 PR 遵守规则 8；通知携带 PR 号/R2 状态（规则 9）。

- 下发角色：协调 PM
- 日期：2026-08-26
