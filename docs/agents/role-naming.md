# 角色名称对照

> 生效日期：2026-08-15（Asia/Shanghai）
> 用途：记录 CoderClub 交接仓库五角色的名称更名与对应关系。历史文档保留旧名，阅读时以本表对照；新文档一律使用现行名称。

## 现行名称（自 2026-08-15 起）

| 现行名称 | 会话输入别名 | 层级 | 职责 | 对应分支/目录 |
| --- | --- | --- | --- | --- |
| 协调 PM | PM | 协调层 | 跨项目治理、决策、验收、发布门禁 | `codex/pm-coordination`、`pm/`、`status/pm.json` |
| 后端评审 | B-Review | 协调层 | 后端契约提案、回执复核签署、后端交接 | `codex/backend-contract`、`proposals/backend/`、`status/backend.json` |
| 后端实现 | B-Impl | 执行层 | 后端业务代码、测试、实现证据 | `claude/backend-proposals`、`G:/Dev/backend/Club/CoderClub/**` |
| 前端评审 | F-Review | 协调层 | 前端契约消费复核、验收、阻塞报告 | `codex/frontend-design`、`proposals/frontend/`、`status/frontend.json` |
| 前端实现 | F-Impl | 执行层 | 前端业务代码、测试、项目基线 | `claude/frontend-proposals`、`G:/Dev/backend/Club/CoderClubFront/**` |

## 旧名对照（2026-08-15 前使用）

| 旧名 | 现行名称 |
| --- | --- |
| PM / 跨项目协调 Codex | 协调 PM |
| Backend Codex | 后端评审 |
| Claude Code 后端 | 后端实现 |
| Frontend Codex | 前端评审 |
| Claude Code 前端 | 前端实现 |

## 更名范围说明

- 本次仅更名人类可读的角色称呼，**不改动**：分支名、worktree 目录名、角色目录（`proposals/backend/` 等）、`status/*.json` 中的 `role` 字段值（`pm` / `backend` / `frontend`）、`api/` 契约快照及历史归档文档。
- 历史归档文档（`pm/reviews/`、`handoff/`、`proposals/`、`acceptance/` 等日期目录下已创建文档）保留旧名，作为当时的决策记录；追溯阅读时按本表对照。
- 新文档一律使用现行名称。
