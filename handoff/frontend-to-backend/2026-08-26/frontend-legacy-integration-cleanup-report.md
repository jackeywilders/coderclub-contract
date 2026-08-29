# 前端遗留整合与清理任务回执（A10：T1 契约字段对齐 + T2 退出按钮 + T3 清理）

> 回执角色：前端实现（F-Impl）
> 回执日期：2026-08-26
> 任务书：`pm/requirements/2026-08-26/frontend-legacy-integration-cleanup-task.md`（派发 PR #60，`7b98b36`）
> 依据：`docs/agents/verification-workflow.md` §6 双轨（Markdown + `*-summary.json`）
> 契约快照：`8ebcda53…`（零变更，本任务未改 `api/` 快照与 `sync-manifest.json`）

## 1. 来源与提交哈希

| 字段 | 值 |
| --- | --- |
| 来源项目 | `G:/Dev/backend/Club/CoderClubFront`（前端代码仓库，private） |
| 来源分支 | `feat/legacy-integration-a10`（基于 main `601d778` 创建） |
| 实施提交 SHA | `7731a2db`（feat(auth): 契约字段对齐 userName/nickName）、`d55dd819`（feat(subject): 答题退出按钮） |
| 合并提交 SHA | `3d34dc68`（Merge pull request #11，mergedAt 2026-08-26T14:51:52Z，合入授权 = 用户，F-Impl 经 GitHub MCP 执行 merge） |
| PR 号 | 前端仓库 **#11** |
| R2 状态 | ✅ 已合入 `main`（远端核验：`main` HEAD = `3d34dc68`，API 通道） |
| 契约快照 SHA-256 | `8ebcda53…`（交接仓库 `sync-manifest.json` 当前值，本任务零变更） |

## 2. T1 auth 契约字段对齐（对齐 `a43aeb3`）

main 上登录/注册/绑定链路对齐契约 `LoginDTO{userName,password}`、`RegisterDTO{userName,password,nickName}`、`BindAccountDTO{wxOpenId,userName,password}`：

- `src/api/auth.ts`：`login`/`register`/`bindAccount` 请求字段 `username→userName`、`nickname→nickName`
- `src/stores/user.ts`：`login` 调用 `{ username, password }` → `{ userName: username, password }`（函数参数名保留，非请求键）
- `src/views/login/RegisterView.vue`：表单全链路 `form.username→form.userName`、`form.nickname→form.nickName`（模板 `prop`/`v-model`、form 模型、`rules`、提交 payload）
- 字段残留扫描：上述三文件内契约字段名残留为 0；不改行为逻辑

## 3. T2 答题「退出答题」按钮

- `src/views/subject/answer/SubjectAnswer.vue`：题目内容区顶部「退出答题」按钮（`el-button` + `ArrowLeft` 图标 + `router.back()`），`ArrowLeft` 加入 icons import
- 以 main 为基线（参照 worktree 2 工作树版本）；**未**引入 worktree 2 中 `SubjectAnswerPanel.vue` 的追齐痕迹（其内容已在 main）

## 4. 验证结果

| 命令 | 结果 |
| --- | --- |
| `npm test` | 10/10 pass，exit 0 |
| `npm run api:check` | SHA `0dae8d3a…`（前端基线，A3 同步值），43 endpoints，无差异 |
| `npm run lint`（主范围 src/scripts） | exit 0（遗留 `.worktrees/` 干扰已随 T3 清理消除） |
| `npm run build` | vue-tsc --noEmit + vite build exit 0 |
| 前端 CI | PR #11 `check` SUCCESS（run 32982121517，2026-08-25 14:44:41Z 完成） |

## 5. T3 环境清理（T1/T2 合入 main 后执行，2026-08-26 实测）

| 项 | 结果 |
| --- | --- |
| worktree 移除 | `git worktree remove --force` ×2（`feat-subject-real-api`、`feat-view-contract-alignment`）；`worktree list` 仅余 main；空 `.worktrees/` 目录与 `.git/worktrees` 元数据已清除 |
| 本地分支删除 | `git branch -D` ×6：`chore/remove-deprecated-contract-workflow`、`ci/github-actions`、`feat/frontend-history`、`feat/g1-03-baseline`、`feat/subject-real-api-integration`、`feat/subject-view-contract-alignment`；本地仅余 `main` |
| 远端分支删除 | `gh api -X DELETE` ×11（任务书清单 10 + 本次 PR #11 来源分支 `feat/legacy-integration-a10`）：`chore/remove-deprecated-contract-workflow`、`ci/github-actions`、`docs/engineering-skill-setup`、`docs/governance-compliance`、`feat/contract-convergence`、`feat/frontend-history`、`feat/g1-03-baseline`、`feat/subject-real-api-integration`、`feat/subject-view-contract-alignment`、`refactor/subject-remove-keyword-param`、`feat/legacy-integration-a10`；远端核验仅余 `main`（`3d34dc68`） |
| 保留 | `main` 完好（远端 `3d34dc68`） |

## 6. 声明

- 未修改交接仓库 `api/` 快照、`status/sync-manifest.json` 与任何治理文件；未触碰后端项目（规则 8/19）。
- 远端操作（分支/提交/PR/删除）经 GitHub MCP / gh API 通道（规则 17）。
- 本地前端仓库 `main` 停留 `601d778`（git 传输受限未 fetch 到 `3d34dc68`）；已合入内容以远端核验为准，本地副本待网络恢复后同步。
- 无真实环境信息（规则 8）。

## 7. 关联（建议后续）

- 契约 `UserInfoVO`/`LoginUserInfo`/`AdminAuthUser` 亦为 `userName/nickName`，前端用户信息链路（`src/types/auth.d.ts`、`layout/Navbar.vue`、`views/user/UserProfile.vue`、`views/user/UserManage.vue`）仍消费 `username/nickname`——超出本任务 T1 边界（仅 LoginDTO/RegisterDTO/BindAccountDTO），建议后续任务对齐。

## 8. 版本记录

- 2026-08-26：创建（任务书派发后执行；T1/T2 经 PR #11 合入 main、T3 清理完成、回执提交）。
