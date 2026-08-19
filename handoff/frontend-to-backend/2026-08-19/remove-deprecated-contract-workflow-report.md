# 前端移除弃用 contract-workflow.ps1 指引回执

> 回执角色：前端评审（F-Review）
> 回执日期：2026-08-19
> 任务书：`pm/requirements/2026-08-19/frontend-remove-deprecated-contract-workflow-task.md`
> 依据：`docs/agents/verification-workflow.md` §6 双轨（Markdown + `*-summary.json`）

## 1. 来源与提交哈希

| 字段 | 值 |
| --- | --- |
| 来源项目 | `G:/Dev/backend/Club/CoderClubFront`（前端代码仓库，private） |
| 来源分支 | `chore/remove-deprecated-contract-workflow` → 合入 `main` |
| 实施提交 SHA | `634c22a`（docs(governance): remove deprecated contract-workflow.ps1 guidance） |
| 合并提交 SHA | `a71a8db`（Merge pull request #8） |
| PR 号 | 前端仓库 **#8** |
| R2 状态 | 已合入 `main`（`git merge-base --is-ancestor 634c22a origin/main` ✓，mergedAt 2026-08-19T17:45:15Z） |
| 契约快照 SHA-256 | 未涉及（本任务不涉及契约变更；快照变化见 P1/P3 实施回执） |

## 2. 落地内容

1. **`CLAUDE.md` 第 19 条改写**（与任务书指定文本一致）：移除 `scripts\contract-workflow.ps1` 引用，改为"不执行任何 worktree 创建/同步/Snapshot 命令（已弃用）；交接仓库同步与合入一律走 Git 远端流程（角色分支 → PR → governance-check 自动合并）；本地状态以 `git fetch origin` 后各角色分支为准（规则 9）"。
2. **`package.json` 移除 `contract:check`** npm script（任务书可选项）。已确认前端 `ci.yml` 无 `contract:check` 依赖（仅 api:check 相关），移除不影响 CI。

## 3. 验证结果

- 前端 `ci` workflow `check` **SUCCESS**（GitHub Actions；`package.json` 变更触发完整 npm test / lint / api:check / build）。
- 合入后核验：`origin/main` 的 `CLAUDE.md` 第 19 条已为新表述；`package.json` 无 `contract` 引用。
- 本地 `main` 已快进到 `a71a8db`（= origin/main），工作树干净。

## 4. 关联（不阻塞）

- 任务书关联项：全局规范 `~/.zcode/AGENTS.md` 补"命令工具连续失败 2-3 次即换通道"建议句，由协调 PM 另行处理（本次前端任务不涉及）。

## 5. 声明

- 本回执不修改 `api/` 快照、`status/sync-manifest.json`、后端项目；无真实环境信息（规则 8）。
- 附注（流程记录）：本任务合入前曾遇 gh 客户端 keyring token 失效 + 代理环境变量格式异常，经使用 GCM 凭据临时修复后完成查询与合入；该工具故障已按"如实报告 + 降级通道"处理，不影响交付物。

## 6. 版本记录

- 2026-08-19：创建（前端评审回执，任务书 §3）。