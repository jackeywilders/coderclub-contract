# PM 验收：前端契约收敛（A3，T1/T2/T3/T5）

> **验收角色：** 协调 PM
> **验收日期：** 2026-08-26
> **任务书：** `pm/requirements/2026-08-26/frontend-contract-convergence-task.md`（PR #38，`40b60916`）
> **回执：** `handoff/frontend-to-backend/2026-08-26/frontend-contract-convergence-report.md` + `-summary.json`（PR #42 签署 / PR #43 补记回执 SHA，均已合入交接仓库 main）
> **实现：** 前端仓库 PR #9（merge `d81e665c`，2026-08-25T16:08:16Z）

## 1. 规则 9 远端证据

| 字段 | 值 |
| --- | --- |
| 实施提交 SHA | `b303bbc`（docs(api): 基线更新至 P1/P3 快照）、`7113535`（feat: sort UI + subjectScore 默认 10）、`19405019`（refactor: 抽 useOptionLetter composable） |
| 回执提交 SHA | `9d071f13`（交接仓库 PR #42）；`d9b4de8`（summary.json blob，PR #43 补记） |
| PR 号 | 前端仓库 **#9**；交接仓库 #42/#43 |
| R2 状态 | 均已合入 `main`（前端 merge `d81e665c`；交接仓库 PR #42/#43 经自动合并，`42fdeb4` 为 main 顶端） |

## 2. 验收结论

✅ **A3 主体验收通过，同意关闭（T1/T2/T3/T5）。** 附带一项收尾项（见 §5 观察 1）：A2 决策 §3.3 的 `keyword` 死参数清理正由前端实现执行中，完成后追加回执并由 PM 追加关闭本验收。

## 3. 逐项核验（PM 依前端 PR #9 `get_files` 抽查）

| 任务 | 验收点 | 核验结果 |
| --- | --- | --- |
| T1 基线更新 | `api:check` 差异恰为 3 处新增后 `--update-baseline` | ✅ `docs/frontend/handoff/api-docs-baseline.json` 已更新（1526+/- 对称重排）；回执 §3 `api:check` passed（SHA `0dae8d3a`、43 endpoints、No changes detected）；schema 级差异实测恰 3 处（`SubjectCategoryDTO.sort`/`SubjectPageQueryDTO.subjectType`/getSubjectPage example `subjectType`） |
| T2 subjectScore | add 路径默认 10 | ✅ `SubjectEdit.vue` `buildPayload` `subjectScore: 10`（P2 决策：仅 add 必填、`settleName` 可选，`settleName: ''` 保留）；过期「待回执（P2）」注释已清理 |
| T3 sort 收敛 | 排序展示 + 可编辑 + 不再硬编码 `sort: 0` | ✅ `CategoryManage.vue` 新增「排序」展示列（`row.sort ?? '-'`）、「排序值」输入（`el-input-number :min=0`）；`form.sort: 0 → null`、`openEditDialog` 回显 `row.sort ?? null`、`handleSave` 空值 `delete payload.sort`；`src/types/subject.d.ts` 补 `sort?: number` |
| T5 顺带 | 抽 composable + 补换行 | ✅ `src/composables/useOptionLetter.ts` 新建；`SubjectEdit.vue`/`SubjectAnswerPanel.vue` 两处引用替换（`optionLetter(opt.optionType, opt)` → `optionLetter(opt.optionType)`）；`CategoryManage.vue` 文件尾补换行 |

## 4. 验证证据

- 前端 CI（PR #9 触发 `check`）：✅ SUCCESS（GitHub Actions run `32868497169`，2026-08-25T15:53:17Z 完成）。
- 回执 §3 四命令全绿（`api:check`/`npm test` 10/10/`lint`（src/scripts 范围）/`build`）；lint 全量限制为遗留 `.worktrees/` 干扰（B5，非本次改动）。
- 契约核对：相对旧快照 `9a97c055` 的差异恰为 3 处新增，无路径/方法/鉴权结构差异。
- 状态文件（T4，随回执执行）：`status/frontend.json` → `gate3-p1p3-accepted-snapshot-consumed`，`consumedSha256` = `0dae8d3a…`（LF/CRLF 双值），`lastCommit` = `d81e665c`，`historicalConsumedSha256` = `9a97c055…` —— 与 `sync-manifest.json`（快照 `0DAE8D3A`）一致。

## 5. 验收意见

1. **收尾项（不阻塞主体）**：`keyword` 死参数清理（A2 决策 `pm/reviews/2026-08-26/getSubjectPage-schema-alignment-decision.md` §3.3）——F-Impl 执行中；完成后按已发指示**追加**更新 A3 回执（report 增「§A2 addendum」小节 + summary 增 `addendumCommitSha`），合入后 PM 追加关闭本验收并更新 `frontend.json` `lastCommit`。
2. **关联不阻塞**：B1——`subject_category.sort` 运行时 DB ALTER 待运维/用户，排序真实语义待 ALTER 后验证（T3 代码收敛不依赖）；B5——前端仓库遗留 `.worktrees/` 清理待用户授权。
3. **条件成就**：A3 已合入 → A2 实施阶段（后端 controller 收窄为 `SubjectPageQueryDTO`）派发条件已满足，待 PM 派发后端实现；与 `keyword` 清理并行无冲突（不同仓库/代码面）。

## 6. 版本记录

- 2026-08-26：创建（A3 主体验收通过；`status/pm.json` state → `gate3-a3-accepted`）。
