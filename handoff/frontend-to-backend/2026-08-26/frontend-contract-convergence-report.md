# 前端契约收敛任务回执（T1 基线 + T2 subjectScore + T3 sort + T5 清理）

> 回执角色：前端评审（F-Review）
> 回执日期：2026-08-26
> 任务书：`pm/requirements/2026-08-26/frontend-contract-convergence-task.md`（T1/T2/T3 + T5 顺带，F-Impl 执行 / F-Review 复核签署）
> 依据：`docs/agents/verification-workflow.md` §6 双轨（Markdown + `*-summary.json`）

## 1. 来源与提交哈希

| 字段 | 值 |
| --- | --- |
| 来源项目 | `G:/Dev/backend/Club/CoderClubFront`（前端代码仓库，private） |
| 来源分支 | `feat/contract-convergence` → 合入 `main` |
| 实施提交 SHA | `b303bbc`（docs(api): baseline 更新至 P1/P3 快照）、`7113535`（feat(subject): sort UI + subjectScore 默认 10）、`19405019`（refactor(subject): 抽 optionLetter composable） |
| 合并提交 SHA | `d81e665c`（Merge pull request #9，mergedAt 2026-08-25T16:08:16Z） |
| PR 号 | 前端仓库 **#9** |
| R2 状态 | 已合入 `main`（`git merge-base --is-ancestor 19405019 origin/main` ✓，API 通道核验） |
| 契约快照 SHA-256 | `0dae8d3a…`（43 endpoints，源 `f964f88`/`05933BEA…`；3 处新增：`SubjectCategoryDTO.sort`、`SubjectPageQueryDTO.subjectType`、getSubjectPage 请求示例 `subjectType`） |

## 2. 落地内容（逐项对照任务书）

| 任务 | 验收点 | 落地 |
| --- | --- | --- |
| T1 基线更新 | `api:check` 差异恰为 3 处新增后 `--update-baseline` | `docs/frontend/handoff/api-docs-baseline.json` `specSha256` 同步至 `0dae8d3a…`（43 endpoints，schema 摘要无端点级差异） |
| T2 subjectScore | add 路径默认 10 | `SubjectEdit.vue` `buildPayload` `subjectScore: 0 → 10`，清理过期"待回执（P2）"注释（P2 决策：仅 add 必填，`settleName` 可选） |
| T3 sort 收敛 | 排序展示列 + 表单可编辑，payload 不再硬编码 `sort:0` | `CategoryManage.vue` 新增"排序"展示列（空值显示 -）与"排序值"输入（默认空/不传，空值 delete payload.sort）；`src/types/subject.d.ts` 补 `SubjectCategory.sort?` |
| T5 顺带 | 抽 composable + 补换行 | `OPTION_LETTERS`/`optionLetter` 由 `SubjectEdit.vue` / `SubjectAnswerPanel.vue` 抽为 `src/composables/useOptionLetter.ts`；`CategoryManage.vue` 文件尾补换行 |

## 3. 验证结果（2026-08-26 前端评审本机复验 + CI）

| 命令 | 结果 |
| --- | --- |
| `npm run api:check` | ✅ SHA `0dae8d3a…`，43 endpoints，**No API contract changes detected** |
| `npm test` | ✅ 10/10 pass，0 fail |
| `npm run lint`（src/scripts 范围 `--fix=false`） | ✅ exit 0（全量 lint 受遗留 `.worktrees/` 旧代码干扰，B5 阻塞项，非本次改动） |
| `npm run build` | ✅ vue-tsc --noEmit + vite build 成功 |
| 前端 CI（PR #9 触发 `check`） | ✅ SUCCESS（GitHub Actions run 32868497169，2026-08-25T15:53:17Z 完成） |

## 4. 契约核对

新快照相对旧快照（`9a97c055…`）的 schema 级差异实测**恰为 3 处**（2026-08-26 本机 `api:check` 复验）：`SubjectCategoryDTO +sort`、`SubjectPageQueryDTO +subjectType`、getSubjectPage 请求 example +`subjectType`；无路径/方法/鉴权结构差异。P1/P2/P3 决策依据 `pm/reviews/2026-08-18/p1-p2-p3-interface-decisions.md`（已闭环）；任务书派发 PR #38（交接仓库 main，`40b60916`）。

## 5. 状态文件（T4，随本任务执行）

`status/frontend.json` 已刷新：`state` → `gate3-p1p3-accepted-snapshot-consumed`；`contract.sourceCommit` → `f964f88`、`sourceSha256`/`consumedSha256` → `0dae8d3a…`（LF SHA `0dae8d3a753ec86048601813950f2be59a2c03d2386c5697a44970b15a988d61`，磁盘 CRLF 变体 `12a193ac…`）；`historicalConsumedSha256` → `9a97c055…`；`lastCommit` → `d81e665c`；`lastHandoff`/`consumptionReceipt` → 本回执路径。与 `status/pm.json`（`gate3-p1p3-accepted-snapshot-synced`）及 `sync-manifest.json`（快照 `0DAE8D3A`）一致。

## 6. 关联（不阻塞）

- B1：`subject_category.sort` 运行时 DB ALTER 待运维/用户（后端侧），排序真实语义待 ALTER 后验证；T3 代码收敛不依赖。
- B4：getSubjectPage 请求 schema 整段对齐提案已由后端评审提出（`proposals/backend/2026-08-26/getSubjectPage-request-schema-alignment-proposal.md`，PR #40），待 PM 决策，不阻塞本任务。
- B5：前端仓库遗留 `.worktrees/`（两个）仍待用户授权清理。

## 7. 声明

- 本回执不修改 `api/` 快照、`status/sync-manifest.json`、后端项目；无真实环境信息（规则 8）。
- 本地前端仓库 `main` 尚未包含 PR #9 合入（本机 git 传输偶发受阻，R2 经 GitHub API 通道核验）；回执提交后由用户/前端评审按需同步本地副本。
- 流程记录：前端仓库 git fetch 连续受阻（github.com:443 连接失败），按全局规则第 17 条切换 GitHub MCP/gh API 通道完成合入与核验；不绕过合入条件（CI SUCCESS + mergeable clean）。

## 8. 版本记录

- 2026-08-26：创建（前端评审回执，任务书 T1/T2/T3/T5）。

## 9. A2 addendum：移除 SubjectList.vue keyword 死参数（2026-08-26 用户补充决策）

> 补充来源：用户 2026-08-26 指令（A2 决策，A3 主体验收后追加）。
> 说明：`SubjectList.vue` 的 `keyword` 查询参数为死参数（后端 `getSubjectPage` 无 `subjectName` 筛选，静默忽略），随收敛清理移除；前端侧清理，**无需契约变更**；标题搜索能力如需另行提案（不在本期）。

| 字段 | 值 |
| --- | --- |
| 实施提交 SHA | `d825a183`（`refactor(subject): remove dead keyword query param (A2)`，前端仓库 `refactor/subject-remove-keyword-param` 分支，单 commit） |
| PR 号 | 前端仓库 **#10** |
| 影响文件 | `src/views/subject/info/SubjectList.vue`（删除关键词输入框、`queryParams.keyword`、`handleReset` 重置项；保留题型/难度/分类筛选与搜索/重置逻辑） |
| 验证结果 | `npm run lint`（主范围 src/scripts）exit 0；`npm run build`（vue-tsc --noEmit + vite build）exit 0；无 API/契约变更（`api:check`/`npm test` 不涉及） |
| R2 状态 | **已合入 `main`**（前端 PR #10 merge `601d778e`，2026-08-25T16:42:02Z；合入人：前端评审，用户授权） |