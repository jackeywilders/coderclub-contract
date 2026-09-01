# Redis 读写加速（REDIS-INTEGRATION，②线）——PM 验收

> 验收角色：协调 PM
> 验收日期：2026-09-01
> 回执：`handoff/backend-to-frontend/2026-09-01/backend-redis-integration-report.md` + `-summary.json`（PR #156，`receiptCommitSha=b029d96`，已合入 main）
> 复核签署：`acceptance/backend/2026-09-01/backend-redis-integration-review-signoff.md` + 工作底稿 `designs/backend/2026-09-01/backend-redis-integration-review-workpaper.md`（PR #157，merged，MCP 核验；含 chinese-code-review 分级意见）
> 状态：**验收通过**

## 1. 验收结论

✅ **REDIS-INTEGRATION 验收通过。** 实施 `c82983c`（15 commits，经 CoderClub PR #23 合入 main `9eda4ec3`）经 B-Review 复核签署（PR #157，Code Review：无 [必须修复]）与 PM 独立核验，与任务书 `pm/requirements/2026-08-31/redis-integration-task.md`（grill/brainstorming 共识）相符——common Redis 基建（Redisson 双 @Lazy 懒装配）、Caffeine 三处全覆盖、未读/reply 计数（miss 回填）、词库 Redis 源 + pub/sub 失效（FIX-C1 防环路 + FIX-C2 强制 DB 重载）、排行 `rank:practice` zset（giveUp 仅已交卷回减 I-1）。**本批快照零变更**（openapi 75→75，内部实现切换无新端点）；interview S4 会话不实现（前缀+锁预留，随 interview 任务承接）。

## 2. 规则 9 核验链（四字段）

| 字段 | 值 |
| --- | --- |
| 实施提交 SHA | `c82983c`（`c82983c139ef2f6298025236257cd404fe1e6001`，15 commits） |
| 合并提交 SHA | `9eda4ec3`（CoderClub PR #23 merge，2026-09-01T01:42:27Z，合并人 JackeyWilder） |
| 回执提交 SHA | `b029d96`（PR #156，merge `60bba5c`，已合入 main） |
| PR 号 | CoderClub #23（merged `9eda4ec3`）；交接仓库回执 #156、签署 #157（均 merged） |
| R2 状态 | ✅ 双达成：实施合入 CoderClub main（`9eda4ec3`）；回执/签署均合入交接仓库 main |
| CI | run `33457691813` 双绿：build-and-test（job 99701059781 success）+ sensitive-scan（job 99701059476 success） |

## 3. PM 独立复核（非签署转录）

1. **实施 R2 实测（远端 main）**：CoderClub PR #23 已合入 main（merge `9eda4ec3`，合并人 JackeyWilder，01:42:27Z）；CI 双绿逐 job 核验（run 33457691813）；PR 38 files 变更（common/circle/subject/practice + 测试），openapi 文件未涉及——openapi 零变更确认。
2. **签署链实测**：交接仓库 PR #157 已合入 main（merge `63ae06a`，01:44:35Z）；signoff + workpaper 双文件落库（`acceptance/backend/2026-09-01/` + `designs/backend/2026-09-01/`）；回执双轨已在 main（PR #156 merge `60bba5c`，`receiptCommitSha=b029d96`）。
3. **源契约实测（远端 main）**：`docs/api/coderclub-openapi.json` LF SHA-256 = `57C2D6EE12D071CD6799718D7F772DAE10587C5FD7B876443CDAB06CF29E91D4`（复算一致）；75 路径 / 119 schemas——**本批源文档零变更**。
4. **快照处理（零变更）**：快照保持 `ADCCD073`（75 路径 / 119 schemas / LF 无尾换行 2 空格缩进），与源 diff = **12 项**（10 脱敏 + 2 治理修正，构成不变）；本批无端点登记，快照微同步与 interview 端点批次合并执行时一并复核（无挂起端点项）。
5. **PM 注记（记账偏差，不阻塞）**：回执与签署将 `sourceDoc`/源 SHA 记为 `ADCCD073`（实为**快照 SHA**），源文档实测 `57C2D6EE`；openapi 零变更属实，验收按当前源复核，无需 B-Impl 补正。
6. **敏感扫描**：快照未变沿用 ADCCD073 既有合规状态；回执/签署全文无真实 IP/凭据（规则 8 占位合规）。

## 4. 快照微同步登记（本批零变更）

| 项 | before | after |
| --- | --- | --- |
| sourceCommit | `f6c23a04e96` | `f6c23a04e96`（本批源文档零变更；backendCommit 追踪 `9eda4ec3`） |
| sourceSha256（LF） | `57C2D6EE…` | `57C2D6EE…`（不变） |
| snapshotSha256 | `ADCCD073…` | `ADCCD073…`（不变） |
| pathCount / operationCount | 75 / 75 | **75 / 75**（不变） |
| semanticDifferenceCount | 12 | **12**（构成不变） |

## 5. Code Review 意见与延后项登记（承接签署 §2/§4，均不阻塞）

| # | 项 | 级别/处置 |
| --- | --- | --- |
| 1 | `unreadCount` miss 回填 `set` 与 reply 侧 `setIfAbsent` 不对称（回填窗口可覆盖并发 INCR） | [建议修改]——下个迭代批次统一 `setIfAbsent` 与 reply 同构，登记 |
| 2 | subject_liked 仅预留（key 约定留档，DDL/唯一索引就绪） | 待点赞任务按 R1 落地 |
| 3 | 排行同分排序差异（zset 字典序 vs SQL 不定序） | 行为可接受，登记 |
| 4 | 题目详情 30s 缓存窗口（answer 编辑短暂旧值） | 任务书裁定容忍 |
| 5 | Redisson 懒连接装配错误延迟 | 固有取舍，登记 |
| 6 | 真实取锁未实机触发（仅 mock RLock 单测） | interview 任务 S4 实机验证 |
| 7 | unread/reply miss 回填并发窄竞态 | spec-inherent、最终一致，接受 |
| 8 | INCR/DECR 与 DB 非原子窗口 | 任务书双保险语义，接受 |
| 9 | 词库回填失败陈旧快照 + `circle.sensitive-word.pubsub.auto-start` 配置未文档化 | 登记，建议后续补文档注记 |

## 6. 后续

1. **快照微同步批次**：本批零变更；interview 端点批次（75→83 + rebuild）一并执行时复核。
2. **interview 任务（S4）**：复用本任务 `interview:` 前缀 + RedisLockUtil 锁；实机取锁验证随 interview 会话落地。
3. **subject_liked 点赞任务**：R1 落地（key 约定/DDL 已就绪）。
4. **unread 回填统一 `setIfAbsent`**：随下个迭代批次（[建议修改] 承接）。
5. 同批剩余：r2-backup（B-Impl 推进中），回执到位后走签署 → 验收。

---

验收人：协调 PM，2026-09-01
