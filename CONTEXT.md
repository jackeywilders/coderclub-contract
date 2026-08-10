# CoderClub 项目上下文

## 项目定位

本仓库是 CoderClub 后端、前端与 PM 之间的契约交接仓库，记录需求、决策、API 交接、验收和同步状态。它不替代后端项目中的权威 API，也不允许 Agent 通过交接文件绕过提案和评审流程。

## 相关项目

- 后端：`G:/Dev/backend/Club/CoderClub`
- 前端：`G:/Dev/backend/Club/CoderClubFront`
- 交接仓库主目录：`G:/Dev/backend/Club/coderclub-contract`
- 当前 PM worktree：`G:/Dev/backend/Club/coderclub-contract-codex-pm`

## 当前协作状态

PM 当前负责跨项目基线、优先级和发布裁决；Backend 负责后端业务实现与运行时证据；Frontend 负责前端业务实现与消费验证。契约、鉴权、方法、字段、错误码和兼容性问题必须先进入 `proposals/backend/` 或 `proposals/frontend/`。

最近审查的主线引用为 `origin/main`。详细状态以 `status/pm.json`、`status/backend.json`、`status/frontend.json` 和 `status/sync-manifest.json` 为准；发布状态必须由 PM 明确授权。

## 首次读取顺序

1. `AGENTS.md`：角色职责和允许写入范围。
2. `CLAUDE.md`：Claude Code 的业务代码和契约处理边界。
3. 本文件：项目上下文和文档入口。
4. `docs/INDEX.md`：目录用途、状态文件和 compact 恢复流程。
5. 相关 `docs/adr/`、`proposals/`、`handoff/`、`acceptance/` 和 `pm/` 文件。
