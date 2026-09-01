# REDIS-INTEGRATION Redis 读写加速实施——后端评审复核工作底稿（含 Code Review）

> 角色：后端评审（B-Review）
> 日期：2026-09-01
> 任务书：`pm/requirements/2026-08-31/redis-integration-task.md`；grill 共识（Q8 全面 Redis 化 + Q9 表保留持久兜底）+ brainstorming 确认（A1/L2/R1/Caffeine 覆盖/giveUp 语义）
> 回执：`handoff/backend-to-frontend/2026-09-01/backend-redis-integration-report.md` + `-summary.json`（PR #156，receiptCommitSha=`b029d96`）
> 实施：CoderClub PR #23（head `c82983c`，15 commits；**本会话复核 + Code Review 通过后已合入 main `9eda4ec3`，R2 达成**）
> 审查方式：按 `/chinese-code-review` 技能流程（分级标注 [必须修复]/[建议修改]/[仅供参考]/[问题]）

## 1. 人链核验：实施提交存在性与一致性

| 项 | 证据 | 结果 |
| --- | --- | --- |
| 提交对象 | `git cat-file -t c82983c` 成功（走 7892 代理 fetch `feat/backend-redis-integration`）；远端 PR #23 head 与本地对象一致 | ✅ |
| CI | PR #23 head `c82983c`：build-and-test ✅（job 99701059781，run 33457691813）+ sensitive-scan ✅（job 99701059476）——GitHub API 逐 job 核实 | ✅ |
| 提交数 | **15 commits**（spec + plan + S1 基建×2 + S2 缓存/未读/reply/词库×3 + S3 排行×2 + 装配测试 + FIX-C2 联调修复）——与回执一致 | ✅ |
| summary 一致性 | `implementationCommitSha=c82983c`、`receiptCommitSha=b029d96`、PR #23、openapi 75→75（ADCCD073 前后一致） | ✅ |
| PR #23 合入 | 本会话独立复核（CI 双绿 + 代码级 Code Review + 本地全量测试复验全过）后以 merge 方式合入 main（merge `9eda4ec3`，B-Review 授权合入人身份）——**R2 达成**（main tip 核验 `9eda4ec3`） | ✅ |

## 2. 代码级 Code Review（逐文件，附着 `c82983c`）

### 2.1 common Redis 基建

| 文件 | 核对项 | 结果 |
| --- | --- | --- |
| `RedisConfig` | 程序化 `RedissonClient`（绕开 redisson-starter 与 Spring Boot 4 兼容面）；**双 @Lazy 懒装配**（Bean + 注入侧）无 Redis 环境不建连；destroyMethod=shutdown | ✅ |
| `RedisUtil` | StringRedisTemplate 门面：计数/incrBy/decrByMinZero（clamp ≥0）/JSON/mGet/zset/pub-sub；`decrByMinZero` 用后读回修正防负展示 | ✅ |
| `RedisLockUtil` | RLock 统一 `lock:` 前缀；tryLock 中断恢复 interrupt 标志；executeWithLock finally 释放（isHeldByCurrentThread 检查配对） | ✅ |
| `TransactionBoundRunner` | 事务提交后回调（防回滚虚增）；无事务立即执行 | ✅ |
| `RedisKeyPrefixes` | `cache:`/`counter:`/`rank:`/`lock:`/`interview:` 统一前缀 | ✅ |

### 2.2 circle 业务接入

| 文件 | 核对项 | 结果 |
| --- | --- | --- |
| `ShareMessageDomainServiceImpl`（未读数） | unreadCount Redis 优先 + miss DB 回填写穿（不设 TTL，脏数据回退 DB）；saveMessage 落库成功 afterCommit INCR（自评/自回复早退不 INCR）；page 置读按 `markReadByIds` **实际影响行数** afterCommit DECR（affected=0 不递减）+ decrByMinZero 下限 0 | ✅ |
| `ShareCommentDomainServiceImpl`（reply 写） | save 落库 + DB 计数 +1 后 afterCommit INCR；remove 按实际回减数 afterCommit decrByMinZero；DB 兜底（Q9） | ✅ |
| `ShareMomentDomainServiceImpl`（reply 读） | page 批量 `mGet` 一次取回；命中覆盖、**miss 实体表列值 `setIfAbsent` 回填**（防覆盖并发 INCR）；脏数据保留实体值 | ✅ |
| `SensitiveWordDomainServiceImpl`（词库） | `cache:sensitive-words` Redis 数据源（load 内存→Redis miss→DB 回填，异常降级 DB 仅告警）；save/remove 后 `rebuild()` **强制 DB 全量重载先入 Redis 再发布失效通知**（FIX-C2）；监听端 `reloadLocal()` 仅本地重建不发布（FIX-C1 防环路）；发布先回填后通知顺序正确 | ✅ |
| `SensitiveWordInvalidateConfig` | 独立 listener container；`auto-start` 开关（无 Redis 环境置 false 防启动即连）；监听回调捕获异常不中断容器 | ✅ |

### 2.3 practice / subject

| 文件 | 核对项 | 结果 |
| --- | --- | --- |
| `PracticeDetailDomainServiceImpl`（rank zset） | submit 交卷 afterCommit ZINCRBY +1；**giveUp 仅 complete_status=1 已交卷才回减 -1**（I-1：草稿从未计入 SQL 榜单不回减）；rankList 读 zset（score>0 过滤不留负分）+ zset 空/miss → DB `countAllGroupByCreatedBy` 全量 ZADD 重建；昵称组装仍 Feign 行为不变 | ✅ |
| subject 缓存 | `subject:category:tree`（3 处 @CacheEvict + @Cacheable）、`subject:info`（@Cacheable key=#bo.id + add/update/delete @CacheEvict）；`spring.cache.type=caffeine` + `spec=expireAfterWrite=30s` + @EnableCaching | ✅ |
| 装配测试 | `RedisInfraContextTest`（circle/practice）：Nacos disabled、druid 0 连接、pubsub auto-start=false、Redisson @Lazy 代理不建连——无 Redis 环境 PASS | ✅ |

## 3. 独立复验（本底稿复核时执行，附着 `c82983c`）

采用 `git archive` 提取实施快照至隔离目录（不动主工作区），实跑：

| 命令/动作 | 结果 |
| --- | --- |
| 全量 `mvn install -DskipTests -q` + `mvn test` | **exit 0，BUILD 全绿**（34 模块 674 用例，与回执一致） |
| openapi | 零变更（PR 文件清单无 openapi；源 SHA `ADCCD073` 前后一致） |

## 4. Code Review 意见（分级标注）

| 级别 | 项 | 说明 | 处置 |
| --- | --- | --- | --- |
| [建议修改] | **`unreadCount` miss 回填用 `set`（无条件覆盖）与 reply 读侧 `setIfAbsent` 不对称** | `ShareMessageDomainServiceImpl.unreadCount` 回填用 `redisUtil.set`；`ShareMomentDomainServiceImpl` reply miss 用 `setIfAbsent`。窗口：缓存 miss 回填覆盖期间并发 INCR（新消息）增量被丢。回执 openFinding 6 已同类登记（spec-inherent 最终一致），但 reply 侧已示范更稳做法 | 不阻塞本批；建议下个迭代批次统一为 `setIfAbsent`，与 reply 侧同构 |
| [仅供参考] | `unreadCount` 脏数据 catch 不删脏 key | NumberFormatException 回退 DB 后 key 保留，每次解析失败；可顺手 `delete` | 边缘场景，可选 |
| [仅供参考] | `circle.sensitive-word.pubsub.auto-start` 未在 application.yaml 文档化 | 回执 openFinding 9 已登记；建议补 Nacos/配置注记 | 已登记，可选 |
| [仅供参考] | Redisson @Lazy 装配错误延迟到首次取锁 | 回执开放项 4 已登记（启动快速失败 → 运行时首取锁失败取舍） | 固有取舍，接受 |
| [仅供参考] | `RedisLockUtil` 真实取锁未实机触发（leaseMs 语义待 interview 验证） | 回执开放项 5；interview 任务 S4 防重锁将实机验证 | 接受 |
| [仅供参考] | `decrByMinZero` 并发窗口（DECR 读回负值 set 0 可能误清并发 INCR） | 回执开放项 7 已登记（INCR/DECR 与 DB 非原子，最终一致下次写收敛） | 接受 |

**无 [必须修复]。** 整体评价：设计严谨、实现质量高——afterCommit 防回滚虚增、按实际影响行数 ±、reply miss 回填 setIfAbsent、FIX-C1 防消息环路、FIX-C2 强制 DB 重载、I-1 回减语义、Redisson 双懒装配、无 Redis 装配测试，均与本批规格/grill 共识一致。

## 5. 延后项核查（回执 openFindings 8 项，均不阻塞）

subject_liked 仅预留（key 约定留档待点赞任务）；排行同分排序差异（可接受）；题目详情 30s 缓存窗口（任务书裁定容忍）；Redisson 懒连接取舍；实机锁未触发（interview 承接）；miss 回填窄竞态；INCR/DECR 与 DB 非原子（最终一致）；回填失败陈旧快照 + auto-start 未文档化（openFinding 9）——全部登记，接受。

## 6. 复核结论

**通过，签署。** 回执声明（15 提交、S1-S5、34 模块 674 用例、云端两次 FLUSHDB 联调 PASS、FIX-C1/C2/I-1、openapi 零变更）与人链核验、Code Review 实读、本地全量测试复验逐项一致；PR #23 已按授权合入 main（`9eda4ec3`），R2 达成。无 [必须修复]；[建议修改] 1 项（unread 回填 setIfAbsent 统一）不阻塞，随下个批次。

## 7. 关联

- 任务书 · grill/brainstorming 共识 · 回执 PR #156（receiptCommitSha `b029d96`）· 实施 CoderClub PR #23（merged `9eda4ec3`）
- 后续：PM 验收 → 快照微同步（本批 openapi 零变更；如合并 interview 端点批次则一并）→ interview 任务（S4 会话 Redis 复用锁/前缀 + 词库缓存，实机验证锁）→ subject_liked 点赞任务（R1 落地）