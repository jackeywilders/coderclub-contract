# G1-04 Claude Code 后端执行报告

> **角色**：Claude Code 后端（执行实现 + 测试 + 真实 DB 复核）
> **任务来源**：`pm/requirements/2026-08-12/g1-04-claude-code-backend-task.md`（PM 批准）
> **复核角色**：Backend Codex（本报告供其独立复验后签署回执）
> **报告日期**：2026-08-13
> **契约影响**：无（不改变 HTTP 契约，未产生 `proposals/backend/`）

## 1. 来源与提交哈希

| 项目 | 值 |
| --- | --- |
| 来源项目 | `G:/Dev/backend/Club/CoderClub` |
| 来源分支 | `main` |
| 死代码清理提交 | `fad2312`（refactor(subject): 移除无调用者的 SubjectInfoService.page 死代码） |
| 启动脚本修复提交 | `7c3ac66`（fix(scripts): 启动脚本先安装再运行，避免引用过期 m2 jar） |
| 本回执提交哈希 | （Backend Codex 签署时填写） |
| 服务地址 | Auth `http://localhost:3100`、Subject `http://localhost:3000` |
| 运行环境 | Nacos `<nacos-dev-addr>:<nacos-port>`（namespace `<dev-namespace>`）；Redis `<redis-mysql-addr>:<redis-port>`；MySQL 以 Nacos 拉取值为准 |

## 2. 第一部分：死代码清理（已提交）

### 2.1 清理内容

- 删除接口声明 `SubjectInfoService.page(SubjectInfoEntity, int, Long, Long, Integer)`（`coder-club-subject-infra/.../service/SubjectInfoService.java`）
- 删除实现 `SubjectInfoServiceImpl.page(...)`（leftJoin + 固定 `info.getId()` 关联、无 `is_deleted` 过滤的旧实现）
- import 清理：接口删 `Page`；实现删 `Page`、`ObjectUtils`；**保留** `QueryMethods`/`QueryWrapper`/`SubjectMappingEntity`/`SelectKey`（`countByCondition()`/`add()` 使用）

### 2.2 无调用者与契约影响确认

- infra 全模块 grep `.page(`：无残留
- 真实请求路径 `POST /subject/getSubjectPage` 走 domain `page()`，不经过 infra `page()`
- OpenAPI 源 SHA-256 未变化：`7576e28a346dcf60b304bdd405f0bb82b72252df37e96013509ece00c6a14a2e`（43 路径 / 43 操作）

### 2.3 测试命令与结果

| 命令 | 结果 |
| --- | --- |
| `git diff-tree --check fad2312 -r` | 通过 |
| `mvn -pl coder-club-subject/coder-club-subject-domain -am '-Dtest=SubjectInfoDomainServiceImplTest,SubjectInfoServiceImplTest' '-Dsurefire.failIfNoSpecifiedTests=false' test` | `SubjectInfoServiceImplTest` 3/3 + `SubjectInfoDomainServiceImplTest` 3/3，BUILD SUCCESS |
| `mvn -pl coder-club-subject/coder-club-subject-app/coder-club-subject-app-controller -am '-Dtest=SubjectContractTest' '-Dsurefire.failIfNoSpecifiedTests=false' test` | `SubjectContractTest` 45/45，BUILD SUCCESS |

## 3. 执行过程中的重要发现（供复核知悉）

首轮真实 DB 复核出现 total 全错（如 `subjectType=99` 返回 `total=23`）。Druid SQL 日志显示 count 执行了 `LEFT JOIN ... ON (subject_info.subject_difficult = 2) AND subject_mapping.is_deleted = 0` —— 过滤器写入 ON 子句、无 subject_id 关联。

**根因**：启动命令 `mvn spring-boot:run -pl <starter> -DskipTests`（未先安装）使服务引用了本地 Maven 仓库 `D:/Programs/Apache/apache-maven-3.8.4/maven-repo` 中 **2026-08-03** 的过期 `coder-club-subject-infra-1.0.jar`（早于 `06397f4` 分页计数对齐修复）。执行 `mvn install -DskipTests -q`（将当前源码装入本地仓库）后重启服务，total 即与 list 口径一致。

**处置**：首轮错误数据作废；以下全部为**新构建**实测。已将启动脚本修复为「先 `mvn install -DskipTests -q -pl <starter> -am`，再 `spring-boot:run`」（提交 `7c3ac66`），防止再次引用过期 jar。Backend Codex 复核时建议确认当前运行服务来自新构建。

## 4. 第二部分：真实 DB 九场景复核（新构建）

账号：`<test-account>`（`POST /auth/register` 注册，密码 BCrypt 加密存储）。请求头 `Authorization: <raw-token>`（Token 已脱敏，不写入本报告）。

以下为每个场景的**原始请求与原始 JSON 响应（不截断）**。

### 场景 1：无结果（subjectType=99）

请求：`POST /subject/getSubjectPage`

```json
{"pageNo":1,"pageSize":5,"subjectType":99}
```

响应：

```json
{"code":200,"data":{"list":[],"pageNo":1,"pageSize":5,"total":0,"totalPages":0},"message":"操作成功","success":true}
```

核对：`total=0`、`list=[]`、`totalPages=0` ✅

### 场景 2：单页（subjectType=1）

请求：

```json
{"pageNo":1,"pageSize":5,"subjectType":1}
```

响应：

```json
{"code":200,"data":{"list":[{"id":328,"labelName":["Redis","数据一致性"],"optionList":[],"pageNo":1,"pageSize":20,"subjectDifficult":1,"subjectName":"Redis有几种基础数据类型？","subjectParse":"Redis总共有五种基础数据类型","subjectScore":5,"subjectType":1},{"id":329,"labelName":["Redis","数据一致性"],"optionList":[],"pageNo":1,"pageSize":20,"subjectDifficult":1,"subjectName":"Redis 是什么类型的数据库？","subjectParse":"Redis 是一种开源的内存中数据结构存储，作为键值存储数据库，它支持多种数据结构如字符串、哈希、列表、集合等。","subjectScore":5,"subjectType":1},{"id":330,"labelName":["Redis","数据一致性"],"optionList":[],"pageNo":1,"pageSize":20,"subjectDifficult":1,"subjectName":"以下哪种数据结构不是 Redis 原生支持的？","subjectParse":"Redis 原生支持字符串、列表、集合、哈希和有序集合等数据结构，但不支持图结构。图形数据需要通过其他方式模拟。","subjectScore":5,"subjectType":1},{"id":331,"labelName":["Redis","数据一致性"],"optionList":[],"pageNo":1,"pageSize":20,"subjectDifficult":1,"subjectName":"Redis 中用于设置键过期时间的命令是？","subjectParse":"EXPIRE 命令用于为指定的键设置过期时间，以秒为单位。当键过期时，它将被自动删除。","subjectScore":5,"subjectType":1}],"pageNo":1,"pageSize":5,"total":4,"totalPages":1},"message":"操作成功","success":true}
```

核对：`total=4`、`list.length=4`、`totalPages=1` ✅

### 场景 3：多页第 1 页（subjectType=4）

请求：

```json
{"pageNo":1,"pageSize":5,"subjectType":4}
```

响应：

```json
{"code":200,"data":{"list":[{"id":100,"labelName":["Redis","数据一致性"],"optionList":[],"pageNo":1,"pageSize":20,"subjectDifficult":1,"subjectName":"Redis支持哪几种数据类型？","subjectParse":"解析什么","subjectScore":1,"subjectType":4},{"id":101,"labelName":["Redis","数据一致性"],"optionList":[],"pageNo":1,"pageSize":20,"subjectDifficult":2,"subjectName":"Redis的高级数据类型有什么？","subjectParse":"解析什么","subjectScore":1,"subjectType":4},{"id":102,"labelName":["Redis","数据一致性"],"optionList":[],"pageNo":1,"pageSize":20,"subjectDifficult":1,"subjectName":"Redis的优点有什么？","subjectParse":"解析什么","subjectScore":1,"subjectType":4},{"id":103,"labelName":["Redis","数据一致性"],"optionList":[],"pageNo":1,"pageSize":20,"subjectDifficult":1,"subjectName":"Redis相比Memcached有哪些优势？","subjectParse":"解析什么","subjectScore":1,"subjectType":4},{"id":104,"labelName":["Redis","数据一致性"],"optionList":[],"pageNo":1,"pageSize":20,"subjectDifficult":1,"subjectName":"Redis是单进程单线程的？","subjectParse":"解析什么","subjectScore":1,"subjectType":4}],"pageNo":1,"pageSize":5,"total":14,"totalPages":3},"message":"操作成功","success":true}
```

核对：`total=14`（运行库实际值，dump 为 12，见第 6 节）、`list.length=5`、`totalPages=3` ✅

### 场景 4：多页第 2 页（subjectType=4）

请求：

```json
{"pageNo":2,"pageSize":5,"subjectType":4}
```

响应：

```json
{"code":200,"data":{"list":[{"id":105,"labelName":["Redis","数据一致性"],"optionList":[],"pageNo":1,"pageSize":20,"subjectDifficult":2,"subjectName":"数据库和缓存的数据一致性如何保障，有哪些方案？","subjectParse":"解析什么","subjectScore":1,"subjectType":4},{"id":105,"labelName":["Redis","数据一致性"],"optionList":[],"pageNo":1,"pageSize":20,"subjectDifficult":2,"subjectName":"数据库和缓存的数据一致性如何保障，有哪些方案？","subjectParse":"解析什么","subjectScore":1,"subjectType":4},{"id":106,"labelName":["Redis","数据一致性"],"optionList":[],"pageNo":1,"pageSize":20,"subjectDifficult":1,"subjectName":"redis过期策略都有哪些？","subjectParse":"解析什么","subjectScore":1,"subjectType":4},{"id":107,"labelName":["Redis","数据一致性"],"optionList":[],"pageNo":1,"pageSize":20,"subjectDifficult":1,"subjectName":"什么是缓存穿透？","subjectParse":"解析什么","subjectScore":1,"subjectType":4},{"id":108,"labelName":["Redis","数据一致性"],"optionList":[],"pageNo":1,"pageSize":20,"subjectDifficult":1,"subjectName":"什么是缓存击穿","subjectParse":"解析什么","subjectScore":1,"subjectType":4}],"pageNo":2,"pageSize":5,"total":14,"totalPages":3},"message":"操作成功","success":true}
```

核对：`list.length=5`，与第 1 页 id（100-104）不重复 ✅。注：id=105 因双映射（category 2/3 + label 44）在页内出现 2 行（见第 6 节，已知语义风险，不阻塞）。

### 场景 5：多页第 3 页（subjectType=4）

请求：

```json
{"pageNo":3,"pageSize":5,"subjectType":4}
```

响应：

```json
{"code":200,"data":{"list":[{"id":109,"labelName":["Redis","数据一致性"],"optionList":[],"pageNo":1,"pageSize":20,"subjectDifficult":1,"subjectName":"什么是缓存雪崩","subjectParse":"解析什么","subjectScore":1,"subjectType":4},{"id":110,"labelName":["Redis","数据一致性"],"optionList":[],"pageNo":1,"pageSize":20,"subjectDifficult":1,"subjectName":"redis的setnx和setex区别","subjectParse":"解析什么","subjectScore":1,"subjectType":4},{"id":327,"labelName":["Redis","数据一致性"],"optionList":[],"pageNo":1,"pageSize":20,"subjectDifficult":1,"subjectName":"缓存真的好用吗？","subjectParse":"好用","subjectScore":2,"subjectType":4},{"id":338,"labelName":["Redis","数据一致性"],"optionList":[],"pageNo":1,"pageSize":20,"subjectDifficult":1,"subjectName":"feign-chain-verify-20260803-1","subjectScore":10,"subjectType":4}],"pageNo":3,"pageSize":5,"total":14,"totalPages":3},"message":"操作成功","success":true}
```

核对：`list.length=4`（14-5-5=4，与 `total=14` 一致）、与第 1/2 页不重复 ✅。注：id=338（`feign-chain-verify-20260803-1`）为 dump 后新增的运行库数据，type=4 实际 14 条而非 dump 的 12 条。

### 场景 6：过滤-分类（categoryId=2）

请求：

```json
{"pageNo":1,"pageSize":20,"categoryId":2}
```

响应（`data.list` 共 20 条，`total=22`、`totalPages=2`）：

```json
{"code":200,"data":{"list":[{"id":100,"labelName":["Redis","数据一致性"],"optionList":[],"pageNo":1,"pageSize":20,"subjectDifficult":1,"subjectName":"Redis支持哪几种数据类型？","subjectParse":"解析什么","subjectScore":1,"subjectType":4},{"id":101,"labelName":["Redis","数据一致性"],"optionList":[],"pageNo":1,"pageSize":20,"subjectDifficult":2,"subjectName":"Redis的高级数据类型有什么？","subjectParse":"解析什么","subjectScore":1,"subjectType":4},{"id":102,"labelName":["Redis","数据一致性"],"optionList":[],"pageNo":1,"pageSize":20,"subjectDifficult":1,"subjectName":"Redis的优点有什么？","subjectParse":"解析什么","subjectScore":1,"subjectType":4},{"id":103,"labelName":["Redis","数据一致性"],"optionList":[],"pageNo":1,"pageSize":20,"subjectDifficult":1,"subjectName":"Redis相比Memcached有哪些优势？","subjectParse":"解析什么","subjectScore":1,"subjectType":4},{"id":104,"labelName":["Redis","数据一致性"],"optionList":[],"pageNo":1,"pageSize":20,"subjectDifficult":1,"subjectName":"Redis是单进程单线程的？","subjectParse":"解析什么","subjectScore":1,"subjectType":4},{"id":105,"labelName":["Redis","数据一致性"],"optionList":[],"pageNo":1,"pageSize":20,"subjectDifficult":2,"subjectName":"数据库和缓存的数据一致性如何保障，有哪些方案？","subjectParse":"解析什么","subjectScore":1,"subjectType":4},{"id":106,"labelName":["Redis","数据一致性"],"optionList":[],"pageNo":1,"pageSize":20,"subjectDifficult":1,"subjectName":"redis过期策略都有哪些？","subjectParse":"解析什么","subjectScore":1,"subjectType":4},{"id":107,"labelName":["Redis","数据一致性"],"optionList":[],"pageNo":1,"pageSize":20,"subjectDifficult":1,"subjectName":"什么是缓存穿透？","subjectParse":"解析什么","subjectScore":1,"subjectType":4},{"id":108,"labelName":["Redis","数据一致性"],"optionList":[],"pageNo":1,"pageSize":20,"subjectDifficult":1,"subjectName":"什么是缓存击穿","subjectParse":"解析什么","subjectScore":1,"subjectType":4},{"id":109,"labelName":["Redis","数据一致性"],"optionList":[],"pageNo":1,"pageSize":20,"subjectDifficult":1,"subjectName":"什么是缓存雪崩","subjectParse":"解析什么","subjectScore":1,"subjectType":4},{"id":110,"labelName":["Redis","数据一致性"],"optionList":[],"pageNo":1,"pageSize":20,"subjectDifficult":1,"subjectName":"redis的setnx和setex区别","subjectParse":"解析什么","subjectScore":1,"subjectType":4},{"id":327,"labelName":["Redis","数据一致性"],"optionList":[],"pageNo":1,"pageSize":20,"subjectDifficult":1,"subjectName":"缓存真的好用吗？","subjectParse":"好用","subjectScore":2,"subjectType":4},{"id":328,"labelName":["Redis","数据一致性"],"optionList":[],"pageNo":1,"pageSize":20,"subjectDifficult":1,"subjectName":"Redis有几种基础数据类型？","subjectParse":"Redis总共有五种基础数据类型","subjectScore":5,"subjectType":1},{"id":329,"labelName":["Redis","数据一致性"],"optionList":[],"pageNo":1,"pageSize":20,"subjectDifficult":1,"subjectName":"Redis 是什么类型的数据库？","subjectParse":"Redis 是一种开源的内存中数据结构存储，作为键值存储数据库，它支持多种数据结构如字符串、哈希、列表、集合等。","subjectScore":5,"subjectType":1},{"id":330,"labelName":["Redis","数据一致性"],"optionList":[],"pageNo":1,"pageSize":20,"subjectDifficult":1,"subjectName":"以下哪种数据结构不是 Redis 原生支持的？","subjectParse":"Redis 原生支持字符串、列表、集合、哈希和有序集合等数据结构，但不支持图结构。图形数据需要通过其他方式模拟。","subjectScore":5,"subjectType":1},{"id":331,"labelName":["Redis","数据一致性"],"optionList":[],"pageNo":1,"pageSize":20,"subjectDifficult":1,"subjectName":"Redis 中用于设置键过期时间的命令是？","subjectParse":"EXPIRE 命令用于为指定的键设置过期时间，以秒为单位。当键过期时，它将被自动删除。","subjectScore":5,"subjectType":1},{"id":332,"labelName":["Redis","数据一致性"],"optionList":[],"pageNo":1,"pageSize":20,"subjectDifficult":1,"subjectName":"以下哪些是 Redis 支持的持久化机制？","subjectParse":"Redis 提供两种主要的持久化机制：AOF 和 RDB。AOF 是通过记录每个写操作来实现持久化，而 RDB 是通过定期生成数据快照来实现的。Snapshotting 其实是 RDB 的工作原理之一，D 选项不正确因为 Redis 确实有持久化选项。","subjectScore":5,"subjectType":2},{"id":333,"labelName":["Redis","数据一致性"],"optionList":[],"pageNo":1,"pageSize":20,"subjectDifficult":1,"subjectName":"在 Redis 中，哪些命令可以用于从集合（Set）中随机获取元素？","subjectParse":"SRANDMEMBER 命令用于从集合中随机返回一个或多个元素，而 SPOP 命令则用于随机移除并返回一个元素。SINTER 用于求集合的交集，SMEMBERS 则用于返回集合中的所有成员。","subjectScore":5,"subjectType":2},{"id":334,"labelName":["Redis","数据一致性"],"optionList":[],"pageNo":1,"pageSize":20,"subjectDifficult":1,"subjectName":"关于 Redis 缓存淘汰策略，以下哪些描述是正确的？","subjectParse":"volatile-lru 策略只对设置了过期时间的键进行 LRU 淘汰。allkeys-random 策略会随机淘汰任何键，无论是否设置了过期时间。volatile-ttl 策略实际上是优先淘汰剩余生存时间最短的键，而不是最长的。noeviction 策略在内存不足时不会淘汰任何键，而是返回错误。","subjectScore":5,"subjectType":2},{"id":335,"labelName":["Redis","数据一致性"],"optionList":[],"pageNo":1,"pageSize":20,"subjectDifficult":1,"subjectName":"Redis 支持事务操作，但不支持事务的回滚。","subjectParse":"Redis 支持事务操作，通过 MULTI 和 EXEC 命令来执行一组命令。但是，Redis 的事务不支持回滚机制。如果事务中的某个命令出错，其他命令仍会继续执行。Redis 的事务是“乐观锁”的一种实现，主要用于确保一组命令的原子性执行。","subjectScore":5,"subjectType":3}],"pageNo":1,"pageSize":20,"total":22,"totalPages":2},"message":"操作成功","success":true}
```

核对：`total=22` 与「按 categoryId=2 过滤的 list 条数」一致（交叉验证见场景 6b：pageSize=50 时 `list.length=22`）✅

### 场景 6b：交叉验证（categoryId=2 全量）

请求：

```json
{"pageNo":1,"pageSize":50,"categoryId":2}
```

响应（`data.list` 共 22 条，`total=22`、`totalPages=1`；id 序列 100-110,327,328-331,332-334,335-337 共 22 条）：

```json
{"code":200,"data":{"list":[{"id":100,"labelName":["Redis","数据一致性"],"optionList":[],"pageNo":1,"pageSize":20,"subjectDifficult":1,"subjectName":"Redis支持哪几种数据类型？","subjectParse":"解析什么","subjectScore":1,"subjectType":4},{"id":101,"labelName":["Redis","数据一致性"],"optionList":[],"pageNo":1,"pageSize":20,"subjectDifficult":2,"subjectName":"Redis的高级数据类型有什么？","subjectParse":"解析什么","subjectScore":1,"subjectType":4},{"id":102,"labelName":["Redis","数据一致性"],"optionList":[],"pageNo":1,"pageSize":20,"subjectDifficult":1,"subjectName":"Redis的优点有什么？","subjectParse":"解析什么","subjectScore":1,"subjectType":4},{"id":103,"labelName":["Redis","数据一致性"],"optionList":[],"pageNo":1,"pageSize":20,"subjectDifficult":1,"subjectName":"Redis相比Memcached有哪些优势？","subjectParse":"解析什么","subjectScore":1,"subjectType":4},{"id":104,"labelName":["Redis","数据一致性"],"optionList":[],"pageNo":1,"pageSize":20,"subjectDifficult":1,"subjectName":"Redis是单进程单线程的？","subjectParse":"解析什么","subjectScore":1,"subjectType":4},{"id":105,"labelName":["Redis","数据一致性"],"optionList":[],"pageNo":1,"pageSize":20,"subjectDifficult":2,"subjectName":"数据库和缓存的数据一致性如何保障，有哪些方案？","subjectParse":"解析什么","subjectScore":1,"subjectType":4},{"id":106,"labelName":["Redis","数据一致性"],"optionList":[],"pageNo":1,"pageSize":20,"subjectDifficult":1,"subjectName":"redis过期策略都有哪些？","subjectParse":"解析什么","subjectScore":1,"subjectType":4},{"id":107,"labelName":["Redis","数据一致性"],"optionList":[],"pageNo":1,"pageSize":20,"subjectDifficult":1,"subjectName":"什么是缓存穿透？","subjectParse":"解析什么","subjectScore":1,"subjectType":4},{"id":108,"labelName":["Redis","数据一致性"],"optionList":[],"pageNo":1,"pageSize":20,"subjectDifficult":1,"subjectName":"什么是缓存击穿","subjectParse":"解析什么","subjectScore":1,"subjectType":4},{"id":109,"labelName":["Redis","数据一致性"],"optionList":[],"pageNo":1,"pageSize":20,"subjectDifficult":1,"subjectName":"什么是缓存雪崩","subjectParse":"解析什么","subjectScore":1,"subjectType":4},{"id":110,"labelName":["Redis","数据一致性"],"optionList":[],"pageNo":1,"pageSize":20,"subjectDifficult":1,"subjectName":"redis的setnx和setex区别","subjectParse":"解析什么","subjectScore":1,"subjectType":4},{"id":327,"labelName":["Redis","数据一致性"],"optionList":[],"pageNo":1,"pageSize":20,"subjectDifficult":1,"subjectName":"缓存真的好用吗？","subjectParse":"好用","subjectScore":2,"subjectType":4},{"id":328,"labelName":["Redis","数据一致性"],"optionList":[],"pageNo":1,"pageSize":20,"subjectDifficult":1,"subjectName":"Redis有几种基础数据类型？","subjectParse":"Redis总共有五种基础数据类型","subjectScore":5,"subjectType":1},{"id":329,"labelName":["Redis","数据一致性"],"optionList":[],"pageNo":1,"pageSize":20,"subjectDifficult":1,"subjectName":"Redis 是什么类型的数据库？","subjectParse":"Redis 是一种开源的内存中数据结构存储，作为键值存储数据库，它支持多种数据结构如字符串、哈希、列表、集合等。","subjectScore":5,"subjectType":1},{"id":330,"labelName":["Redis","数据一致性"],"optionList":[],"pageNo":1,"pageSize":20,"subjectDifficult":1,"subjectName":"以下哪种数据结构不是 Redis 原生支持的？","subjectParse":"Redis 原生支持字符串、列表、集合、哈希和有序集合等数据结构，但不支持图结构。图形数据需要通过其他方式模拟。","subjectScore":5,"subjectType":1},{"id":331,"labelName":["Redis","数据一致性"],"optionList":[],"pageNo":1,"pageSize":20,"subjectDifficult":1,"subjectName":"Redis 中用于设置键过期时间的命令是？","subjectParse":"EXPIRE 命令用于为指定的键设置过期时间，以秒为单位。当键过期时，它将被自动删除。","subjectScore":5,"subjectType":1},{"id":332,"labelName":["Redis","数据一致性"],"optionList":[],"pageNo":1,"pageSize":20,"subjectDifficult":1,"subjectName":"以下哪些是 Redis 支持的持久化机制？","subjectParse":"Redis 提供两种主要的持久化机制：AOF 和 RDB。AOF 是通过记录每个写操作来实现持久化，而 RDB 是通过定期生成数据快照来实现的。Snapshotting 其实是 RDB 的工作原理之一，D 选项不正确因为 Redis 确实有持久化选项。","subjectScore":5,"subjectType":2},{"id":333,"labelName":["Redis","数据一致性"],"optionList":[],"pageNo":1,"pageSize":20,"subjectDifficult":1,"subjectName":"在 Redis 中，哪些命令可以用于从集合（Set）中随机获取元素？","subjectParse":"SRANDMEMBER 命令用于从集合中随机返回一个或多个元素，而 SPOP 命令则用于随机移除并返回一个元素。SINTER 用于求集合的交集，SMEMBERS 则用于返回集合中的所有成员。","subjectScore":5,"subjectType":2},{"id":334,"labelName":["Redis","数据一致性"],"optionList":[],"pageNo":1,"pageSize":20,"subjectDifficult":1,"subjectName":"关于 Redis 缓存淘汰策略，以下哪些描述是正确的？","subjectParse":"volatile-lru 策略只对设置了过期时间的键进行 LRU 淘汰。allkeys-random 策略会随机淘汰任何键，无论是否设置了过期时间。volatile-ttl 策略实际上是优先淘汰剩余生存时间最短的键，而不是最长的。noeviction 策略在内存不足时不会淘汰任何键，而是返回错误。","subjectScore":5,"subjectType":2},{"id":335,"labelName":["Redis","数据一致性"],"optionList":[],"pageNo":1,"pageSize":20,"subjectDifficult":1,"subjectName":"Redis 支持事务操作，但不支持事务的回滚。","subjectParse":"Redis 支持事务操作，通过 MULTI 和 EXEC 命令来执行一组命令。但是，Redis 的事务不支持回滚机制。如果事务中的某个命令出错，其他命令仍会继续执行。Redis 的事务是“乐观锁”的一种实现，主要用于确保一组命令的原子性执行。","subjectScore":5,"subjectType":3},{"id":336,"labelName":["Redis","数据一致性"],"optionList":[],"pageNo":1,"pageSize":20,"subjectDifficult":1,"subjectName":"在 Redis 中，所有数据都必须存储在内存中，即使使用持久化机制，数据也不会存储到磁盘。","subjectParse":"虽然 Redis 是一个内存数据库，所有操作都在内存中进行以保证高速性能，但 Redis 提供了持久化机制（AOF 和 RDB），允许将数据存储到磁盘中。这种机制确保了即使在服务器重启后，数据也可以从磁盘恢复到内存。","subjectScore":5,"subjectType":3},{"id":337,"labelName":["Redis","数据一致性"],"optionList":[],"pageNo":1,"pageSize":20,"subjectDifficult":1,"subjectName":"Redis 的发布/订阅（Pub/Sub）模式可以用于消息队列的持久化存储。","subjectParse":"Redis 的发布/订阅（Pub/Sub）模式用于实时消息传递，并不支持消息的持久化存储。一旦消息发布，Redis 不会保留消息历史。因此，Pub/Sub 适合于实时通信场景，但不适合需要消息持久化的场景。如果需要持久化，可以考虑使用 Redis Stream 或其他消息队列系统。","subjectScore":5,"subjectType":3}],"pageNo":1,"pageSize":50,"total":22,"totalPages":1},"message":"操作成功","success":true}
```

核对：`total=22`、`list.length=22`、`totalPages=1` —— 场景 6 的 `total` 与全量 list 条数一致 ✅

### 场景 7：过滤-分类+标签（categoryId=2, labelId=44）

请求：

```json
{"pageNo":1,"pageSize":20,"categoryId":2,"labelId":44}
```

响应：

```json
{"code":200,"data":{"list":[{"id":105,"labelName":["Redis","数据一致性"],"optionList":[],"pageNo":1,"pageSize":20,"subjectDifficult":2,"subjectName":"数据库和缓存的数据一致性如何保障，有哪些方案？","subjectParse":"解析什么","subjectScore":1,"subjectType":4}],"pageNo":1,"pageSize":20,"total":1,"totalPages":1},"message":"操作成功","success":true}
```

核对：`total=1`、`list.length=1`、`totalPages=1` ✅

### 场景 8：过滤-难度（subjectDifficult=2）

请求：

```json
{"pageNo":1,"pageSize":20,"subjectDifficult":2}
```

响应：

```json
{"code":200,"data":{"list":[{"id":101,"labelName":["Redis","数据一致性"],"optionList":[],"pageNo":1,"pageSize":20,"subjectDifficult":2,"subjectName":"Redis的高级数据类型有什么？","subjectParse":"解析什么","subjectScore":1,"subjectType":4},{"id":105,"labelName":["Redis","数据一致性"],"optionList":[],"pageNo":1,"pageSize":20,"subjectDifficult":2,"subjectName":"数据库和缓存的数据一致性如何保障，有哪些方案？","subjectParse":"解析什么","subjectScore":1,"subjectType":4},{"id":105,"labelName":["Redis","数据一致性"],"optionList":[],"pageNo":1,"pageSize":20,"subjectDifficult":2,"subjectName":"数据库和缓存的数据一致性如何保障，有哪些方案？","subjectParse":"解析什么","subjectScore":1,"subjectType":4}],"pageNo":1,"pageSize":20,"total":3,"totalPages":1},"message":"操作成功","success":true}
```

核对：`total=3` 与 `list.length=3` 口径一致 ✅。注：id=105 双映射出现 2 行（已知语义风险）。

### 场景 9：契约字段核验（任选上述响应）

以场景 2 响应为例，逐字段核对：

| 契约层 | 快照字段 | 实测 | 结果 |
| --- | --- | --- | --- |
| `ResponseResultPageSubjectInfo` | `success` (boolean) | `true` | ✅ |
| | `code` (integer) | `200` | ✅ |
| | `message` (string) | `"操作成功"` | ✅ |
| | `data` (PageResultSubjectInfo) | 对象 | ✅ |
| `PageResultSubjectInfo` | `pageNo` (integer) | `1` | ✅ |
| | `pageSize` (integer) | `5` | ✅ |
| | `total` (integer) | `4` | ✅ |
| | `totalPages` (integer) | `1` | ✅ |
| | `list` (array of SubjectInfoDTO) | 4 项 | ✅ |

快照来源：`api/coderclub-openapi.json` 的 `ResponseResultPageSubjectInfo`（四字段 required）与 `PageResultSubjectInfo`（五字段 required）。全部场景响应均含此九字段且类型一致。

## 5. 逐场景通用核对结论

- ✅ 每个场景 `total` == 同口径 list 条数（含 count==0 提前返回路径，场景 1 的 `total=0/list=[]/totalPages=0` 由 `PageResult` 默认值兜底）
- ✅ 每个场景 `totalPages` == `ceil(total / pageSize)`
- ✅ 多页场景（3/4/5）页间 list 不重复
- ✅ 空结果语义：`total=0`、`list=[]`、`totalPages=0`（场景 1）

## 6. 已知限制

1. **`subjectType=4` 实际 total=14（dump 为 12）**：运行库含 dump（`doc_<jc-club-db>-init.sql`）未列出的新题，如 id=338（`feign-chain-verify-20260803-1`，type=4）。按任务规定以实测为准。
2. **id=105 双映射重复行**（category 2/3 + label 44 双映射 → inner join 在部分过滤下出现 2 行）：count 与 list 均内连接、口径一致；与「去重后条数」不符属语义层面，不阻塞关闭（对应 Backend Codex 工作底稿 §7）。
3. **列表项携带未声明的 `pageNo`/`pageSize` 字段**：实测 `SubjectInfoDTO` 项含 `pageNo`/`pageSize`（item 内 `pageSize` 恒为默认 20，非请求值）。快照与运行时 OpenAPI 的 `SubjectInfoDTO` schema 均未声明这两个字段，属既有装饰性多余字段，不影响场景 9 必需字段。如需收敛，建议后续单独评估（本任务不产生契约变更）。
4. **运行环境**：Auth/Subject 均在本机启动（端口 <auth-port>/<subject-port>），依赖远程 Nacos/MySQL/Redis；启动脚本已修复为先安装再运行（提交 `7c3ac66`）。

## 7. 声明

- 未修改交接仓库 `api/coderclub-openapi.json` 快照、`status/sync-manifest.json`。
- 未修改前端项目。
- 未向运行库插入或删除任何业务测试数据（存量数据零写入，注册测试账号 `<test-account>` 属任务授权范围）。
- 本报告所有请求、响应与测试输出均为真实执行结果，未伪造。
- 首轮因引用过期 m2 jar 产生的错误数据已作废并在第 3 节说明，未作为本报告证据。

## 8. 待 Backend Codex 复核项

- [ ] 独立复验死代码清理提交 `fad2312`（范围、import、无 `page(` 残留）
- [ ] 独立复验启动脚本修复提交 `7c3ac66`
- [ ] 核对九场景原始请求/响应与第 5 节结论
- [ ] 填写本报告第 1 节「本回执提交哈希」并签署
