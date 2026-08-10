# CoderClub 交接仓库协作约定

本仓库是 CoderClub 后端、前端与 PM 之间的契约交接区。它记录决策、交接、验收和状态。经 PM 批准的 `api/coderclub-openapi.json` 是后续跨项目开发使用的权威契约快照；后端项目中的 API 定义仍是运行时权威来源。

## 项目路径

- 后端项目：`G:/Dev/backend/Club/CoderClub`
- 前端项目：`G:/Dev/backend/Club/CoderClubFront`
- 交接仓库：`G:/Dev/backend/Club/coderclub-contract`
- 当前 PM 工作目录：`G:/Dev/backend/Club/coderclub-contract-codex-pm`

## 协调角色与实际执行角色

### PM / 跨项目协调 Codex

职责：维护交接仓库治理规则，汇总需求与决策，协调后端和前端交接，维护路线图、报告、验收记录及同步状态。

允许写入：当前交接仓库内的全部治理路径，包括 `AGENTS.md`、`CLAUDE.md`、`docs/`、`api/`、`designs/`、`handoff/`、`proposals/`、`acceptance/`、`pm/` 和 `status/`。

禁止写入：后端项目和前端项目；不得未经来源核验或 PM 批准写入、替换 `api/` 契约快照；不得未经授权推送远端。

### Backend Codex

职责：分析后端接口影响，编写 `proposals/backend/` 契约提案，审查 Claude Code 后端的实现提交，提交后端到前端的交接信息，执行复验并响应前端反馈。

允许写入：交接仓库内仅允许写入 `designs/backend/**`、`handoff/backend-to-frontend/**`、`proposals/backend/**`、`acceptance/backend/**` 和 `status/backend.json`。

禁止写入：后端项目、前端项目、交接仓库的权威治理文件、`api/`、`sync-manifest.json` 及对方角色的目录。不得代替 Claude Code 后端修改 Java、测试或后端运行时 API 源。契约变更必须先写入 `proposals/backend/`，等待 PM 确认。

### Claude Code 后端

职责：在后端项目实现已获 PM 确认的业务代码、测试和必要的本地验证；按照批准的契约提案同步后端运行时 API 源，并提交完整实现证据。

允许写入：`G:/Dev/backend/Club/CoderClub/**`；其中 `docs/api/coderclub-openapi.json` 只有在对应 `proposals/backend/` 已获 PM 确认后，才允许作为实现的一部分更新。

禁止写入：前端项目、交接仓库的治理文件、交接仓库 `api/` 快照、`status/sync-manifest.json`、对方角色目录及未经批准的契约变更。不得自行决定接口路径、方法、字段、鉴权、错误码或兼容性策略。

### Frontend Codex

职责：审查 Claude Code 前端的实现提交，复验已确认的接口契约消费，提交前端到后端的交接信息，执行验收并报告接口阻塞。

允许写入：交接仓库内仅允许写入 `designs/frontend/**`、`handoff/frontend-to-backend/**`、`proposals/frontend/**`、`acceptance/frontend/**` 和 `status/frontend.json`。

禁止写入：前端项目、交接仓库的权威治理文件、`api/`、`sync-manifest.json` 及对方角色的目录。不得代替 Claude Code 前端修改 `src/`、前端测试或项目基线。契约变更必须先写入 `proposals/frontend/`，等待 PM 确认。

### Claude Code 前端

职责：在前端项目实现已确认的业务代码、测试和必要的项目基线更新，并提交前端实现证据。

允许写入：`G:/Dev/backend/Club/CoderClubFront/**`；消费已确认的交接仓库契约快照和 PM 批准的前端提案。

禁止写入：后端项目、交接仓库治理文件、交接仓库 `api/` 快照、`status/sync-manifest.json` 及未经确认的契约变更。发现契约问题时必须先写入 `proposals/frontend/`，不得通过修改基线绕过评审。

## 协作规则

1. 后端项目中的 API 定义和实现是运行时权威来源；经 PM 批准的 `api/coderclub-openapi.json` 是后续跨项目开发的权威契约快照。快照必须记录来源提交、源 SHA-256、快照提交、快照 SHA-256 和语义差异。
2. 任何接口字段、路径、鉴权、错误码或兼容性变更，先写入对应的 `proposals/`；Backend/Frontend 不得直接改写运行时源文件或 `api/` 快照。
3. 交接内容必须包含来源项目、提交哈希、影响范围、验证结果和接收方动作。
4. `status/*.json` 记录当前状态，不以状态文件替代代码或契约本身。
5. 提交前检查 `git diff --check` 和 `git status --short`；推送远端必须得到 PM 的明确授权。
