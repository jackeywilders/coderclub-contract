# 前端 fromId 判定切换小批实施回执（A8-P3-FE D3）

> 回执角色：前端实现（F-Impl）
> 回执日期：2026-08-30
> 依据：`docs/agents/verification-workflow.md` §6 双轨（Markdown + `*-summary.json`）
> 契约快照：`74417dd8`（75 路径，specSha256 `74417dd8ecdf835be33688bc14c1a4ca8e3d11bdd8f9559056ebe86ed0f85182`）
> 来源分支：`feat/frontend-a8-p3-fromid-switch`（rebase 至含敏感词批合入的最新 `main` 后，4 commits 小批）

## 0. TLDR

本人动态判定由「昵称/ID 匹配」临时兜底切换为 **fromId 精确匹配**（D3 小批，类型 + 判定 + 调用 + 单测 + 基线五处改动）。分支已 rebase 至最新 `main`（含敏感词批 PR #18 合入），rebase 后 tree 与 rebase 前逐位一致（a859b77c）。本地门禁全绿（api:check No changes / lint 0 / vue-tsc 0 / 等价全量单测 53/53），前端 PR #19 CI check=success。回执双轨落交接仓库。

## 1. 来源与提交哈希

| 字段 | 值 |
| --- | --- |
| 来源项目 | `G:/Dev/backend/Club/CoderClubFront`（前端代码仓库，private） |
| 来源分支 | `feat/frontend-a8-p3-fromid-switch`（基于 `main` 7905579 = 敏感词批 PR #18 合入后的最新 main，4 commits 小批） |
| 设计/计划提交 SHA | `f4c128b`（docs(frontend): fromId 前端切换小批设计文档与实现计划） |
| 基线提交 SHA | `7c21ecc`（chore(api): update contract baseline to 75 endpoints，specSha256 → 74417dd8） |
| 类型提交 SHA | `86fb5af`（feat(types): MomentItemVO 补 fromId） |
| 实施提交 SHA（判定切换） | `ed12997`（feat(circle): 本人动态判定切换 fromId 精确匹配，分支 tip） |
| PR 号 | 前端仓库 **#19**（`feat/frontend-a8-p3-fromid-switch` → `main`，CI check=success） |
| R2 状态 | 否（PR #19 已开、CI 绿，待用户/F-Review 手动合入） |
| 契约快照 SHA-256 | `74417dd8ecdf835be33688bc14c1a4ca8e3d11bdd8f9559056ebe86ed0f85182`（75 路径） |

## 2. PM 决策依据

- 提案：`proposals/frontend/2026-08-30/moment-item-fromid-proposal.md`（随 A8-P3-FE 第一批提交交接仓库，PR #111 合入）
- PM 决策：交接仓库 **PR #114**（`docs(pm): review fromId proposal (D3) - confirm MomentItemVO fromId`，2026-08-30 12:11 UTC 合入 main）——确认本人动态判定使用 `fromId` 精确匹配
- 后端实现：commit `86a09e7`（后端 MomentItemVO 补 `fromId`）

## 3. 改动面（5 处，全部为 fromId 判定小批内容）

| 文件 | 改动 |
| --- | --- |
| `src/types/circle.d.ts` | `MomentItemVO` 补充 `fromId` 字段（类型层） |
| `src/utils/circle.ts` | 本人动态判定由临时兜底切换为 **fromId 精确匹配**（判定层） |
| `src/views/circle/components/MomentCard.vue` | 删除按钮展示判定调用点同步（调用层） |
| `src/__tests__/circle.test.ts` | 单测同步更新至 fromId 判定语义（单测） |
| `docs/frontend/handoff/api-docs-baseline.json` | 契约基线 specSha256 更新至 `74417dd8`（75 端点，与 main 基线 6262F444 端点数一致、无端点冲突）（基线） |

## 4. 验证结果

| 命令 | 结果 |
| --- | --- |
| `npm run api:check` | `Endpoints: 75`、`SHA-256: 74417dd8…`、**No API contract changes detected** |
| `npm run lint` | exit 0 |
| `npx vue-tsc --noEmit` | exit 0 |
| 等价全量单测（`node --experimental-strip-types --test --experimental-test-isolation=none scripts/check-api-spec.test.mjs src/api/response-interceptor.test.ts src/__tests__/practice.test.ts src/__tests__/circle.test.ts src/__tests__/sensitive.test.ts`） | **53/53 pass**（8 suites, 0 fail） |
| rebase 一致性 | `git rebase origin/main` 4/4 无冲突重放（origin/main = 7905579，含 #18 合入）；rebase 后 `HEAD^{tree}` = rebase 前 `d1cd63d^{tree}` = `a859b77c`，逐位一致；`origin/main..HEAD` diff 仅 7 个 fromId 文件 |
| CI | 前端 PR #19 `check` conclusion=success（run 33330381997，job 99307784396，40s） |

> 登记说明（如实）：`npm test` 原命令与 `npm run build`（vite 阶段）在本任务沙箱下未现场执行；等价全量单测以 dispatch 指定命令直跑 node test runner 替代（53/53 pass），CI 的 `npm test` 与 `build` 阶段均绿（check=success），两者互为兜底。本任务无代码改动，rebase 保留既有 commits。

## 5. 完成通知四字段（§2）

| 字段 | 值 |
| --- | --- |
| 实施提交 SHA | `ed12997`（前端分支 tip，完整 `ed12997aa9acd98bf4b96ff93509945ad1f6348e`） |
| 回执提交 SHA | `42e5f68b`（本回执在交接仓库的提交，完整 `42e5f68bad2736d2241ca705a0d49c7183680967`） |
| PR 号 | 前端 **#19**；回执 PR **#128**（governance-check 自动合入，2026-08-30 19:20 UTC） |
| R2 状态 | 否（前端 PR #19 已开、CI 绿；回执 PR 待 governance-check 自动合入） |

## 6. Frontend 声明

我确认以上消费文件、来源、哈希和验证结果真实可复核；未确认的字段、方法、鉴权或错误码没有被前端自行推断。

- Frontend 角色：前端实现（F-Impl）
- 日期：2026-08-30
