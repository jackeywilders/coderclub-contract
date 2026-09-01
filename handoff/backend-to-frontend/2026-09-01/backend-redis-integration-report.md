# 回执：Redis 读写加速实施（B-Impl，②线）

> **回执角色：** 后端实现（B-Impl）
> **日期：** 2026-09-01（Asia/Shanghai）
> **任务书：** `pm/requirements/2026-08-31/redis-integration-task.md`（第二批四线之二）
> **决策依据：** grill 共识（2026-08-31，Q8 全面 Redis 化 + Q9 表保留持久兜底——Redis 作加速层、清空可重建）+ brainstorming 逐项确认（A1 common 共享 / L2 Redisson 锁 / R1 读 Redis+写穿+miss 回填 / Caffeine 三处全覆盖 / subject_liked 仅预留）
> **设计/计划：** 后端仓库 `docs/superpowers/specs/2026-08-31-redis-integration-design.md`（545a9c0）、`docs/superpowers/plans/2026-08-31-redis-integration.md`（56b76f2，随本 PR 合入）

## 1. 来源与提交哈希

| 项 | 值 |
| --- | --- |
| 实现仓库 | jackeywilders/coderclub（后端） |
| 分支 | `feat/backend-redis-integration`（基于 `dc0dd28`） |
| 实现头 | `c82983c`（15 提交：spec + plan + S1 基建×2 + S2.1 缓存 + S2.2 未读 + S2.3 reply + S2.5 词库×3（含 FIX-C1/C2）+ S3 排行×2（含 I-1）+ 装配测试 + FIX-C2 联调修复） |
| PR | **#23**（feat/backend-redis-integration → main） |
| CI | build-and-test + sensitive-scan（head `c82983c`，run 33457691813 双绿，核验后转人工合入） |
| 合入状态 | **R1 达成**；R2 待人工合入（用户/B-Review 在 CI 全绿后执行） |

## 2. 任务明细（对照任务书 S1-S5）

1. **S1 共享 Redis 基建** ✅：BOM 增 `org.redisson:redisson:3.44.0`；common 增 data-redis/redisson/fastjson2；`RedisKeyPrefixes`（`cache:`/`counter:`/`rank:`/`lock:`/`interview:` 统一前缀）、`RedisUtil`（StringRedisTemplate 门面：计数/decByMinZero/zset/JSON/mGet/pub-sub）、`RedisLockUtil`（Redisson RLock，统一 `lock:` 前缀，tryLock/executeWithLock）、`TransactionBoundRunner`（事务提交后回调，防回滚虚增）、`RedisConfig`（程序化 `RedissonClient`——**双 @Lazy 懒装配**：无 Redis 环境启动不建连，规避 Spring Boot 4 与 redisson-starter 兼容风险）。
2. **S2.1 纯读 Caffeine 三处全覆盖** ✅：circle 圈子树（保留 `@Cacheable circle:tree`）+ subject 分类树（新增 `subject:category:tree` 30s）+ subject 单题详情（新增 `subject:info` key=id 30s；add/update/delete 路径 `@CacheEvict(allEntries)`）；`getSubjectPage` 分页列表不缓存（命中率低防放大）。
3. **S2.2 未读数** ✅：`counter:unread:{toId}`——saveMessage 落库成功 afterCommit INCR（自评/自回复不 INCR）；unreadCount Redis 读优先、miss → DB `countUnread` 回填（不设 TTL）；page 置读按 `markReadByIds` 实际影响行数 afterCommit `decrByMinZero`（isRead=1 过滤页 affected=0 不减；多次分页自然归零非暴力清零）；表 `is_read` 兜底。
4. **S2.3 reply_count** ✅：`counter:reply:{momentId}`——评论 save/remove 保留 DB 原子增减后 afterCommit Redis ±（remove 按实际受影响行数）；page 批量一次 `mGet` 覆盖 `replyCount`（miss 用实体表列值 `setIfAbsent` 回填）；表列兜底（Q9）。
5. **S2.4 subject_liked** ⏸️ **仅预留**：点赞子系统未实现（无端点/契约，前端亦延后），本任务交付 key 约定（`counter:like:{subjectId}`、`cache:like-state:{userId}:{subjectId}`）与基建，**openFinding 登记**待点赞任务按 R1 落地。
6. **S2.5 词库 DFA** ✅：Redis 数据源 `cache:sensitive-words`（无 TTL 显式失效）；load 链 内存→Redis miss→DB 回填；pub/sub 失效（`sensitive-words:invalidate` 频道，listener 回调 `reloadLocal` 仅本地重建**不发布**——FIX-C1 防消息环路）；**rebuild 强制 DB 重载**（FIX-C2——运行期发现 load() Redis hit 优先致 DB 变更不入 context，联调修复）。
7. **S3 排行** ✅：`rank:practice` zset——submit 交卷 afterCommit `ZINCRBY +1`；giveUp **仅已交卷**（complete_status=1）回减 -1（I-1 人类裁定：草稿从未计入不回减）；rankList 读 zset（`score>0` 过滤对齐 SQL is_deleted）+ zset 空/miss → DB `countAllGroupByCreatedBy`（新增无 LIMIT mapper）全量 ZADD 重建；`practice_info` 表兜底。
8. **S4 会话** ⏸️ 不实现：interview 任务书 S5 承接（会话 TTL 2h + 词库缓存 + 防重锁）；本任务交付 `interview:` 前缀 + `RedisLockUtil` 供其复用。
9. **S5 质量门禁** ✅：common（RedisUtil/RedisLockUtil/TransactionBoundRunner/前缀）+ circle（未读/reply/词库）+ subject（缓存注解命中/失效）+ practice（排行 zset 写读/重建/giveUp）单测全绿；装配测试 `RedisInfraContextTest`（circle/practice 无 Redis PASS）；**云端联调（两次 FLUSHDB）写路径 + miss 回填 + 重建 + giveUp 回减 + 词库双向全部 PASS**；全仓 mvn + CI 双绿。

## 3. 测试证据

- 全仓 `mvn install -DskipTests -q` EXIT=0；`mvn test` 34 模块 **674 用例全绿**（0 Failures/0 Errors，含两个新装配测试与既有 Circle/Practice/Gateway context 测试）。
- 审查链：brainstorming（A1/L2/R1 + Caffeine 三处全覆盖修订 + subject_liked 预留 + giveUp 回减语义）→ SDD 执行（Task1-8 子代理 + 任务审查，修复波：FIX-C1 消息环路 + FIX-I1 load 降级 + I-1 giveUp 回减 + FIX-C2 词库写路径）→ 定向复审全部 ADDRESSED。
- 联调（云端 Redis 8.8.1，Nacos 下发配置；两次 FLUSHDB）：未读写/未读 miss 回填/reply 写/reply miss 回填/排行写/排行重建/giveUp 回减/词库双向 全部 PASS（验证矩阵见实现 PR 描述与 task-8 联调记录）。

## 4. 边界遵守声明（任务书 §2）

- 表不简化（Q9）：未读/回复数/排行仍落库持久，Redis 仅加速；接口语义不变（计数/排行响应不变，仅后端实现切换）；openapi/`status/` 未改（快照微同步由 PM 验收批次执行）。
- Redis key 统一前缀防冲突；规则 8 占位（key 无敏感值）；Conventional Commits；未改交接仓库治理文件/其他角色目录。
- 中间件配置仅经 Nacos 拉取（本机无 Redis 凭据落盘）；联调 FLUSHDB 由用户在授信环境执行。

## 5. 已知限制与延后项（openFindings）

1. **subject_liked 仅预留**（S2.4 裁定）：点赞子系统未实现（DDL 表 + uniq_like 唯一索引已就绪），key 约定留档，待点赞任务按 R1 模式落地。
2. **排行同分排序差异**：zset 同分按 member 字典序 vs SQL group-by desc 同分不定序——行为可接受，登记。
3. **题目详情缓存 30s 窗口**：答案修正后旧值短暂可见（任务书已裁定"可容忍本地副本"）。
4. **Redisson 程序化装配**：绕开 redisson-spring-boot-starter 与 Spring Boot 4 兼容面；懒连接使装配错误从启动快速失败变为首次取锁运行时失败（固有取舍）。
5. **真实取锁未实机触发**：`RedisLockUtil` 逻辑单测覆盖；本任务无业务端点触发（锁为 rebuild/interview 预留），实机验证待 interview 任务（S4 会话防重锁）触发。
6. **miss 回填×并发 DECR 窄竞态**（未读/reply）：setIfAbsent 防覆盖新 INCR，Redis 短暂偏离 DB 至下次写收敛——spec 设计固有取舍。
7. **INCR/DECR 与 DB 非原子并发窗口**：计数加速层与表兜底最终一致（任务书 Q9 双保险语义）。
8. **敏感词回填失败时他实例暂持旧快照**：最终一致窗口（设计内）；幂等 save 仍全量 DB 读（性能观察，无动作项）。
9. **新配置项 `circle.sensitive-word.pubsub.auto-start`**（默认 true）未入 application.yaml 文档（仅代码 @Value 默认值 + 测试属性覆盖）——建议补 Nacos/文档说明。

## 6. 后续链

1. B-Review 复核签署 → PM 验收 → **快照微同步**（本批 openapi 无变更 75→75，路径数维持；如 PM 有合并 interview 端点批次则一并）。
2. 合入提醒：PR #23 CI 双绿（run 33457691813），**合入由人工（用户/B-Review）在 GitHub 执行**。
3. 同批衔接：r2-backup（四线之三，待推进）；interview 后端/前端（同批三线，其 S5 会话复用本任务 `interview:` 前缀 + 锁）。
4. 联调遗留：临时账号 itgr_tmp_b/itgr_tmp_c 与联调动态/练习数据保留云端开发库（可清理）；FLUSHDB 后各路径自愈已验证。

---
- 回执角色：后端实现（B-Impl），2026-09-01
