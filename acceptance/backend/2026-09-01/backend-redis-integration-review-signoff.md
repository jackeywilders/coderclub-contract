# REDIS-INTEGRATION Redis 读写加速实施——后端评审复核签署

> 角色：后端评审（B-Review）
> 签署日期：2026-09-01
> 任务书：`pm/requirements/2026-08-31/redis-integration-task.md`
> 回执：`handoff/backend-to-frontend/2026-09-01/backend-redis-integration-report.md` + `-summary.json`（PR #156，receiptCommitSha `b029d96`）
> 工作底稿：`designs/backend/2026-09-01/backend-redis-integration-review-workpaper.md`
> 审查方式：按 `/chinese-code-review` 技能流程（分级标注）
> 状态：**签署通过，转 PM 验收**

## 1. 复核结论

✅ **复核通过，签署本回执。** 实施 `c82983c`（CoderClub PR #23，15 commits）经人链核验 + Code Review + 独立复验与任务书/规格相符：

- [x] **S1 common Redis 基建**：`RedisKeyPrefixes`/`RedisUtil`/`RedisLockUtil`/`TransactionBoundRunner`/`RedisConfig`（Redisson 3.44.0 程序化装配 + **双 @Lazy 懒装配**，无 Redis 环境不建连）
- [x] **S2 缓存层**：Caffeine 三处全覆盖（circle 圈树 + subject 分类树 + 题目详情，30s TTL + 写路径 @CacheEvict）；未读 `counter:unread`（afterCommit INCR / 实际影响行数 DECR / miss 回填 / decrByMinZero）；reply `counter:reply`（批量 mGet + miss setIfAbsent 回填）；词库 Redis 数据源 + pub/sub 失效（**FIX-C1 防环路 + FIX-C2 强制 DB 重载**）；subject_liked 仅预留

- [x] **S3 排行** `rank:practice` zset：submit afterCommit +1；**giveUp 仅已交卷回减 -1（I-1）**；rankList 读 zset（score>0 过滤）+ 空/miss DB 全量重建
- [x] **S5 质量门禁**：34 模块 674 用例全绿 + `RedisInfraContextTest` 无 Redis PASS + 云端两次 FLUSHDB 联调全 PASS
- [x] **独立复验（本会话实跑，附着 `c82983c`）**：全量 `mvn install -DskipTests` + `mvn test` **exit 0**
- [x] **CI 双绿**：run 33457691813（GitHub API 逐 job 核实）
- [x] **契约不变**：openapi 75→75 零变更（源 SHA `ADCCD073` 前后一致）；接口语义不变（仅后端实现切换）；表不简化（Q9 DB 兜底保留）

## 2. Code Review 意见（chinese-code-review 分级，随签登记）

**无 [必须修复]。** 发现项：

| 级别 | 项 | 处置 |
| --- | --- | --- |
| [建议修改] | `unreadCount` miss 回填用 `set`（无条件覆盖）与 reply 读侧 `setIfAbsent` 不对称——回填窗口可能覆盖并发 INCR（新消息）增量 | **不阻塞本批**（回执 openFinding 6 同类竞态已登记为 spec-inherent、最终一致）；建议下个迭代批次统一为 `setIfAbsent` 与 reply 同构 |
| [仅供参考] | unread 脏数据 catch 不删脏 key（每次解析失败）；`auto-start` 未文档化；Redisson 懒连接取舍；实机锁待 interview 验证；decrByMinZero 并发窗口 | 均已登记（回执开放项/本底稿 §4），可选/接受 |

## 3. 规则 9 完成通知四字段（自检）

| 字段 | 值 |
| --- | --- |
| 实施提交 SHA | `c82983c`（`c82983c139ef2f6298025236257cd404fe1e6001`，15 commits） |
| 回执提交 SHA | `b029d96`（交接仓库 PR #156 回执提交，已合入 main） |
| PR 号 | CoderClub PR #23——**已合入 main（merge `9eda4ec3`，2026-09-01，B-Review 复核 + Code Review 通过后执行授权合入）** |
| R2 状态 | **实施 R2 达成**（已合入 CoderClub main，main tip 核验 `9eda4ec3`）；本签署随交接仓库流程合入 main |

## 4. 延后项与观察项（打包转 PM 验收，不阻塞）

| # | 项 | 处置标注 |
| --- | --- | --- |
| 1 | subject_liked 仅预留（key 约定留档） | 待点赞任务按 R1 落地 |
| 2 | 排行同分排序差异（zset 字典序 vs SQL 不定序） | 行为可接受，登记 |
| 3 | 题目详情 30s 缓存窗口 | 任务书裁定容忍 |
| 4 | Redisson 懒连接装配错误延迟 | 固有取舍，登记 |
| 5 | 真实取锁未实机触发 | interview 任务 S4 实机验证 |
| 6 | unread/reply miss 回填并发窄竞态（含本批 [建议修改] unread set→setIfAbsent 统一） | 下个迭代批次统一，登记 |
| 7 | INCR/DECR 与 DB 非原子 | 任务书双保险语义（最终一致），接受 |
| 8 | 词库回填失败陈旧快照 + `auto-start` 配置未文档化 | 登记，建议后续补文档注记 |

## 5. 关联

- 任务书 · grill/brainstorming 共识 · 回执 PR #156 · 实施 CoderClub PR #23（merged `9eda4ec3`）
- 后续：PM 验收 → 快照微同步（本批零变更，interview 端点批次一并）→ interview 任务（S4 Redis 锁/前缀复用 + 实机验证）→ subject_liked 点赞任务

签署：后端评审（B-Review），2026-09-01