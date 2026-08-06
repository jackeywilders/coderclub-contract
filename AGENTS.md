# CoderClub 交接仓库协作约定

本仓库是 CoderClub 后端、前端与 PM 之间的契约交接区。它记录决策、交接、验收和状态，不复制 OpenAPI 文件，也不替代后端项目中的权威 API 定义。

## 项目路径

- 后端项目：`G:/Dev/backend/Club/CoderClub`
- 前端项目：`G:/Dev/backend/Club/CoderClubFront`
- 交接仓库：`G:/Dev/backend/Club/coderclub-contract`
- 当前 PM 工作目录：`G:/Dev/backend/Club/coderclub-contract-codex-pm`

## 三个 Codex 角色

### PM / 跨项目协调 Codex

职责：维护交接仓库治理规则，汇总需求与决策，协调后端和前端交接，维护路线图、报告、验收记录及同步状态。

允许写入：当前交接仓库内的全部治理路径，包括 `AGENTS.md`、`CLAUDE.md`、`docs/`、`api/`、`designs/`、`handoff/`、`proposals/`、`acceptance/`、`pm/` 和 `status/`。

禁止写入：后端项目和前端项目；不得在交接仓库复制或伪造 OpenAPI 权威文件；不得未经授权推送远端。

### Backend Codex

职责：在后端项目实现后端业务代码和测试，识别接口影响，提交后端到前端的交接信息，并响应前端反馈。

允许写入：`G:/Dev/backend/Club/CoderClub/**`；交接仓库内仅允许写入 `designs/backend/**`、`handoff/backend-to-frontend/**`、`proposals/backend/**`、`acceptance/backend/**` 和 `status/backend.json`。

禁止写入：前端项目、交接仓库的权威治理文件、`api/`、`sync-manifest.json` 及对方角色的目录。契约变更必须先写入 `proposals/backend/`，等待协调和授权。

### Frontend Codex

职责：在前端项目实现前端业务代码和测试，消费已确认的接口契约，提交前端到后端的交接信息，并报告接口阻塞。

允许写入：`G:/Dev/backend/Club/CoderClubFront/**`；交接仓库内仅允许写入 `designs/frontend/**`、`handoff/frontend-to-backend/**`、`proposals/frontend/**`、`acceptance/frontend/**` 和 `status/frontend.json`。

禁止写入：后端项目、交接仓库的权威治理文件、`api/`、`sync-manifest.json` 及对方角色的目录。契约变更必须先写入 `proposals/frontend/`，等待协调和授权。

## 协作规则

1. 后端项目中的 API 定义和实现是运行契约的权威来源；交接仓库只保存引用、决策和同步记录。
2. 任何接口字段、路径、鉴权、错误码或兼容性变更，先写入对应的 `proposals/`，不得直接改写权威 API。
3. 交接内容必须包含来源项目、提交哈希、影响范围、验证结果和接收方动作。
4. `status/*.json` 记录当前状态，不以状态文件替代代码或契约本身。
5. 提交前检查 `git diff --check` 和 `git status --short`；推送远端必须得到 PM 的明确授权。
