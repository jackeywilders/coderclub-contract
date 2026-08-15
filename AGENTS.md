# CoderClub 交接仓库协作约定

本仓库是 CoderClub 后端、前端与 PM 之间的契约交接区。它记录决策、交接、验收和状态。经 PM 批准的 `api/coderclub-openapi.json` 是后续跨项目开发使用的权威契约快照；后端项目中的 API 定义仍是运行时权威来源。

## 项目路径

- 后端项目：`G:/Dev/backend/Club/CoderClub`
- 前端项目：`G:/Dev/backend/Club/CoderClubFront`
- 交接仓库：`G:/Dev/backend/Club/coderclub-contract`
- 当前 PM 工作目录：`G:/Dev/backend/Club/coderclub-contract-codex-pm`

## 协调角色与实际执行角色

> 五角色的现行名称、会话输入别名与旧名对照见 [docs/agents/role-naming.md](docs/agents/role-naming.md)（更名生效于 2026-08-15；历史文档保留旧名）。

### 协调 PM

职责：维护交接仓库治理规则，汇总需求与决策，协调后端和前端交接，维护路线图、报告、验收记录及同步状态。

允许写入：当前交接仓库内的全部治理路径，包括 `AGENTS.md`、`CLAUDE.md`、`docs/`、`api/`、`designs/`、`handoff/`、`proposals/`、`acceptance/`、`pm/` 和 `status/`。

禁止写入：后端项目和前端项目；不得未经来源核验或 PM 批准写入、替换 `api/` 契约快照；不得未经授权推送远端。

### 后端评审

职责：分析后端接口影响，编写 `proposals/backend/` 契约提案，审查后端实现的提交，提交后端到前端的交接信息，执行复验并响应前端反馈。

允许写入：交接仓库内仅允许写入 `designs/backend/**`、`handoff/backend-to-frontend/**`、`proposals/backend/**`、`acceptance/backend/**` 和 `status/backend.json`。

禁止写入：后端项目、前端项目、交接仓库的权威治理文件、`api/`、`sync-manifest.json` 及对方角色的目录。不得代替后端实现修改 Java、测试或后端运行时 API 源。契约变更必须先写入 `proposals/backend/`，等待 PM 确认。

### 后端实现

职责：在后端项目实现已获 PM 确认的业务代码、测试和必要的本地验证；按照批准的契约提案同步后端运行时 API 源，并提交完整实现证据。

允许写入：`G:/Dev/backend/Club/CoderClub/**`；其中 `docs/api/coderclub-openapi.json` 只有在对应 `proposals/backend/` 已获 PM 确认后，才允许作为实现的一部分更新。

禁止写入：前端项目、交接仓库的治理文件、交接仓库 `api/` 快照、`status/sync-manifest.json`、对方角色目录及未经批准的契约变更。不得自行决定接口路径、方法、字段、鉴权、错误码或兼容性策略。

### 前端评审

职责：审查前端实现的提交，复验已确认的接口契约消费，提交前端到后端的交接信息，执行验收并报告接口阻塞。

允许写入：交接仓库内仅允许写入 `designs/frontend/**`、`handoff/frontend-to-backend/**`、`proposals/frontend/**`、`acceptance/frontend/**` 和 `status/frontend.json`。

禁止写入：前端项目、交接仓库的权威治理文件、`api/`、`sync-manifest.json` 及对方角色的目录。不得代替前端实现修改 `src/`、前端测试或项目基线。契约变更必须先写入 `proposals/frontend/`，等待 PM 确认。

### 前端实现

职责：在前端项目实现已确认的业务代码、测试和必要的项目基线更新，并提交前端实现证据。

允许写入：`G:/Dev/backend/Club/CoderClubFront/**`；消费已确认的交接仓库契约快照和 PM 批准的前端提案。

禁止写入：后端项目、交接仓库治理文件、交接仓库 `api/` 快照、`status/sync-manifest.json` 及未经确认的契约变更。发现契约问题时必须先写入 `proposals/frontend/`，不得通过修改基线绕过评审。

## 远端与合入流程（2026-08-16 起）

- **主远端**：GitHub `github.com/jackeywilders/coderclub-contract`（公开仓库）；Gitee 保留为备份 remote（`gitee`），不用于日常协作。
- 各角色在**角色分支**上提交并 push，发起 PR 到 `main`；`main` 不接受直接 push。
- PR 满足分支保护条件（无冲突 + `governance-check` 通过）后由 GitHub **自动合并**到 `main`；`pr-sync-main` 自动把最新 `main` 合并进 PR 分支，冲突时留给人工解决。
- 涉及 `api/` 契约快照、发布状态（`releaseStatus`/`finalReleaseStatus`）、治理文件的变更仍由协调 PM 把关，不得绕过评审直接合入。

## 协作规则

1. 后端项目中的 API 定义和实现是运行时权威来源；经 PM 批准的 `api/coderclub-openapi.json` 是后续跨项目开发的权威契约快照。快照必须记录来源提交、源 SHA-256、快照提交、快照 SHA-256 和语义差异。
2. 任何接口字段、路径、鉴权、错误码或兼容性变更，先写入对应的 `proposals/`；后端评审/前端评审不得直接改写运行时源文件或 `api/` 快照。
3. 交接内容必须包含来源项目、提交哈希、影响范围、验证结果和接收方动作。
4. `status/*.json` 记录当前状态，不以状态文件替代代码或契约本身。
5. push 角色分支并发起 PR 属于日常协作，无需逐次授权；`main` 的变更一律经 PR 自动合并（见"远端与合入流程"）。强制推送、历史改写、删除远端分支等危险操作仍须 PM 明确授权。
6. 交接仓库内新建的任何文档（提案、设计、交接、验收、评审、报告、路线图等），必须先在其所属目录下建立 `YYYY-MM-DD/` 日期目录（以文档创建日期为准，Asia/Shanghai），再写入该目录；文件名不再带日期前缀。豁免固定路径文件：`AGENTS.md`、`CLAUDE.md`、`CONTEXT.md`、`docs/INDEX.md`、`docs/adr/**`、`docs/agents/**`、`api/**` 契约快照、`status/*.json` 状态文件、`_template-*` 模板与 `.gitkeep`。存量文档的迁移也遵循同一布局。
7. 本机全局已配置 `prepare-commit-msg` 钩子（`git config --global core.hooksPath`），自动剥离 AI 工具追加的 `Co-Authored-By: Claude ...` 提交署名行，对所有仓库与提交工具生效（2026-08-15 起）；约定细节、副作用与回退方式见 `docs/agents/git-commit-conventions.md`。历史提交保留原样。
8. 交接文档中的真实环境信息（IP/域名/端口/凭据值/测试账号密码/内部库名/namespace）一律以占位符呈现（语义化占位符，规范见 `docs/agents/sensitive-data-conventions.md`）；**提交消息与 PR 描述同样公开且受此约束**；真实值对照表由协调 PM 维护在私有位置，不得提交到本仓库或任何公开远端。2026-08-15 历史脱敏改写后旧提交哈希失效，追溯以协调 PM 私有对照表或改写前备份为准。
