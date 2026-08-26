# 前端评审签署：前端遗留整合与清理（A10，T1/T2/T3）

> **签署角色：** 前端评审（F-Review）
> **签署日期：** 2026-08-26
> **任务书：** `pm/requirements/2026-08-26/frontend-legacy-integration-cleanup-task.md`（PR #60，`7b98b36`）
> **回执：** `handoff/frontend-to-backend/2026-08-26/frontend-legacy-integration-cleanup-report.md` + `-summary.json`（PR #61，merge `7aa649b6`；receiptCommitSha 回填 PR #62，`daa68ba`）
> **实现：** 前端仓库 PR #11（`feat/legacy-integration-a10`，merge `3d34dc68`，2026-08-26T14:51:52Z）

## 1. 规则 9 远端证据（人链核验）

| 字段 | 值 |
| --- | --- |
| 实施提交 SHA | `7731a2db`（feat(auth): 契约字段对齐 userName/nickName）、`d55dd819`（feat(subject): 答题退出按钮） |
| 合并提交 SHA | `3d34dc68`（Merge pull request #11） |
| 回执提交 SHA | `1ea8c29b`（回执主体，PR #61） |
| PR 号 | 前端仓库 **#11**；交接仓库 #61/#62 |
| R2 状态 | 均已合入 `main`（前端 `git merge-base --is-ancestor 7731a2db origin/main` ✓，main HEAD=`3d34dc68`；交接仓库 PR #61 merge `7aa649b6`、PR #62 merge `daa68ba`） |
| 契约快照 SHA-256 | `8ebcda53…`（零变更，api 文件实测 SHA-256 `8ebcda5362bc…`） |

## 2. 复核结论

✅ **A10 复核通过，同意签署。** T1 auth 契约字段对齐、T2 答题退出按钮、T3 worktree/分支清理三块均满足任务书验收标准；回执双轨齐全、证据链完整。

## 3. 人链核验明细（F-Review 逐项验证，API 通道）

### T1 auth 契约字段对齐（对照契约快照 `LoginDTO{userName,password}` / `RegisterDTO{userName,password,nickName}` / `BindAccountDTO{wxOpenId,userName,password}`）

| 文件 | 核验结果 |
| --- | --- |
| `src/api/auth.ts` | ✅ `login({userName,password})`、`register({userName,password,nickName?})`、`bindAccount({wxOpenId,userName,password})`；全文件 `userName`×3 + `nickName`×1，**无 `username`/`nickname` 残留** |
| `src/stores/user.ts` | ✅ `login({ userName: username, password })`——请求键 `userName`；`username` 仅为形参名（非请求键，与回执口径一致） |
| `src/views/login/RegisterView.vue` | ✅ 模板 `prop`/`v-model`、form 模型、`rules`、提交 payload 全链路 `userName`/`nickName`（逐行核对，无残留；`username` 匹配为大小写不敏感误报，实际全为 `userName`） |
| 行为逻辑 | 未改动（仅字段名对齐） |

### T2 答题「退出答题」按钮

- ✅ `src/views/subject/answer/SubjectAnswer.vue`：题目区顶部「退出答题」按钮（`el-button text` + `<el-icon><ArrowLeft/></el-icon>` + `router.back()`）；`ArrowLeft` 已加入 `@element-plus/icons-vue` import。
- ✅ 未引入 worktree 2 中 `SubjectAnswerPanel.vue` 的追齐痕迹（main 基线正确）。

### T3 环境清理（本机 + 远端双通道核验）

| 项 | 核验结果 |
| --- | --- |
| worktree ×2 | ✅ `worktree list` 仅余 main；`.worktrees/` 目录已移除 |
| 本地分支 | ✅ 本地仅余 `main` |
| 远端分支 | ✅ API + `git ls-remote` 双通道：仅余 `main`（`3d34dc68`）— 11 个分支（任务书清单 10 + PR #11 来源分支）已删 |
| main | ✅ 完好（远端 `3d34dc68`；本地已快进同步） |

## 4. 验证证据

- 前端 CI（PR #11 `check`）：✅ **SUCCESS**（GitHub Actions run `32982121517`，2026-08-26T14:44:41Z 完成，API 通道核验）。
- 回执 §4 四命令：`npm test` 10/10、`api:check`（前端基线 SHA `0dae8d3a…`）无差异、`lint`（src/scripts）exit 0、`build`（vue-tsc + vite）exit 0。
- 契约核对：快照 `8ebcda53`（api 文件 SHA-256 实测）零变更；前端基线 `0dae8d3a…` 为 A3 同步值，不变更。

## 5. 附带发现（建议后续，非本任务阻塞）

回执 §7 同口径：契约 `UserInfoVO`/`LoginUserInfo`/`AdminAuthUser` 亦为 `userName/nickName`，但前端用户信息链路（`src/types/auth.d.ts`、`layout/Navbar.vue`、`views/user/UserProfile.vue`、`views/user/UserManage.vue`）仍消费 `username/nickname`——超出 A10 T1 边界（仅 LoginDTO/RegisterDTO/BindAccountDTO），建议 PM 后续派发专项对齐任务。

## 6. 签署意见

✅ **签署通过**。A10（T1/T2/T3）实施与回执均满足任务书验收标准，同意转协调 PM 验收。签署依据：回执双轨（PR #61 + 回填 PR #62）+ 前端 PR #11 合入（`3d34dc68`）+ 本文件人链核验记录。

## 7. 版本记录

- 2026-08-26：创建（前端评审签署，转 PM 验收）。