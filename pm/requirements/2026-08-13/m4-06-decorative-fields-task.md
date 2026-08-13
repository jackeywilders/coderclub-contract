# M4-06 后端执行任务：装饰字段收敛（G1-04 遗留）

> **任务角色：** Claude Code 后端
>
> **批准角色：** PM / 跨项目协调 Codex
>
> **任务日期：** 2026-08-13
>
> **任务状态：** 待执行

> **任务依据：** `pm/requirements/2026-08-13/m4-task-design.md` §3 M4-06（设计已获用户批准，2026-08-13 分节确认）；执行与验收流程见该设计 §4（沿用 G1-04 模型）。

## 1. 任务摘要

收敛 `SubjectInfoDTO` 列表项携带的装饰性 `pageNo`/`pageSize` 字段（G1-04 遗留，快照未声明），消除快照与运行时响应差异。**本任务必须先提案后实施**：先评估「声明进契约」与「运行时移除」两案并提交 PM 确认，再实施 + 测试；如涉契约声明，按 `AGENTS.md` 规则 1 同步 `api/` 快照全链。

## 2. 前置事实（PM 已核验）

### 2.1 任务来源

`pm/requirements/2026-08-13/m4-task-design.md` §3 M4-06（M4 六项任务之一，提案流程独立，可与任意项并行）：

- 背景：「`SubjectInfoDTO` 列表项携带快照未声明的装饰性 `pageNo`/`pageSize` 字段（见 `pm/reviews/2026-08-13/g1-04-close-acceptance.md` 记录事项 3）。」
- 目标：「收敛装饰字段，消除快照与运行时响应差异。」

### 2.2 G1-04 遗留记录（记录事项 3）

`pm/reviews/2026-08-13/g1-04-close-acceptance.md` 记录事项 3：「装饰性多余字段：`SubjectInfoDTO` 列表项携带快照未声明的 `pageNo`/`pageSize` 字段（既有行为）。建议后续独立提案评估收敛，本任务不产生契约变更。」

### 2.3 快照现状

- `api/coderclub-openapi.json`（PM 批准快照）未声明 `SubjectInfoDTO` 的 `pageNo`/`pageSize` 字段；`status/sync-manifest.json` 记录 43 路径 / 43 操作（pathCount=43、operationCount=43、baselineEndpointCount=43）。

### 2.4 既有测试基线

- `SubjectContractTest` 45/45，BUILD SUCCESS（`pm/reviews/2026-08-13/g1-04-close-acceptance.md` 关闭验收核验）。

## 3. 执行步骤（按顺序执行）

### 步骤 1：撰写提案（必须先提案后实施）

- Backend Codex 负责撰写提案并写入 `proposals/backend/2026-08-13/m4-06-decorative-fields-<方案>.md`（Claude Code 后端提供运行时实现事实与影响评估输入；提案写入遵循 `AGENTS.md` 角色边界）。
- 提案必须评估两案并给出推荐方案：

  1. **声明进契约**：将 `pageNo`/`pageSize` 声明进 OpenAPI，运行时保持现状。
  2. **运行时移除**：从运行时响应移除 `pageNo`/`pageSize`，快照保持现状。

- 每案须评估：**兼容性影响**（后端既有消费方、测试基线、契约快照差异）与**前端消费影响**（前端是否已消费该两字段、移除的破坏性、声明的收益）。
- 提案须给出两案对照结论：推荐方案 + 理由 + 影响面清单。

### 步骤 2：PM 确认方案

- PM 在提案上记录决策（选定方案、日期、决策依据）。**未经 PM 确认方案前不得进入实施**。

### 步骤 3：实施 + 测试（按 PM 确认的方案）

- 按 PM 确认的选定方案实施（运行时移除 / 契约声明），提交实施代码。
- 运行测试（预期全绿），含 `SubjectContractTest` 45/45 回归：

  ```
  mvn -pl coder-club-subject/coder-club-subject-app/coder-club-subject-app-controller -am '-Dtest=SubjectContractTest' '-Dsurefire.failIfNoSpecifiedTests=false' test
  ```

- 既有测试全绿（infra / domain / controller 契约测试）。
- 若实施中发现两案之外的新选项或影响超出提案评估范围：停止实施，补充提案，重新经 PM 确认。

### 步骤 4：同步 `api/` 快照（如涉契约声明）

- 若 PM 确认「声明进契约」：按 `AGENTS.md` 规则 1 同步 `api/coderclub-openapi.json` 快照，快照必须记录全链：**源提交、源 SHA-256、快照提交、快照 SHA-256、语义差异**。
- 若 PM 确认「运行时移除」：快照不变化，无需本步骤（仍需在回执中核验快照与运行时一致性）。

### 步骤 5：提交回执（执行后由 Backend Codex 复核签署）

回执文件：`handoff/backend-to-frontend/2026-08-13/m4-06-decorative-fields-report.md`，必须包含：

1. 来源项目、分支、实施提交哈希与回执提交哈希。
2. 提案编号与 PM 确认记录（提案路径、选定方案、PM 决策记录位置）。
3. 测试命令与原始输出（含 `SubjectContractTest` 45/45 回归）。
4. 快照哈希（如变化）：源 SHA-256 / 快照 SHA-256 及语义差异（如涉）。
5. 已知限制（如前端消费方未确认项、服务地址、环境变量）。
6. 声明：未经 PM 批准未修改 `api/` 快照与 `status/sync-manifest.json`；未伪造验证输出。

## 4. 验收边界与关闭条件

- 本任务仅覆盖 `SubjectInfoDTO` 装饰字段 `pageNo`/`pageSize` 的收敛（声明进契约或运行时移除）；**不得在 PM 确认方案前实施**，不得在提案之外自行改变契约字段/路径/方法。
- 关闭条件（全部满足后 PM 复核关闭 M4-06）：
  1. 提案获 PM 批准（含选定方案与决策记录）。
  2. 实施提交存在且测试全绿（含 `SubjectContractTest` 45/45 回归与既有测试）。
  3. 快照/基线一致（如涉契约声明：源提交/SHA-256/快照提交/SHA-256/语义差异全链核对）。
  4. 回执含提案编号、PM 确认记录、提交哈希与测试输出，Backend Codex 复核签署。
- 若实施中发现需补充评估（如前端已消费该字段、字段语义与分页相关）：**M4-06 不关闭**，补充提案，经 PM 确认后重新实施与验证。

## 5. 禁止事项

- 未经 PM 确认方案前不得实施（必须先提案后实施）。
- 不得直接修改交接仓库 `api/coderclub-openapi.json` 快照（快照同步仅能在提案获 PM 确认后，按 `AGENTS.md` 规则 1 执行）与 `status/sync-manifest.json`。
- 不得自行决定「声明进契约」或「运行时移除」方案及契约字段/路径/方法变更。
- 不得在回执中伪造请求、响应或测试输出。

- 批准角色：PM / 跨项目协调 Codex
- 日期：2026-08-13
