# M4 阶段分发交接摘要

> **交接角色：** 协调 PM
>
> **交接日期：** 2026-08-13
>
> **接收角色：** 后端实现（执行）、后端评审（复核签署 + M4-06 提案）
>
> **用途：** 供接收方会话启动时读取本摘要与对应任务书，逐项执行 M4 任务并提交回执。

## 1. 必读文件（按顺序）

| 文件 | 用途 |
| --- | --- |
| `pm/requirements/2026-08-13/m4-task-design.md` | M4 设计规格（六项任务 + Gate 4 发布门禁），已获用户批准 |
| `pm/requirements/2026-08-13/m4-implementation-plan.md` | 实施计划（PM 侧流程，接收方可略读了解整体） |
| `AGENTS.md` | 角色写入边界、日期目录规则（第 6 条）、契约治理规则（规则 1） |

## 2. 任务分配与执行顺序

| 顺序 | 任务书 | 执行角色 | 复核角色 | 回执路径（按回执实际创建日期落位） |
| --- | --- | --- | --- | --- |
| 1 | `pm/requirements/2026-08-13/m4-01-fine-grained-permission-task.md` | 后端实现 | 后端评审 | `handoff/backend-to-frontend/<执行日期>/m4-01-fine-grained-permission-report.md` |
| 2（并行） | `pm/requirements/2026-08-13/m4-02-oss-access-control-task.md` | 后端实现 | 后端评审 | `handoff/backend-to-frontend/<执行日期>/m4-02-oss-access-control-report.md` |
| 2（并行） | `pm/requirements/2026-08-13/m4-03-credential-hardening-task.md` | 后端实现（代码侧）+ 用户/运维（凭据轮换） | 后端评审 | `handoff/backend-to-frontend/<执行日期>/m4-03-credential-hardening-report.md` |
| 3 | `pm/requirements/2026-08-13/m4-05-invalid-request-body-task.md` | 后端实现 | 后端评审 | `handoff/backend-to-frontend/<执行日期>/m4-05-invalid-request-body-report.md` |
| 4（M4-01/02/05 完成后启动） | `pm/requirements/2026-08-13/m4-04-test-quality-gate-task.md` | 后端实现 | 后端评审 | `handoff/backend-to-frontend/<执行日期>/m4-04-test-quality-gate-report.md` |
| 全程独立并行 | `pm/requirements/2026-08-13/m4-06-decorative-fields-task.md` | **后端评审 先写提案** → 后端实现实施 | 后端评审 复核、PM 确认方案 | `handoff/backend-to-frontend/<执行日期>/m4-06-decorative-fields-report.md` |

## 3. 各角色职责与边界（AGENTS.md）

### 后端实现

- 逐项实现 M4-01~06（M4-06 须等 PM 确认方案后才实施）
- 每项完成后提交回执到 `handoff/backend-to-frontend/<执行日期>/m4-0X-<task>-report.md`，必含：来源项目/分支、提交哈希、原始命令与输出、已知限制、声明（未改 `api/` 快照、未改 `status/sync-manifest.json`、未伪造输出）
- **禁止**：写入 `proposals/`、`api/`、`status/`；不得自行决定契约策略；不得执行运维侧凭据轮换（M4-03）

### 后端评审

- 复核并签署每份回执（工作底稿 `designs/backend/<日期>/m4-0X-...-review-workpaper.md`）
- 撰写 M4-06 提案：`proposals/backend/<日期>/m4-06-decorative-fields-proposal.md`（评估「声明进契约」vs「运行时移除」两案，含兼容性影响与前端消费影响；后端实现提供运行时事实输入）
- **禁止**：写入 `api/` 快照与 `status/sync-manifest.json`；代替 PM 决策方案

### PM（本会话）

- 接收回执后逐项验收：核验关闭条件 → `pm/reviews/<日期>/m4-0X-close-acceptance.md` → 更新 `status/pm.json` → M4 全部关闭后 Gate 4 流程

## 4. 关键约定

1. **日期目录规则（AGENTS.md 第 6 条）**：所有新文档先建 `YYYY-MM-DD/` 目录（创建日期）再写入，文件名无日期前缀；回执目录 = 写回执当天
2. **回执必含**：来源项目/分支/提交哈希、原始请求与响应（不截断）、测试命令与结果、契约字段核验（如涉）、已知限制、声明
3. **契约变更**：任何接口字段/路径/方法/鉴权/错误码变更必须先 `proposals/backend/` → PM 确认；`api/` 快照仅 PM 可更新
4. **M4-04 验收启动条件**：须在 M4-01/02/05 完成后（关闭条件 0）
5. **M4-06 流程**：提案 → PM 确认方案 → 实施（45/45 回归）→ 如涉契约声明由 PM 同步快照（全链哈希）
6. **测试基线**：既有测试全绿（`SubjectContractTest` 45/45 等）；覆盖率门禁以行覆盖率为准（M4-04）

## 5. 状态追踪

- `status/pm.json`：`state=gate0-1-development-contract-accepted-release-pending`；`lastAction` 记录分发事实
- 每项回执到达并经 PM 验收后更新；M4 全部关闭 → `gate0-1-m4-accepted-gate4-pending`
- 发布状态：`releaseStatus`/`finalReleaseStatus` = `not-published`，仅用户授权后由 PM 变更（Gate 4）

- 交接角色：协调 PM
- 日期：2026-08-13
