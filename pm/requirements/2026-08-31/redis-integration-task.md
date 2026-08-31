# 任务书：Redis 读写加速实施（B-Impl）

> 派发角色：协调 PM
> 派发日期：2026-08-31
> 执行角色：后端实现（B-Impl）
> 决策依据：grill 共识（2026-08-31）——Q8 全面 Redis 化（缓存/计数/排行/会话/锁）+ Q9 **表保留持久兜底**（Redis 作加速层，清空可重建）+ Caffeine/Redis 分工确认（纯读缓存 Caffeine 保留/可选 Redis；一致性数据 Redis 必须）
> 现状核查（审查确认）：Redis 8.8.1（云端，host 占位 `<redis-host>`）**仅承载 sa-token 登录态**；circle 树 Caffeine 本地缓存；**业务代码无 RedisTemplate 直接使用**；practice 排行为 MySQL 聚合；敏感词 DFA 内存 Trie + save/remove rebuild
> 批次：阶段四配套（与 interview 后端/前端、subject 搜索升级、数据落地同批）

## 1. 任务明细

### S1 共享 Redis 基建
- 各服务 starter 统一 Redis 工具 Bean（`RedisTemplate`/`RedisUtil`，复用既有 `sa-token-redis-jackson` 连接；key 前缀约定如 `cache:` / `counter:` / `rank:` / `lock:` / `interview:`）。
- **锁封装**：`RedisLockUtil`（SETNX + TTL + 释放，或 Redisson 若引入）——供重建锁/防重锁复用。

### S2 缓存层（分工原则）
- **纯读且可容忍本地副本**（circle 圈子树、subject 分类树、题目详情）：**保留 Caffeine**（单实例更优）或按需 Redis 化（多实例一致）——任务书不强制替换，由实现按部署形态择一；若 Redis 化，key `cache:xxx` + TTL + 变更失效。
- **一致性数据（Redis 必须）**：
  - `share_message` 未读数：`counter:unread:{toId}` 计数（消息落库 + INCR；读取即已读归零），表 `is_read` 持久兜底。
  - `share_moment.reply_count`：Redis INCR/DECR + 定时/写时落库兜底（表列保留）。
  - `subject_liked` 点赞状态/计数：Redis + 落库兜底（`uniq_like` 唯一索引持久）。
- **词库 DFA 数据源**（敏感词 `sensitive_words`、interview `interview_keyword`）：Redis 存词库数据 + 变更失效（pub/sub 或 TTL 轮询）触发各实例 DFA 重建（`SensitiveWordDomainServiceImpl` rebuild 先例；interview 侧由 interview 任务书 S5 承接）。

### S3 排行（practice Redis zset）
- 交卷完成链路（`PracticeDetailDomainServiceImpl` submit，`complete_status=1`）`ZINCRBY rank:practice:{?} created_by 1`；查询 `ZREVRANGE` 对齐现 `countGroupByCreatedBy`（group by created_by count desc）语义；`practice_info` 表持久兜底（可全量重建）。

### S4 会话（interview 进行中）
- 由 interview 任务书 S5 承接（interviewId 会话 TTL 2h + 词库缓存 + 防重锁）——本任务书提供共享基建与锁封装。

### S5 质量门禁
- Redis 单测/集成测试（本地/云端 Redis 可用，地址按 nacos 配置下发、host 占位 `<redis-host>`）；全仓 mvn + CI 双绿；回执双轨（含 `receiptCommitSha`）+ 四字段。
- 验证：未读计数/排行/词库失效的 Redis 读写一致性断言；Redis 清空后从库重建路径可验证。

## 2. 约束

- **表不简化**（Q9）：计数/排行/未读仍落库持久，Redis 仅加速——双保险，Redis 清空不丢数据。
- 不触碰既有接口语义（计数/排行响应不变，仅后端实现切换）；Redis key 设计统一前缀防冲突。
- 不改 `api/` 快照与 `status/`；规则 8 占位符（Redis key 无敏感值）；Conventional Commits。

## 3. 关联

- grill 共识（Q8/Q9）· interview 任务书 S5（会话/词库缓存，衔接）· 数据落地任务书（同批）· 云端 Redis（已连接核查：仅 sa-token）
