# 角色名称对照

> 生效日期：2026-08-15（Asia/Shanghai）
> 用途：记录 CoderClub 交接仓库五角色的名称更名与对应关系。历史文档保留旧名，阅读时以本表对照；新文档一律使用现行名称。

## 现行名称（自 2026-08-15 起）

| 现行名称 | 会话输入别名 | 层级 | 职责 | 对应分支/目录 |
| --- | --- | --- | --- | --- |
| 协调 PM | PM | 协调层 | 跨项目治理、决策、验收、发布门禁 | `pm`、`pm/`、`status/pm.json` |
| 后端评审 | B-Review | 协调层 | 后端契约提案、回执复核签署、后端交接 | `review/backend`、`proposals/backend/`、`status/backend.json` |
| 后端实现 | B-Impl | 执行层 | 后端业务代码、测试、实现证据 | `impl/backend`、`G:/Dev/backend/Club/CoderClub/**` |
| 前端评审 | F-Review | 协调层 | 前端契约消费复核、验收、阻塞报告 | `review/frontend`、`proposals/frontend/`、`status/frontend.json` |
| 前端实现 | F-Impl | 执行层 | 前端业务代码、测试、项目基线 | `impl/frontend`、`G:/Dev/backend/Club/CoderClubFront/**` |

## 旧名对照（2026-08-15 前使用）

| 旧名 | 现行名称 |
| --- | --- |
| PM / 跨项目协调 Codex | 协调 PM |
| Backend Codex | 后端评审 |
| Claude Code 后端 | 后端实现 |
| Frontend Codex | 前端评审 |
| Claude Code 前端 | 前端实现 |

## 更名范围说明

- 本次仅更名人类可读的角色称呼；8-15 当时**不改动**分支名、worktree 目录名、角色目录、`status/*.json` 的 `role` 字段值、`api/` 契约快照及历史归档文档。（分支名与 worktree 目录的后续重排见下「分支治理规范」2026-09 变更。）
- 历史归档文档（`pm/reviews/`、`handoff/`、`proposals/`、`acceptance/` 等日期目录下已创建文档）保留旧名，作为当时的决策记录；追溯阅读时按本表及「分支历史对照」对照。
- 新文档一律使用现行名称。

## 分支治理规范（2026-09-01 生效）

### 角色分支（稳定，唯一）

每个角色一个稳定分支，命名**不绑定任何 AI 工具**（8-15 前的 `codex/*`、`claude/*` 前缀已废弃）：

| 角色 | 分支 | 目录空间 |
| --- | --- | --- |
| 协调 PM | `pm` | `pm/`、`status/pm.json` |
| 后端评审 B-Review | `review/backend` | `proposals/backend/`、`designs/backend/`、`acceptance/backend/`、`status/backend.json` |
| 后端实现 B-Impl | `impl/backend` | `handoff/backend-to-frontend/` |
| 前端评审 F-Review | `review/frontend` | `proposals/frontend/`、`designs/frontend/`、`acceptance/frontend/`、`status/frontend.json` |
| 前端实现 F-Impl | `impl/frontend` | `handoff/frontend-to-backend/` |

### 任务分支规范

- **前后端代码仓库**：实现分支统一 `feat/<域>-<特性>`（`feat/backend-*`、`feat/frontend-*`），**单分支单 PR**、CI（含敏感扫描）全绿后合入 main、**合入即删**。
- **交接仓库回执**：回执（Markdown 正文 + `*-summary.json` 双轨）直接在**角色稳定分支**上一次性提交并发 PR，**不再创建 `receipt/*`、`*-backfill` 等一次性回执分支**，杜绝分支膨胀。
- 一次性任务分支合入 main 后即删除（远端 + 本地），不作为常驻分支保留。

### 分支历史对照（2026-09-01 前旧名 → 现名）

用于追溯 2026-09-01 前历史文档/PR 中的旧分支引用（历史归档不回改）：

| 旧分支名 | 现分支名 | 角色 |
| --- | --- | --- |
| `codex/pm-coordination` | `pm` | 协调 PM |
| `codex/backend-contract` | `review/backend` | 后端评审 B-Review |
| `claude/backend-proposals` | `impl/backend` | 后端实现 B-Impl |
| `codex/frontend-design` | `review/frontend` | 前端评审 F-Review |
| `claude/frontend-proposals` | `impl/frontend` | 前端实现 F-Impl |

> 注：8-29 后 B-Review 实际以 `claude/backend-proposals` 作为签署/提案通道（旧名），改名后统一为 `review/backend`；`codex/backend-contract` 已于 8-27 停用。历史回执分支（`claude/backend-*-receipt` 等）均为一次性分支，已删除，不在对照表内。
