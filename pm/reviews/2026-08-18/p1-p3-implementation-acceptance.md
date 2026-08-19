# 后端 P1/P3 实施验收 + api/ 快照全链同步记录

> **验收角色：** 协调 PM（PM / 跨项目协调 Codex）
> **验收日期：** 2026-08-18
> **任务书：** `pm/requirements/2026-08-18/backend-p1-p3-implementation-task.md`
> **实施回执：** `handoff/backend-to-frontend/2026-08-18/backend-p1-p3-implementation-report.md` + `-summary.json`（后端实现）
> **签署：** 后端评审（`designs/backend/2026-08-18/p1-p3-sort-subjecttype-review-workpaper.md`，交接仓库 PR #32）
> **验收结论：** ✅ **P1/P3 验收通过；api/ 快照全链已同步**

## 一、关闭条件逐项核验

| 条件 | 要求 | 证据 | 结论 |
| --- | --- | --- | --- |
| 1 | P1 分类补 sort 字段 + 契约声明 | 后端 origin/main 含 `49067f1`（Entity/BO/DTO/Assembler）+ `13a1d86`（契约）；排序三端点（queryCategory SQL 层、queryTree 内存层，NULL 排最后 id 兜底） | ✅ |
| 2 | P3 subjectType 契约声明 | `f964f88`（SubjectPageQueryDTO 补 subjectType + 请求示例）；零 Java 行为改动（运行时已支持） | ✅ |
| 3 | 测试全绿 | `mvn test` 19 模块 BUILD SUCCESS；SubjectContractTest 51/51（≥基线）；模块单测 infra 32/domain 47/app-controller 79/auth 41+9/oss 61 | ✅ |
| 4 | 契约 SHA 全链记录 | 源 `7576E28A → FB7AF8C6(P1) → 05933BEA(P3)`；语义差异仅新增字段（向后兼容） | ✅ |
| 5 | 回执双轨 + 后端评审签署 | report + summary.json（结构校验 OK）；签署 `aab8d22`（PR #32） | ✅ |
| 6 | 未改交接仓库 api/ 与 sync-manifest（由 PM 同步） | 后端实现声明 + 本次由 PM 执行快照同步 | ✅ |

## 二、api/ 快照全链同步（协调 PM 执行）

| 项 | 值 |
| --- | --- |
| 源提交 | `f964f88`（后端 main，P3 契约完成点） |
| 源 SHA-256 | `05933BEACB07…`（后端 `docs/api/coderclub-openapi.json`） |
| 快照提交 | 本次 PM PR（交接仓库 main 合入后补记） |
| 快照 SHA-256 | `0DAE8D3A753E…`（`api/coderclub-openapi.json`） |
| 语义差异 | 17 处：14 处密码/Token 示例脱敏（维持既有）+ 3 处新增（`SubjectCategoryDTO.sort`、`SubjectPageQueryDTO.subjectType`、`getSubjectPage` 请求示例 `subjectType`） |

- 脱敏规则：password→`<password>`、newPassword→`<new-password>`、token/tokenValue→`<token>`（tokenName 保留），与既有快照一致（`sensitive-data-conventions.md`）。
- 快照与旧快照 diff 实测：**仅 3 处新增字段**，无其他变化（脱敏集保持一致）。

## 三、已知限制（验收知悉，不阻塞关闭）

1. **运行库 ALTER 未执行**：`subject_category` 加 `sort` 列待运行环境执行（本地无 MySQL 凭据）：`ALTER TABLE subject_category ADD COLUMN sort int(11) DEFAULT NULL COMMENT '排序（升序，空值排最后）' AFTER parent_id;` —— 由后端实现/运维在具备凭据环境执行。
2. **前端 sort:0 收敛**：后端补字段后，前端旧 payload 的 `sort:0` 会被真实写入 0（分类排最前）——前端需按决策收敛（`CategoryManage` 去掉硬编码 sort:0 或改为用户可编辑）。
3. **getSubjectPage 请求 schema 整段对齐**：`SubjectPageQueryDTO` 与运行时 `SubjectInfoDTO` 的整段对齐未在本期处理（后续单独提案）。
4. 后端评审在签署时更新了 `status/backend.json`（B-Review 职责目录）；本次 PM 验收更新 `status/pm.json`/`sync-manifest.json`。

## 四、结论

- **P1/P3 验收通过，M4 之后的首个契约变更闭环**（决策 → 后端实施 → 评审签署 → PM 验收 → 快照全链同步）。
- `releaseStatus`/`finalReleaseStatus` 仍 `not-published`；Gate 4 未启动（发布需用户授权）。

- 验收角色：协调 PM
- 日期：2026-08-18