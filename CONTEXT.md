# CoderClub 项目上下文

## 项目定位

本仓库是 CoderClub 后端、前端与 PM 之间的契约交接仓库，记录需求、决策、API 交接、验收和同步状态。后端项目中的 API 是运行时权威来源；PM 批准的 `api/coderclub-openapi.json` 是后续跨项目开发的权威契约快照。Agent 仍不得通过交接文件绕过提案和评审流程。

## 相关项目

- 后端：`G:/Dev/backend/Club/CoderClub`
- 前端：`G:/Dev/backend/Club/CoderClubFront`
- 交接仓库主目录：`G:/Dev/backend/Club/coderclub-contract`
- 当前 PM worktree：`G:/Dev/backend/Club/coderclub-contract-pm`

## 当前协作状态

PM 当前负责跨项目基线、优先级和发布裁决；后端评审负责后端契约提案与签署复核、后端实现负责后端业务实现与运行时证据；前端评审负责前端契约消费复核与验收、前端实现负责前端业务实现与消费验证。契约、鉴权、方法、字段、错误码和兼容性问题必须先进入 `proposals/backend/` 或 `proposals/frontend/`。

最近审查的主线引用为 `origin/main`。开发契约快照已由 PM 批准用于后续开发消费，但不代表运行时发布或 `finalReleaseStatus` 已放行。详细状态以 `status/pm.json`、`status/backend.json`、`status/frontend.json` 和 `status/sync-manifest.json` 为准；发布状态必须由 PM 明确授权。

## 统一术语

- **运行时权威 API：** 后端项目 `CoderClub/docs/api/coderclub-openapi.json` 及其实现，决定真实服务行为。
- **开发契约快照：** 交接仓库 `api/coderclub-openapi.json`，经 PM 依据来源提交和哈希批准，供后续前后端开发消费。
- **发布契约：** 经过 Gate 0/1、M4 和 PM 发布验收后才可进入发布流程；开发契约快照获批不等于发布契约已发布。

## 首次读取顺序

1. `AGENTS.md`：角色职责和允许写入范围。
2. `CLAUDE.md`：Claude Code 的业务代码和契约处理边界。
3. 本文件：项目上下文和文档入口。
4. `docs/INDEX.md`：目录用途、状态文件和 compact 恢复流程。
5. 相关 `docs/adr/`、`proposals/`、`handoff/`、`acceptance/` 和 `pm/` 文件。
