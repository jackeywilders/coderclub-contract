# 任务书：前端遗留工作整合与清理（A10，源于 A7 勘察）

> **派发角色：** 协调 PM
> **派发日期：** 2026-08-26
> **执行角色：** 前端实现（F-Impl）
> **复核角色：** 前端评审（F-Review）
> **背景（A7 勘察结论）：** 前端项目 `.worktrees/` 存在 2 个工作区，勘察发现 `feat/subject-view-contract-alignment` 分支（ahead=1）含**未合入 main 的有效工作**。用户三向决策：① auth 契约字段对齐合入 main；② 「退出答题」按钮保留合入；③ 本任务（含清理）由前端实现角色执行。

## 1. 目标

把两块未合入工作整合进 `main`，并清理前端项目残留 worktree 与已合入分支，使 CoderClubFront 回到「仅 main + 活动分支」的干净状态。

## 2. 实施边界（仅以下范围，禁止扩大）

### T1 auth 契约字段对齐（来源：提交 `a43aeb3`，未合入）

main 前端当前与契约快照不一致（契约 `LoginDTO{userName,password}`、`RegisterDTO{userName,password,nickName}`、`BindAccountDTO{wxOpenId,userName,password}`），需对齐：

- `src/api/auth.ts`：`login`/`register`/`bindAccount` 请求字段 `username`→`userName`、`nickname`→`nickName`
- `src/stores/user.ts`：对应字段调用点同步
- `src/views/login/RegisterView.vue`：`form.username`→`form.userName`、`form.nickname`→`form.nickName`
- 实施方式：从 worktree `.worktrees/feat-view-contract-alignment` 分支 `feat/subject-view-contract-alignment` 取提交 `a43aeb3`（cherry-pick 或手工重放）；main 上相关文件若有后续演进，以适配合并为准，**不改行为逻辑**
- 硬条件：`userName`/`nickName` 全链路一致（api 签名 + store 调用 + 表单提交）；契约字段名不出现 `username`/`nickname` 残留（排除无关上下文注释/第三方）

### T2 答题「退出答题」按钮合入（来源：worktree 2 工作树未提交改动）

- 内容：`src/views/subject/answer/SubjectAnswer.vue` 顶部「退出答题」返回按钮（`el-button` + `ArrowLeft` 图标 + `router.back()`；Icon 导入 `ArrowLeft` from `@element-plus/icons-vue`）——参照 worktree 2 工作树版本
- **注意**：worktree 2 中 `SubjectAnswerPanel.vue` 的工作树差异（`w-full text-left`、`optionLetter(opt, opt)` 签名等）为向 main 追齐的痕迹、内容已在 main——**以 main 为基线，不重复引入**

### T3 环境清理（T1/T2 合入 main 后执行）

1. `git worktree remove .worktrees/feat-subject-real-api`（分支 `feat/subject-real-api-integration` 已合入、工作树干净）
2. `git worktree remove .worktrees/feat-view-contract-alignment`（T1/T2 合入后，工作树不应再有未合入内容）
3. 删除本地分支：`chore/remove-deprecated-contract-workflow`、`ci/github-actions`、`feat/frontend-history`、`feat/g1-03-baseline`、`feat/subject-real-api-integration`、`feat/contract-convergence`、`refactor/subject-remove-keyword-param`、`feat/subject-view-contract-alignment`（后两个在 T1/T2 合入后删）
4. 删除远端分支（同上清单，含 `feat/contract-convergence`、`docs/engineering-skill-setup`、`docs/governance-compliance`），用 `git push origin --delete` 或 `gh api -X DELETE`
5. 保留：`main`

## 3. 禁止事项

- 不修改交接仓库 `api/` 快照、`status/sync-manifest.json` 及任何治理文件（本任务为前端消费对齐与本地环境清理，契约快照 `8ebcda53` 零变更）
- 不重写与本次无关的代码；不引入 worktree 2 中已由 main 涵盖的重复内容
- 删除 worktree 前确认无未合入内容（T1/T2 已覆盖）；不触碰后端项目

## 4. 交付与回执（规则 9 双轨）

1. 实施提交推送到前端仓库（`G:/Dev/backend/Club/CoderClubFront`），提交信息按 Conventional Commits（如 `feat(auth): align login/register/bindAccount fields with contract (userName/nickName)`；`feat(subject): add exit button on answer page`）。
2. 回执双轨提交到交接仓库 `handoff/frontend-to-backend/2026-08-26/`：Markdown 正文（来源与提交哈希表、T1/T2/T3 逐项明细、验证证据、清理清单）＋ 同目录 `*-summary.json`（按模板字段：`taskId=A10`、`sourceProject=G:/Dev/backend/Club/CoderClubFront`、`contractSnapshotSha256=8ebcda53`（零变更）、`verificationResult`、`verificationDate`）。
3. 完成通知带规则 9 四字段（实施 SHA、回执 SHA、PR 号、R2 状态），告知前端评审复核签署；回执经 `claude/frontend-proposals` PR 合入交接仓库 main（governance-check 自动合并）。
4. 前端评审复核签署后通知 PM；PM 验收并推进状态。

## 5. 验收标准

- [ ] main 上 `auth.ts`/`stores/user.ts`/`RegisterView.vue` 契约字段为 `userName`/`nickName`（与快照 LoginDTO/RegisterDTO/BindAccountDTO 一致；`username`/`nickname` 消费残留为 0）
- [ ] `SubjectAnswer.vue`「退出答题」按钮合入且功能可用（点击返回上一页）
- [ ] 前端构建/类型校验通过（附命令与输出，如 `npm run build` / `vue-tsc` 等既有基线）
- [ ] worktree ×2 已移除；远端 10 个已合入分支 + 本地对应分支清理完毕；`main` 完好
- [ ] 回执双轨落 `handoff/frontend-to-backend/2026-08-26/`，通知带四字段远端证据

## 6. 关联

- 勘察背景：A7 前端 worktree/分支整理（协调 PM 2026-08-26 只读勘察结论）
- 契约依据：交接仓库 `api/coderclub-openapi.json`（`LoginDTO`/`RegisterDTO`/`BindAccountDTO`）
- 来源提交：`a43aeb3`（`feat/subject-view-contract-alignment` 分支）；worktree 2 工作树（退出按钮）
- 前端评审复核：签署回执（`acceptance/frontend/`）后转 PM 验收