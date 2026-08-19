# 前端治理补强任务书：移除已弃用 contract-workflow.ps1 指引

> **任务角色：** 前端评审（F-Review）/ 前端实现（F-Impl）
> **下发角色：** 协调 PM
> **日期：** 2026-08-19
> **来源：** 前端 agent 会话循环诊断 + 前端治理文件排查
> **范围：** 前端代码仓库 `G:/Dev/backend/Club/CoderClubFront/CLAUDE.md`（第 19 条）及 `package.json`（`contract:check` 脚本）

## 1. 背景

1. **前端 agent 会话（session-dd53d3ab）循环根因**：pwsh 工具间歇性参数校验失败，agent 反复重试同一工具 5+ 次才切换，被循环检测器拦截。治理层面缺"工具故障降级"约定（另见全局规范补强）。
2. **排查发现**：`scripts/contract-workflow.ps1` 已逻辑弃用（硬编码旧 worktree 路径，与现行 `codex/*`、`claude/*` 分支工作流不一致），但前端 `CLAUDE.md` 第 19 条仍引用它作为"worktree 同步由用户执行"的依据，且 `package.json` 的 `contract:check` 仍绑定该脚本。已由用户确认 **弃用**。

## 2. 待应用改动（前端 `CLAUDE.md` 第 19 条）

**现状：**
```
- worktree 同步由用户在自己的 PowerShell 中通过 `scripts\contract-workflow.ps1` 完成；**不要执行 SyncWorktrees、Snapshot 或 worktree 创建命令**。
```

**改写为（移除弃用脚本引用，改为符合现行远端流程的表述）：**
```
- **不执行任何 worktree 创建 / 同步 / Snapshot 命令**（`contract-workflow.ps1` 已弃用）。交接仓库的同步与合入一律走 Git 远端流程：提交到角色分支 → PR 到 `main` → governance-check 自动合并；本地 worktree 状态以 `git fetch origin` 后各角色分支为准（规则 9 远程优先核验）。
```

**可选（待前端评审确认）`package.json`：**
- `contract:check` 脚本当前为 `powershell ... -File scripts/contract-workflow.ps1 -Action Check`，因脚本弃用，建议移除该 npm script 或改为直接 `git fetch` 检查（若前端 CI 依赖 `contract:check`，需先确认后改，避免破坏 CI）。

## 3. 执行与验收

1. 前端实现/评审在前端 `CLAUDE.md` 应用上述改写（及经确认的 `package.json` 调整），提交遵循 Conventional Commits（如 `docs(governance): remove deprecated contract-workflow.ps1 guidance`）。
2. 前端 CI（`npm test`/lint/api:check/build）全绿；若移除 `contract:check` 影响 CI，须在 PR 中说明并同步 `ci.yml`。
3. 经 PR 合入前端 `main`（合入人 = 用户或前端评审）；回执按规则 9 双轨落交接仓库 `handoff/frontend-to-backend/2026-08-19/`。
4. 提交与 PR 描述遵守规则 8（无真实环境信息）。

## 4. 关联（不阻塞本任务）

- 全局规范 `~/.zcode/AGENTS.md` 将补"命令工具连续失败 2-3 次即换通道、不硬试"建议句（跨会话防循环），由协调 PM 另行处理。

- 下发角色：协调 PM
- 日期：2026-08-19