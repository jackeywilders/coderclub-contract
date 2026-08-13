# M4-01 后端执行任务：细粒度角色/权限矩阵

> **任务角色：** Claude Code 后端
>
> **批准角色：** PM / 跨项目协调 Codex
>
> **任务日期：** 2026-08-13
>
> **任务状态：** 待执行

> **任务依据：** `pm/requirements/2026-08-13/m4-task-design.md` §3 M4-01（设计已获用户批准，2026-08-13 分节确认）；执行与验收流程见该设计 §4（沿用 G1-04 模型）。

## 1. 任务摘要

关闭 `G1-02-FINE-GRAINED-PERMISSION`（backend openItem，severity medium）：明确普通用户与管理员对 Subject、Auth 管理端点的 401/403 行为并实施，输出细粒度角色/权限矩阵文档。

## 2. 前置事实（PM 已核验）

### 2.1 任务来源

`status/backend.json` openItems：

- id：`G1-02-FINE-GRAINED-PERMISSION`；severity：medium
- 描述：「Auth 管理用户已覆盖 admin_user 角色和 403 回归；Auth Role/Permission 与 Subject 尚未配置细粒度角色/权限矩阵，移交 M4。」

### 2.2 Auth 侧已完成（不重复执行）

- Auth 管理用户已覆盖 `admin_user` 角色与 403 回归。
- 尚未覆盖：Auth Role/Permission 与 Subject 的细粒度角色/权限矩阵。

### 2.3 既有测试基线

- `SubjectContractTest` 45/45，BUILD SUCCESS（`pm/reviews/2026-08-13/g1-04-close-acceptance.md` 关闭验收核验）。
- G1-04 死代码清理与真实 DB 分页复核已关闭（2026-08-13）。

### 2.4 G1-02 统一 401/403 语义（已关闭，本任务沿用）

- 401（未认证）/ 403（无权限）统一语义：HTTP 状态 + 业务 code + 统一响应体（见 `pm/reviews/2026-08-10/gate-0-1-contract-reconciliation-checklist.md` G1-02 行）。

## 3. 执行步骤（按顺序执行）

### 步骤 1：盘点端点清单并输出权限矩阵文档

- 盘点 Subject 与 Auth 管理端点清单（写 / 读 / 管理）。
- 输出权限矩阵文档：端点 × 角色 × 行为，逐项明确**匿名 / 登录 / 角色 / 权限**四类结论。
- 矩阵文档置于后端项目内（Claude Code 后端可写区域），路径与提交哈希在回执中声明。

### 步骤 2：配置角色/权限数据并实施鉴权

- 配置角色/权限数据；如涉及存量数据调整，单独记录数据配置内容，与代码提交区分。
- 实施鉴权：`@SaCheckPermission` 类策略或等价实现，覆盖 Subject 管理端点。
- 403 响应一致性：HTTP 403 + 业务 code + 统一响应体，对齐 G1-02 语义。
- 补齐管理端点 403 断言（对齐 `SubjectContractTest` 风格）。

### 步骤 3：运行测试（预期全绿）

- Subject 侧：

  ```
  mvn -pl coder-club-subject/coder-club-subject-app/coder-club-subject-app-controller -am '-Dtest=SubjectContractTest' '-Dsurefire.failIfNoSpecifiedTests=false' test
  ```

- Auth 侧：等价命令（覆盖 Auth 管理端点鉴权回归，含三态 401/403 断言）。
- 既有测试全绿（infra / domain / controller 契约测试）。

### 步骤 4：提交回执（Backend Codex 复核后写入）

回执文件：`handoff/backend-to-frontend/2026-08-13/m4-01-fine-grained-permission-report.md`，必须包含：

1. 来源项目、分支、实施提交哈希与回执提交哈希。
2. 权限矩阵文档路径。
3. 三态（匿名 / 普通用户 / 管理员）测试命令与原始输出（401/403 断言）。
4. OpenAPI 是否变化及结论（如变化，记录提案编号，见禁止事项）。
5. 已知限制（如存量角色/权限数据配置差异、服务地址、环境变量）。
6. 声明：未修改交接仓库 `api/` 快照、`status/sync-manifest.json`；未伪造验证输出。

## 4. 验收边界与关闭条件

- 本任务仅覆盖 Subject 与 Auth 管理端点的鉴权行为与 403 响应一致性；不得自行改变已批准契约的字段/路径/方法（如有需要必须先提案）。
- 关闭条件（全部满足后 PM 复核关闭 M4-01）：
  1. 权限矩阵文档（端点 × 角色 × 行为，逐项明确匿名/登录/角色/权限）与实施提交存在。
  2. 匿名/普通用户/管理员三态 401/403 测试通过（对齐 `SubjectContractTest` 风格），且既有测试全绿（infra/domain/controller 契约测试）。
  3. 回执含原始命令输出与提交哈希，Backend Codex 复核签署。
- 若三态验证发现 401/403 行为与权限矩阵不一致，或涉及契约字段/路径/方法变化：**M4-01 不关闭**，契约变更先写入 `proposals/backend/`，经 PM 确认后实施，再重新验证。

## 5. 禁止事项

- 不得修改交接仓库 `api/coderclub-openapi.json` 快照与 `status/sync-manifest.json`。
- 契约字段/路径/方法变更必须先提案（`proposals/backend/`），经 PM 确认后方可实施；未经批准不得直接改写运行时 API 源或快照。
- 不得在回执中伪造请求、响应或测试输出。

- 批准角色：PM / 跨项目协调 Codex
- 日期：2026-08-13
