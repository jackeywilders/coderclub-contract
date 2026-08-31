# MessageVO 补 isRead（MESSAGEVO-ISREAD-D2）——PM 验收

> 验收角色：协调 PM
> 验收日期：2026-08-31
> 回执：`handoff/backend-to-frontend/2026-08-31/backend-message-isread-report.md` + `-summary.json`（PR #148，`receiptCommitSha=bd960b6`，已合入 main）
> 复核签署：`acceptance/backend/2026-08-31/backend-message-isread-review-signoff.md`（PR #151，merged，MCP 核验）
> 状态：**验收通过**

## 1. 验收结论

✅ **MESSAGEVO-ISREAD-D2 验收通过。** 实施 `f6c23a0`（经 CoderClub PR #21 合入 main `72d12dd3`）经 B-Review 复核签署（PR #151）与 PM 独立核验，与提案 `proposals/backend/2026-08-31/messagevo-isread-item-proposal.md`（PR #136）及 PM 决策（PR #135 + 确认决策）相符；快照微同步随本验收执行（`MessageVO.isRead` 采纳，75 路径不变）。

## 2. 规则 9 核验链（四字段）

| 字段 | 值 |
| --- | --- |
| 实施提交 SHA | `f6c23a0`（6 commits：`MessageIsReadEnum` @JsonValue + BO/VO 透传 + 判别断言 + InOrder 时序加固） |
| 合并提交 SHA | `72d12dd3`（CoderClub PR #21 merge，2026-08-31T16:27:48Z） |
| 回执提交 SHA | `bd960b6`（PR #148，已合入 main） |
| PR 号 | CoderClub #21（merged `72d12dd3`）；交接仓库回执 #148、签署 #151（merged） |
| R2 状态 | ✅ 双达成 |

## 3. PM 独立复核（非签署转录）

1. **源契约实测（远端 main）**：`docs/api/coderclub-openapi.json` LF SHA-256 = `57C2D6EE12D071CD6799718D7F772DAE10587C5FD7B876443CDAB06CF29E91D4`（gh API 拉取复算一致）；75 路径 / 119 schemas；`MessageVO.isRead`（int32，description 注明读取时点语义，example 2）。
2. **实现语义相符**：`MessageIsReadEnum`（READ(1)/UNREAD(2)，`@JsonValue` 数字序列化 + `of()` null 安全）；BO/VO 透传**组装先于 `markReadByIds`**（读取时点/置读前原值，置读时机零改动）——与 D2 提案 Q1-Q4 共识完全吻合；判别断言（isRead=2 数字）+ InOrder 时序用例。
3. **快照微同步执行**：`74417DD8 → ADCCD073`（75 路径 / 119 schemas / LF 无尾换行 2 空格缩进）；与源 diff 复核 = **12 项**（10 脱敏 + 2 治理修正，构成不变）；`MessageVO.isRead` 随源采纳，不构成快照-源差异。
4. **敏感扫描**：零 hex-token / 零 IP；URL 全部 example.com / localhost；JSON 语法与格式校验通过。

## 4. 快照微同步登记

| 项 | before | after |
| --- | --- | --- |
| sourceCommit | `1fbf0ad`（fromId 实施） | `f6c23a0`（D2 实施，CoderClub PR #21 → main `72d12dd3`） |
| sourceSha256（LF） | `26AEC009…` | `57C2D6EE12D071CD6799718D7F772DAE10587C5FD7B876443CDAB06CF29E91D4` |
| snapshotSha256 | `74417DD8…` | `ADCCD073E0117CA017846157A84E0FA1603D44BC6E05593CA1F256755967B0A7` |
| pathCount / operationCount | 75 / 75 | **75 / 75**（isRead 字段级采纳，路径数不变） |
| semanticDifferenceCount | 12 | **12**（构成不变：10 脱敏 + IdentifierUserItem description + info.description 路径计数） |

## 5. 小瑕疵/观察项登记（不阻塞）

| 项 | 说明 |
| --- | --- |
| summary `contractSnapshotSha256` 空串 | 快照微同步在 PM 验收批次执行（本批已落地，回填即可） |
| `MessageIsReadEnum.of()` 越界值映射 UNREAD | 延后观察（DB 域 1/2，约定在 javadoc） |
| sibling 测试 bare verify | 时序契约由本批 InOrder 用例覆盖（观察项） |

## 6. 后续

1. **F-Impl 消息页条目渲染**（未读高亮/圆点）：第四批衔接（消费 `isRead`，`MessageVO` 类型补字段）。
2. 第二批其余三线（subject-search/redis/r2）并行推进。
3. 阶段四快照微同步批次：interview 端点（75→83）后续合并执行。

---

验收人：协调 PM，2026-08-31
