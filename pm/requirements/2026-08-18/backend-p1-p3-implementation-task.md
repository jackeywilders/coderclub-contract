# 后端实施任务书：P1 分类排序字段 + P3 查询题型筛选契约声明

> **任务角色：** 后端实现（B-Impl）
> **下发角色：** 协调 PM
> **日期：** 2026-08-18
> **状态：** ✅ PM 已决策，可实施（决策依据见下；此前为提案待决）
> **契约影响：** 涉及契约字段新增/声明变更——已获 PM 确认，可实施；需同步后端源 `docs/api/coderclub-openapi.json`（PM 随后同步交接仓库 `api/` 快照全链）

## 1. 决策依据（实施前必读，按序）

| 文件 | 用途 |
| --- | --- |
| `pm/reviews/2026-08-18/p1-p2-p3-interface-decisions.md` | **协调 PM 决策（2026-08-18）**：P1=方案 A（后端补 `sort` + 契约声明）；P3=契约补 `subjectType` 声明（整段 schema 对齐后续单独提案） |
| `proposals/backend/2026-08-18/interface-consistency-p1-p3-response.md` | 后端评审回执（事实复核：P2 修正、P1/P3 属实；附建议） |
| `proposals/frontend/2026-08-18/interface-consistency-questions.md` | 前端契约疑问提案（P1/P2/P3 原文） |
| `docs/agents/verification-workflow.md` §6 / `AGENTS.md` 规则 9 | 回执双轨与远端证据要求 |

## 2. 实施要求（回执须逐项覆盖）

### P1 —— 分类排序字段 `sort`

1. **后端代码**：`SubjectCategoryDTO` 补 `sort`（Integer）字段；分类查询（tree/list 等）返回时排序值生效（按 `sort` 排序或携带排序值，实现方式由后端实现自定）。
2. **契约同步**：同步 `docs/api/coderclub-openapi.json`（后端运行时权威源）——`SubjectCategoryDTO` schema 补 `sort`；记录源更新前/后 SHA-256 与语义差异。
3. **兼容性**：`sort` 为**新增字段（非破坏性）**；既有字段/路径/方法不变；不改变鉴权与错误码。

### P3 —— 查询题型筛选 `subjectType` 契约声明

1. **契约同步**：`docs/api/coderclub-openapi.json` 中 `getSubjectPage` 请求 schema `SubjectPageQueryDTO` 补 `subjectType`（integer）声明（后端代码已支持 `subjectType` 筛选，无 Java 行为改动）。
2. **范围限制**：本期仅补 `subjectType` 声明；`getSubjectPage` 请求 schema 与运行时 `SubjectInfoDTO` 的**整段对齐**不在本期（后续单独提案），不得借此扩大改动。

### 通用

- 测试：涉 P1 的 subject/category 相关测试回归（至少 `SubjectContractTest`）+ 全量 `mvn test` 全绿；P3 为契约声明变更，用 `api:check`/OpenAPI 校验确认 schema 生成正确（如项目有对应检查）。
- 变更遵循实现惯例；提交 Conventional Commits（如 `feat(subject): 分类新增 sort 排序字段及契约声明` 分 P1/P3 清晰提交）。

## 3. 契约与快照边界

- 后端实现只改**后端项目** `docs/api/coderclub-openapi.json`（运行时权威源，已获 PM 确认可改）；**禁止**改交接仓库 `api/` 快照与 `status/sync-manifest.json`（由 PM 在实施完成后同步全链）。
- 若实施中发现超出 P1/P3 决策范围的影响：**停止实施**，回报 PM，不扩大改动。

## 4. 回执要求（规则 9 双轨）

1. 回执文件：`handoff/backend-to-frontend/2026-08-18/backend-p1-p3-implementation-report.md`，必含：来源分支/实施提交哈希/回执提交哈希；决策依据；测试命令与原始输出（含 `SubjectContractTest` 回归）；契约 SHA-256（前端更新前/后）与语义差异；已知限制；声明（未改交接仓库 `api/` 与 `sync-manifest`）。
2. 双轨：同目录 `backend-p1-p3-implementation-summary.json`（字段见 `_template-task-receipt-summary.json`：taskId/taskTitle/receiptPath/sourceProject/implementationCommitSha/receiptCommitSha/pullRequestNumber/contractSnapshotSha256/verificationResult/verificationDate）。
3. 复核：回执经**后端评审**签署后由 PM 验收；PM 据实施提交/SHA 同步交接仓库 `api/` 快照全链并更新 `status/`。
4. 提交与 PR 描述遵守规则 8（无真实环境信息）。

## 5. 禁用事项

- 未在本决策范围外的契约/字段/路径/方法变更须先入 `proposals/backend/` 待 PM 确认。
- 不得修改前端项目、交接仓库治理文件、`api/` 快照、`status/sync-manifest.json`。

- 下发角色：协调 PM
- 日期：2026-08-18