# 前端契约收敛任务书（T1 快照基线 + T2 subjectScore + T3 sort 收敛）

> **任务角色：** 前端实现（F-Impl）执行，前端评审（F-Review）复核签署
> **下发角色：** 协调 PM
> **日期：** 2026-08-26
> **来源：** 四份角色待办报告 + 推荐优先级第 1 项；决策依据 `pm/reviews/2026-08-18/p1-p2-p3-interface-decisions.md`（P1/P2/P3 已闭环）
> **前提：** 契约快照已由 PM 同步（`0DAE8D3A`，源 `f964f88`/`05933BEA`）；`pm.json` 已对齐（PR #37）；git/gh 已确认可用

## 1. 背景与目标

契约快照自 P1/P3 实施后已更新（3 处新增：`SubjectCategoryDTO.sort`、`SubjectPageQueryDTO.subjectType`、`getSubjectPage` 请求示例 `subjectType`），但前端消费基线仍为旧快照（`9a97c055…`）。本任务把前端契约消费收敛到最新快照，并落实 P1/P2/P3 决策的前端侧动作，使前端状态与后端/交接仓库一致。

## 2. 前置准备（执行前必须完成）

| # | 前置 | 处理方式 | 状态 |
| --- | --- | --- | --- |
| P1 | `api-docs-path.txt` 指向的文件更新为最新快照（`0DAE8D3A`） | ① 推荐：经 GitHub MCP 下载交接仓库 main 最新 `api/coderclub-openapi.json` 落 `CoderClubFront/local/` 并改 `api-docs-path.txt` 指向（本地，gitignore，不越界写交接仓库）；② 或 `git -C G:/Dev/backend/Club/coderclub-contract fetch origin` 更新主仓 worktree（属交接仓库范畴，fetch 只读可执行，不 push） | 前端实现处理 |
| P2 | 角色分支 `claude/frontend-proposals` 落后 main 约 20+ 提交 | 提交前 `git fetch origin` + 基于最新 main 重建/合并角色分支（走 Git 远端流程，不执行 worktree 命令） | 前端实现处理 |

## 3. 任务内容（T1/T2/T3 + T5 顺带）

### T1 · 消费新契约快照并更新前端基线（高优先）
1. 前置 P1/P2 完成后，`npm run api:check` 确认失败差异**恰为 3 处新增**（`SubjectCategoryDTO.sort`、`SubjectPageQueryDTO.subjectType`、`getSubjectPage` example subjectType）。
2. `npm run api:check -- --update-baseline` 更新 `docs/frontend/handoff/api-docs-baseline.json`。
3. 验证四命令全绿：`npm test` / `npm run api:check` / `npm run lint` / `npm run build`。

### T2 · P2 字段适配：`subjectScore` 默认值（中优先）
- `src/views/subject/info/SubjectEdit.vue` `buildPayload`：`subjectScore: 0` → **默认 10**（仅 add 路径必填；update 不触发校验；`settleName` 确认可选处理，清理过期注释）。

### T3 · P1 配套：分类 `sort` 前端收敛（中优先）
- `src/views/subject/category/CategoryManage.vue`：当前固定携带 `sort: 0`（后端补字段后会真实入库 0=排最前）→ 收敛为**排序展示列 + 表单可编辑（默认空/不传）** 或按 PM 对齐后移除硬编码；不破坏既有分类功能。

### T5 · 顺带清理（低优先，随 T1-T3 同 PR）
- `OPTION_LETTERS`/`optionLetter` 在 `SubjectEdit.vue` 与 `SubjectAnswerPanel.vue` 重复定义 → 抽 composable。
- `CategoryManage.vue` 文件末尾补换行符。

## 4. 验收标准

1. `npm test` / `npm run api:check` / `npm run lint` / `npm run build` 全绿；基线含 `sort`/`subjectType`。
2. 端到端：add 题目请求携带 `subjectScore: 10` 后端校验通过；分类树展示/编辑排序值且 payload 不再硬编码 `sort:0`。
3. 前端 CI（PR 触发 `check`）SUCCESS；合入前端 main（合入人 = 用户或前端评审）。
4. 回执按规则 9 双轨落交接仓库 `handoff/frontend-to-backend/2026-08-26/`（Markdown + `*-summary.json`），通知带实施 SHA/回执 SHA/PR 号/R2 状态。

## 5. 边界与规则

- 只改前端 `src/`、测试与 `docs/frontend/handoff/api-docs-baseline.json`（G1-03 既有流程）。
- 不修改后端项目、交接仓库治理文件、`api/` 快照、`status/sync-manifest.json`；不越界写交接仓库。
- 契约疑问（如有新发现）先走 `proposals/frontend/` + PM 确认，不自行裁决。
- 提交遵循 Conventional Commits；规则 8（无真实环境信息）；验证被拦截时如实报告、禁止跳过验证声称完成。

## 6. 关联（不阻塞本任务）

- 运行时 DB ALTER（`subject_category.sort` 加列）待运行环境凭据，属后端/运维；T3 代码收敛不依赖，真实排序语义待 ALTER 后验证。
- A4（`status/frontend.json` 刷新）随本任务合入后由前端评审执行。

- 下发角色：协调 PM
- 日期：2026-08-26
