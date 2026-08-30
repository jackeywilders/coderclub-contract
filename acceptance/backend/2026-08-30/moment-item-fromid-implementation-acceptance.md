# MomentItemVO 补 fromId（MOMENT-ITEM-FROMID）——PM 验收

> 验收角色：协调 PM
> 验收日期：2026-08-30
> 回执：`handoff/backend-to-frontend/2026-08-30/backend-moment-item-fromid-report.md` + `backend-moment-item-fromid-summary.json`（PR #119，head `4592191`，已合入 main）
> 复核签署：`acceptance/backend/2026-08-30/moment-item-fromid-review-signoff.md`（PR #120，merged `8ca4ab1`，MCP 核验；工作底稿 `designs/backend/2026-08-30/moment-item-fromid-review-workpaper.md`）
> 状态：**验收通过**

## 1. 验收结论

✅ **MOMENT-ITEM-FROMID 验收通过。** 实施 `1fbf0ad`（6 commits，经 CoderClub PR #18 合入 main `86a09e7e`）经 B-Review 复核签署（PR #120）与 PM 独立核验，与提案 `proposals/frontend/2026-08-30/moment-item-fromid-proposal.md`（PR #111）及 PM 决策（PR #114）相符；快照微同步随本验收执行（`MomentItemVO.fromId` 采纳，75 路径不变）。

## 2. 规则 9 核验链（四字段）

| 字段 | 值 |
| --- | --- |
| 实施提交 SHA | `1fbf0ad`（`1fbf0ad83f4270c735b6de95b24db51538f4d1bc`，6 commits） |
| 回执提交 SHA | `4592191`（回执 PR #119，已合入 main） |
| PR 号 | CoderClub PR #18——**merged（merge `86a09e7e`，2026-08-30T16:58:03Z）** |
| R2 状态 | ✅ 双达成：实施合入 CoderClub main（`86a09e7e`）；签署 PR #120 合入交接仓库 main |

## 3. PM 独立复核（非签署转录）

1. **源契约实测（远端 main）**：`docs/api/coderclub-openapi.json` LF SHA-256 = `26AEC009C4A823629DCC1D6EB5984773791BC3380407F846AAA7D4308F12CC90`（gh API 拉取复算，与回执/签署逐字一致）；75 路径 / 119 schemas；`MomentItemVO` 新增 `fromId: string`（description 注明与 `CommentNodeVO.fromId` 同源、前端「本人动态」精确判定），getMoments 200 example 同步登记；**路径数不变（75）**。
2. **实现语义相符**：组装取**动态创建人**（`bo.getCreatedBy()` 直取），非当前查看者；判别性断言（createdBy=2002 vs 登录 2001）锚定创建人取值——与提案 D3/PM 决策意图一致（任务书 §1.2 字面措辞歧义已由 B-Review 核查澄清，实现符合意图）。
3. **快照微同步执行**：`6262F444 → 74417DD8`（75 路径 / 119 schemas / LF 无尾换行 2 空格缩进）；与源 diff 复核 = **12 项**（10 脱敏 + 2 治理修正，构成不变）；`MomentItemVO.fromId` 随源采纳，不构成快照-源差异。
4. **敏感扫描**：零 hex-token / 零 IP；URL 全部 example.com / localhost 占位；JSON 语法与格式校验通过。

## 4. 快照微同步登记

| 项 | before | after |
| --- | --- | --- |
| sourceCommit | `90a1e96`（list 实施） | `1fbf0ad`（`1fbf0ad83f4…`，fromId 实施，CoderClub PR #18 → main `86a09e7e`） |
| sourceSha256（LF） | `24DC8414…` | `26AEC009C4A823629DCC1D6EB5984773791BC3380407F846AAA7D4308F12CC90` |
| snapshotSha256 | `6262F44477A1A6887668F3514B506D6874EDCC645516D471131A2D2A3A2CB439` | `74417DD8ECDF835BE33688BC14C1A4CA8E3D11BDD8F9559056EBE86ED0F85182` |
| pathCount / operationCount | 75 / 75 | **75 / 75**（fromId 字段级采纳，路径数不变） |
| semanticDifferenceCount | 12 | **12**（构成不变：10 脱敏 + 1 `IdentifierUserItem` 类级 description + 1 `info.description` 路径计数 74→75，源侧计数措辞待下次实现轮顺带修正） |

## 5. 小瑕疵登记（不阻塞，按治理惯例）

| 项 | 说明 |
| --- | --- |
| `receiptCommitSha` 空串 | 回执 summary 漏填回执提交 SHA（历史同类，登记）；实际回执提交 = `4592191` |
| `contractSnapshotSha256` 误记 | 回执 summary 记 `AE967C70`（任务书派发时值），实际验收基线快照为 `6262F444`；以本验收 §4 登记为准 |

## 6. 后续

1. **F-Impl 小批派发**：前端一行切换（`src/utils/circle.ts` `canDeleteMoment` 改精确匹配 `fromId === String(当前用户 id)`，移除 D3 昵称临时兜底）——随本验收批次派发（另任务书）。
2. **F-Impl 第二批（管理端敏感词管理页）**：执行中（任务书 `sensitive-words-manage-frontend-task.md`，消费快照 `74417DD8` 需同步——list 端点不受 fromId 影响，基线仍 75）。
3. 阶段四（interview）评估 / A9 发布门禁（待用户授权）照常待办。

---

验收人：协调 PM，2026-08-30
