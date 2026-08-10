# 状态更新与契约对账计划

> **维护角色：** PM / 跨项目协调 Codex
>
> **适用主线：** `main@9cc3e904b90c5e937dafc26b1da86a72ceaec3df`
>
> **当前状态：** 文档治理已进入主线；契约对账尚未关闭；发布状态保持未发布。

> **后续决策说明：** 本计划记录 ADR-0001 之前的对账步骤。开发契约快照已由 PM 批准，当前映射和状态以 `status/sync-manifest.json`、`docs/adr/0001-development-contract-snapshot.md` 和最新 PM 验收记录为准；本计划中关于“不得将副本认定为权威”的开发范围结论已被取代，发布状态和 Gate 1 遗留项仍未关闭。

## 目标

把 `status/pm.json`、`status/backend.json`、`status/frontend.json` 和 `status/sync-manifest.json` 从“各自记录”收敛为可由提交哈希、文件哈希和验证命令复核的协作事实源。状态文件只记录元数据，不替代源代码、权威 API、运行时证据或测试报告。

## 当前已知差异

| 项目 | 当前事实 | 处理要求 |
| --- | --- | --- |
| PM 基线 | 主线为 `9cc3e90`，`status/pm.json` 仍记录旧审查提交 `ae0c8ad` | PM 完成新一轮审查后更新，不提前伪造关闭状态 |
| Backend API | 源文件 SHA-256 为 `44cbe7...`，交接声明为 `0057e6...` | Backend 重新提交转换关系和完整哈希回执 |
| Frontend API | 实际文件 SHA-256 为 `87e122...`，期望值为 `0057e6...` | Frontend 重新校验来源，差异关闭前不得正式消费 |
| API 目录 | `main` 存在 OpenAPI 副本，但治理规则不把副本视为权威 | PM 记录处置决策，保留 `finalReleaseStatus=not-published` |
| Backend worktree | 本地 `main@e80aaf6` 比远端 `085fe08` 超前 1 个提交 | Backend 角色自行决定提交或同步，PM 只记录已确认回执 |
| Frontend worktree | 当前状态为设计就绪但契约对账阻塞，Node/npm 门禁未恢复 | 先恢复验证环境，再提交消费回执 |

## 更新顺序

### 阶段 1：Gate 0 回执归档

1. Backend 填写 `handoff/backend-to-frontend/_template-contract-baseline-receipt.md` 的实际回执副本。
2. PM 核对源提交、源 SHA-256、转换关系和交接引用。
3. Frontend 根据 Backend 回执重新核验实际消费文件。
4. PM 只在证据完整后更新 `status/pm.json` 的审查基线和开放项。

### 阶段 2：Gate 1 回执归档

1. Backend 提交 47 个操作的鉴权矩阵和 401/403 运行时证据。
2. PM 固化 PUT/DELETE 正式方法、POST 兼容期限和移除条件。
3. Backend 提交分页 `total/list/totalPages` 修复与回归测试证据。
4. Frontend 恢复 Node/npm 验证，填写契约消费回执。

### 阶段 3：同步清单更新

只有在 Gate 0/1 的回执可复核后，才允许更新 `status/sync-manifest.json` 的来源提交、契约引用和 `lastSyncedAt`。更新时必须保持：

- `releaseStatus` 反映真实同步状态；
- `finalReleaseStatus` 仍为 `not-published`，除非 PM 另行明确授权；
- `backendCommit`、`frontendCommit`、`apiContractCommit` 不得填写未经回执确认的猜测值；
- `notes` 不得继续描述与主线事实相矛盾的状态。

## 状态字段规则

| 状态 | 使用条件 |
| --- | --- |
| `not-started` | 角色尚未提交可复核工作或回执 |
| `blocked` | 存在明确依赖、缺失证据或环境门禁失败 |
| `in-progress` | 已有负责人和输入，正在执行并等待验证 |
| `ready-for-acceptance` | 交付物已提交，等待 PM 核验 |
| `accepted` | PM 已核对提交、哈希、命令、结果和限制 |
| `not-published` | 尚未满足发布门禁，或 PM 未授权发布 |

不得用“报告已写入”替代 `accepted`，不得用“代码已存在”替代契约基线确认。

## 停止条件

- 源提交或 SHA-256 无法唯一确认；
- Backend 与 Frontend 对消费文件的来源理解不一致；
- 鉴权矩阵未覆盖全部操作；
- 分页一致性没有无结果、单页和多页证据；
- Frontend Node/npm 门禁仍无法真实执行；
- 任一角色要求绕过提案、回执或 PM 验收直接发布。

## 本计划不授权的动作

- 不修改后端项目或前端项目；
- 不将 OpenAPI 副本直接认定为权威契约；
- 不直接删除或改写 `api/coderclub-openapi.json`；
- 不修改 `finalReleaseStatus` 为已发布；
- 不推送远端或合并 Pull Request。
