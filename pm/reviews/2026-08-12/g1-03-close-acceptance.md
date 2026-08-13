# G1-03 正式关闭验收

> **验收角色：** PM / 跨项目协调 Codex
>
> **验收日期：** 2026-08-12
>
> **验收结论：** G1-03 正式关闭（closed）。四个旧 POST 移除、PM 契约快照修复、前端基线更新与消费验证全部完成。

## 一、关闭依据

本关闭基于前一份 PM 验收文件 `pm/reviews/2026-08-11/g1-03-backend-task-acceptance.md` 中列出的剩余关闭条件，并由 Frontend Codex 提交消费回执后复核。后端实现与 PM 快照此前已通过验收，本次关闭补齐了最后一项前端消费验证。

## 二、本次核验的证据链

### 1. 前端基线更新提交

| 项目 | 值 |
| --- | --- |
| 前端项目 | `G:/Dev/backend/Club/CoderClubFront` |
| 前端本地 main 提交 | `afba2bee2665b576c2fc18aabc54759e0cda6513`（fix(api): update contract baseline to G1-03 snapshot） |
| 前端远端 main | PR #2 合并提交 `b85c5f56f63897ea3e9913b5a2ec1662d2b53455`，包含 `fa908a1d44c3a9300717f8ff475406144774a666` |
| 本地与远端内容一致性 | `git diff afba2be fa908a1 --stat` 为空，内容一致 |
| 变更范围 | 仅 `docs/frontend/handoff/api-docs-baseline.json`（3 insertions / 173 deletions），符合 47→43 endpoints 预期 |

### 2. 基线文件内容核验（实测）

- `endpointCount`：43
- `specSha256`：`414211bfa997081c9a07049d2d6da7a048591d054a068cd87f96390ba7a4a8e8`
- 四个旧 POST（`POST /subject/category/update`、`POST /subject/category/delete`、`POST /subject/label/update`、`POST /subject/label/delete`）：基线中均不存在
- 正式端点均存在：`PUT /subject/category/update`、`DELETE /subject/category/delete/{id}`、`PUT /subject/label/update`、`DELETE /subject/label/delete/{id}`、`DELETE /subject/remove/{id}`

### 3. 快照哈希交叉验证

- 交接仓库磁盘文件（CRLF）SHA-256：`414211bf...`，与前端基线 `specSha256` 完全一致
- 快照 git blob（LF）SHA-256：`9a97c055...`，与 PM 声明一致
- 两者内容一致，差异仅由 `core.autocrlf=true` 换行转换导致，回执第 6 节说明成立

### 4. 前端源码消费（实测）

`G:/Dev/backend/Club/CoderClubFront/src/api/subject.ts`：

- `updateCategory` → `PUT /subject/category/update`
- `updateLabel` → `PUT /subject/label/update`
- `removeSubject` → `DELETE /subject/remove/${id}`

### 5. 消费回执

`handoff/frontend-to-backend/2026-08-11/g1-03-frontend-consumption-receipt.md`（已合入交接仓库 main）：

| 验证命令 | 结果（回执声明） |
| --- | --- |
| `npm run api:check`（更新基线前） | 退出码 1，仅报告四个旧 POST 移除，无其他差异 |
| `npm run api:check -- --update-baseline` | 通过，基线更新为 43 endpoints |
| `npm run api:check`（更新基线后） | 通过，无 API 契约变化 |
| `npm test` | 通过，10/10，0 失败、0 跳过 |
| `npm run lint -- --fix=false` | 通过 |
| `npm run build` | 通过 |
| `git diff --check` | 通过 |

## 三、G1-03 关闭条件逐项核对

| 关闭条件 | 状态 | 证据 |
| --- | --- | --- |
| 后端四个旧 POST 映射移除 | 已完成（前次验收） | `pm/reviews/2026-08-11/g1-03-backend-task-acceptance.md` |
| PM 开发契约快照修复并同步 | 已完成（前次验收） | 快照提交 `99367ea`，源 `87d2b72` |
| 前端 API 基线不再含四个旧 POST | ✅ | 基线提交 `afba2be` / `fa908a1` |
| 前端以当前快照执行 `api:check -- --update-baseline` | ✅ | 消费回执 |
| 前端 `npm test` 通过 | ✅ | 消费回执，10/10 |
| Frontend Codex 提交消费验证回执 | ✅ | 回执文件已合入 main |
| PM 复核回执 | ✅ | 本文档 |

## 四、结论与后续

- **G1-03：closed**。四个旧 POST 不保留、不设延期窗口、不新增 410 的既定决策保持不变。
- `releaseStatus` 与 `finalReleaseStatus` 维持 `not-published`，不因 G1-03 关闭而变更。
- 仍开放项：`G1-04-REAL-DB-PAGINATION-RECHECK`（等待真实数据库分页复核），Gate 1 整体仍为 partial。

- 验收角色：PM / 跨项目协调 Codex
- 日期：2026-08-12
