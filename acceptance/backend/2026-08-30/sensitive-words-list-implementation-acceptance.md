# 敏感词词库 list 端点（SENSITIVE-WORDS-LIST）——PM 验收

> 验收角色：协调 PM
> 验收日期：2026-08-30
> 回执：`handoff/backend-to-frontend/2026-08-30/backend-sensitive-words-list-report.md` + `backend-sensitive-words-list-summary.json`（PR #109，head `028bcbc`，已合入 main `e3f5462`）
> 复核签署：`acceptance/backend/2026-08-30/sensitive-words-list-review-signoff.md`（PR #110，merged `83f7a0fd`，MCP 核验）
> 状态：**验收通过**

## 1. 验收结论

✅ **SENSITIVE-WORDS-LIST 验收通过。** 实施 `90a1e96`（5 commits，经 CoderClub PR #17 合入 main `8617d9de`）经 B-Review 复核签署（PR #110）与 PM 独立核验，与提案 `proposals/backend/2026-08-30/sensitive-words-list-proposal.md`（PR #107）及 PM 决策 L1-L3（全量列表口径，PR #108）相符；快照微同步 74→**75** 随本验收执行。

## 2. 规则 9 核验链（四字段）

| 字段 | 值 |
| --- | --- |
| 实施提交 SHA | `90a1e96`（`90a1e966eae1f6994fecdf923de49c1e990ba70e`，5 commits，含审查修复波） |
| 回执提交 SHA | `028bcbc`（PR #109，已合入 main `e3f5462`） |
| PR 号 | CoderClub PR #17——**merged（merge `8617d9de`，2026-08-30T10:33:18Z）** |
| R2 状态 | ✅ 双达成：实施合入 CoderClub main（`8617d9de`）；签署 PR #110 合入交接仓库 main（`83f7a0fd`） |

## 3. PM 独立复核（非签署转录）

1. **源契约实测（远端 main）**：`docs/api/coderclub-openapi.json` LF SHA-256 = `24DC841402BB5E063758A4156FC3AAF8D84609845BC218D92D0DC8FE6C7DD82A`（gh API 拉取复算，与回执/签署逐字一致）；**75 路径 / 119 schemas**；新增 `/circle/sensitive/words/list`（类级 `@SaCheckLogin` + 方法 `@SaCheckRole("admin_user")`，无请求体，返回 `ResponseResult<List<SensitiveWordItemVO>>`）+ `SensitiveWordItemVO {id, words, type, createdTime}`（required = id/words/type）+ `ResponseResultSensitiveWordItemList` wrapper。
2. **L1-L3 语义相符**：全量列表（type ASC + id ASC，非分页）；只读边界（list 端点不触 DFA 快照/重建，`verifyNoMoreInteractions` 锚定）；`createdTime` 存量 NULL 如实、新增词带时间（契约测试硬断言）；schema 文档 `created_time datetime DEFAULT NULL` 与用户 2026-08-30 云端已执行 DDL 对齐（A1 模式登记，无运行时 DDL）。
3. **快照微同步执行**：`AE967C70 → 6262F444`（75 路径 / 119 schemas / LF 无尾换行 2 空格缩进）；与源 diff 复核 = **12 项**（10 脱敏占位符 + 2 治理修正，见 §4 构成）。
4. **敏感扫描**：零 hex-token（32-64 位）残留、零 IP、URL 全部 example.com / localhost 占位；JSON 语法与格式校验通过。

## 4. 快照微同步登记

| 项 | before | after |
| --- | --- | --- |
| sourceCommit | `8649eba`（配套实施，CoderClub PR #16） | `90a1e96`（`90a1e966…`，list 实施，CoderClub PR #17 → main `8617d9de`） |
| sourceSha256（LF） | `BF59FECD…` | `24DC841402BB5E063758A4156FC3AAF8D84609845BC218D92D0DC8FE6C7DD82A` |
| snapshotSha256 | `AE967C70FBF0CA69085D2429CB586B0A3C83BDAB9FB9F28D7A5A8B01F17E4F68` | `6262F44477A1A6887668F3514B506D6874EDCC645516D471131A2D2A3A2CB439` |
| pathCount / operationCount | 74 / 74 | **75 / 75** |
| semanticDifferenceCount | 11 | **12** |

**构成更新说明**：新 12 项 = 10 脱敏占位符（8 路径例子 + 2 schema 例子 TokenInfo/LoginResponse，不变）+ 1 项 `IdentifierUserItem` 类级 description 治理修正（快照侧保留「展示信息与 auth_user 主键 id」，源侧措辞留待后续实现轮）+ **1 项新增** `info.description` 计数治理修正（源侧登记 75 路径但计数仍写「74 个路径」，快照侧修正为「75 个路径」，源侧计数措辞随下次实现轮顺带修正——B-Impl 回执 §2.6 已声明此约定）。list 端点新增内容随源采纳，不构成快照-源差异。

## 5. 小瑕疵登记（不阻塞，按治理惯例）

| 项 | 说明 |
| --- | --- |
| `receiptCommitSha` 空串 | 回执 summary 漏填回执提交 SHA（B-Impl 历史同类问题，交接文件 §4 先例：不阻塞、登记即可）；实际回执提交 = `028bcbc` |
| `contractSnapshotSha256` 误记 | 回执 summary 记 `DAAEECB7`（任务书派发时值），实际验收基线快照为 `AE967C70`；不影响本批微同步（以本验收 §4 登记为准） |

## 6. 延后项承接（打包登记，不阻塞）

| # | 项 | 处置 |
| --- | --- | --- |
| 1 | L2 排序 SQL（type ASC + id ASC）无自动化锚定（Minor） | 只读确定性 SQL、契约测试顺序断言已覆盖，接受延后 |
| 2 | 风格小项（内联 stream、FQN 签名等，Minor） | 与既有风格一致度可接受，延后 |
| 3 | openapi 200 示例 `createdTime: null` 与 non_null 序列化省略的表述偏差（Minor） | 表述性，description 已注明；前端管理页按空值展示 |
| 4 | 规格措辞缺陷报告（§1.5 ALTER 语义） | 已修复；采纳 B-Review 建议：后续 schema 文档同步任务明确「ALTER 语义转写为列定义（行序表达位置）+ 注释登记实际执行的 ALTER」口径 |

## 7. 后续

1. **F-Impl 第二批（管理端敏感词管理页）**：按用户指示**暂缓**派发；快照 `6262F444`（75 路径）已就绪，list id 可发现性闭环，待排期下发。
2. **fromId 提案（PR #111）**：F-Impl 已消费（临时兜底 + 后端 400 兜底，无硬阻塞），PM 评审结论另记（见 `pm/reviews/2026-08-30/moment-item-fromid-decision.md` 或本批汇报）。
3. **阶段三收尾**：F-Impl 第一批回执（PR #112 已合入 main）待 F-Review 签署后 PM 验收 → state 推进 `gate3-a8-phase3-*`。
4. 阶段三整体收尾后进入阶段四（interview）评估与 A9 发布门禁（待用户授权）。

---

验收人：协调 PM，2026-08-30
