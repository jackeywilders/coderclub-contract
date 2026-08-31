# 任务书：阶段四 interview 服务实现（B-Impl，独立微服务）

> 派发角色：协调 PM
> 派发日期：2026-08-31
> 执行角色：后端实现（B-Impl）
> 决策依据：grill 共识 10 项（2026-08-31，用户逐项确认）+ brainstorming 设计确认（分节批准）；参考项目 `G:/Dev/backend/Club/jc-club`（`jc-club-interview` 模块设计蓝本）
> **ES 决策：本阶段不引入 Elasticsearch**（参考项目仅 subject 用 ES 且为 7.x 演示配置；interview 零 ES 依赖；服务器 ES 8.17 与参考 7.x 代码不匹配且闲置——已评估登记）
> 批次：阶段四独立批次；本批与 F-Impl 前端任务书（`interview-frontend-task.md`）两线并行

## 前置基线

- 新建服务 `coder-club-interview`（接入既有 `G:/Dev/backend/Club/CoderClub` 多模块结构，nacos/gateway/feign/sa-token 体系）；建议分支 `feat/interview-service`。
- **Apifox**：新服务模块「interview服务」须**由用户先行创建**（治理 2026-08-30 生效，MCP/客户端均无模块 API）；B-Impl 接单第一步提醒。
- **数据表基准确认**：已按 `docs/database/2026-08-31-coder-club-init.sql` 全库重建 utf8mb4（用户已执行，无字符集迁移）；interview 3 表按该文件结构与字段实现（`avg_score/score decimal(5,2)`、`hit_keywords json`、审计列）。
- **Nacos 配置模板前置（A1 模式）**：B-Impl 提供 `coder-club-interview-dev.properties` 配置模板（datasource/Redis/nacos discovery/sa-token/feign(auth,subject) url/interview 参数：抽题 N、三档文案、会话 TTL 2h），**真实值由用户在 Nacos 补齐**（A8-P3-BE 补 circle 配置先例）；凭据类（DB/Redis 密码）走既有 Jasypt 加密或用户注入，不落明文。
- **部署 JVM 约束**（代码评估：interview 为轻量服务，无大内存依赖）：`-Xms128m -Xmx384m -XX:MaxMetaspaceSize=256m`（DFA 词库/Redis 会话为 KB 级，调小堆不影响正常运作；显式控制防默认堆超载——服务器 7.5G 内存 7 服务并发临界）。
- 现有快照 `74417DD8`（75 路径）；本批登记后路径数 75 → **83**（interview 5 + 词库 3 = 8 端点；最终以实际登记为准）。

## 1. 任务明细

### S1 服务骨架
- `coder-club-interview` Maven 两模块：`coder-club-interview-api`（DTO/VO/接口契约）+ `coder-club-interview-server`（controller/service/domain/infra，对齐 CoderClub 现有 DDD 简化风格；nacos config/discovery、sa-token、feign(auth/subject)、mybatis-flex、Redis）。**服务名/Nacos 名 = `coder-club-interview`**（gateway 已预置 `lb://coder-club-interview` + `Path=/interview/**`，非白名单→401 兜底；端口惯例 **3600**）。**新服务缺失件自带**：GlobalExceptionHandler（含 `NotRoleException→403`）、SaTokenConfigure + StpInterface（读会话 roleKeys）、FeignConfig（token + X-Trace-Id RequestInterceptor）、nacos/redis/datasource 配置——镜像 circle/practice 先例。
- 统一 `ResponseResult`（success/code/message/data）；业务错误 HTTP 200 + code=400；401 网关登录墙兜底；403 非管理员由既有 `NotRoleException→403` 映射承接。

### S2 面试流程端点（`@SaCheckLogin`，C 端）
| 端点 | 请求 | 响应 |
| --- | --- | --- |
| `POST /interview/start` | `InterviewStartDTO {categoryId?}` | `InterviewStartVO {interviewId, questions:[{questionId, subjectName, labelNames}]}`——按分类/标签抽 **N 道简答题**（复用 subject 内部端点 `/subject/internal/random-subjects`，`typeCountMap {4:N}` 抽简答；Feign 模板镜像 `PracticeSubjectFeignClient`；N 默认 5 可配） |
| `POST /interview/submit` | `InterviewSubmitDTO {interviewId, questionId, answer}` | `InterviewSubmitVO {questionId, score, scoreText, hitKeywords[]}`——DFA 逐题评分，落 `interview_question_history` |
| `POST /interview/finish` | `InterviewFinishDTO {interviewId}` | `InterviewFinishVO {total, avgScore, scoreText, questionCount}`——汇总落 `interview_history` |
| `POST /interview/history` | 分页（pageNo/pageSize） | `Page<InterviewHistoryVO>`（id/分类/avgScore/scoreText/createdTime） |
| `POST /interview/history/detail` | `{interviewId}` | `InterviewDetailVO {history, questions:[{question, answer, score, scoreText, hitKeywords}]}` |

### S3 评分引擎（可插拔）
- `InterviewEngine` 接口：`ScoreResult evaluate(question, answer)`；默认实现 `DfaInterviewEngine`——**将 circle 模块 `WordFilter`/`WordContext` 抽取/复制到 interview 模块**（跨模块不可直接 import）构建**正向** Trie（独立于敏感词黑白 DFA，词库 = `interview_keyword`）；`score = hitKeywords / totalKeywords × 100`（0-100 整数）；`scoreText` 三档：**<60「基础待加强」/ 60-79「掌握良好」/ ≥80「理解深入」**；`hitKeywords` 仅返回命中词。
- LLM 引擎：**注册空实现**（接口契约就位、`engine` 参数扩展位，本轮不接外部 API、无 key/超时/降级处理）。

### S4 词库管理端点（`@SaCheckRole("admin_user")`）
- `POST /interview/keyword/list`（按分类列词库，全量）
- `POST /interview/keyword/save`（`{categoryId, keyword, weight?}`，同分类同词幂等）
- `POST /interview/keyword/remove`（`{id}` 逻辑删幂等）
- 语义与敏感词管理端点同构（管理端页面交互由 F-Impl 侧对齐）。

### S5 Redis 会话与词库缓存（关联 Redis 化任务书）
- **进行中面试会话**：`start` 创建后存 Redis（interviewId → 场次/题目/答案草稿，**TTL 2h**），`submit/finish` 读 Redis 会话、完成后落库并删除会话 key。
- **interview_keyword 词库缓存**：Redis 存词库数据源，`save/remove` 变更失效（pub/sub 或 TTL 失效）触发 `DfaInterviewEngine` 重建。
- **分布式锁**：`submit/finish` 防重、词库重建锁（Redis SETNX 封装）。

### S5 数据模型（3 张新表，统一 utf8mb4）
| 表 | 关键字段 |
| --- | --- |
| `interview_history` | id / user_id / category_id / avg_score / score_text / created_time |
| `interview_question_history` | id / history_id / question_id / answer / hit_keywords(JSON) / score / score_text / created_time |
| `interview_keyword` | id / category_id / keyword / weight(默认1) / is_deleted / created_time（自动填充） |

- schema 文档同步：`docs/database/schema/doc_jc-club-init.sql` 登记三表（与既有风格一致）；**运行时建表 DDL 由用户执行（A1 模式）**，B-Impl 不代执行。
- 种子词库：若干分类示例要点词（语义化占位，规则 8）。

### S6 源契约文档与快照衔接
- `docs/api/coderclub-openapi.json` 登记 interview 5 + 词库 3 = **8 端点** + 相关 schema（DTO/VO）；75 → **83** 路径；回执登记 LF SHA before/after（before = `26AEC009C4A823629DCC1D6EB5984773791BC3380407F846AAA7D4308F12CC90`）。
- 快照微同步由 PM 验收批次合并执行（interview 端点采纳）。

## 2. 质量门禁与验收证据

1. **契约测试** `InterviewContractTest`：start（抽题数量/分类过滤/401/403）/ submit（命中/未命中/边界 0 与 100）/ finish（汇总）/ history（分页/详情）/ 词库三端点（200/401/403 真实拦截链）——判别性断言（如 DFA 命中集与分数映射，误算必失败）。
2. **domain 单测**：`DfaInterviewEngine`（命中率计算/三档边界/空词库/null 答案）、词库 CRUD 幂等、history 落库链路。
3. 全仓 mvn 绿 + CI 双绿（build-and-test + sensitive-scan）；回执双轨（`handoff/backend-to-frontend/` 按创建日期，**含 `receiptCommitSha`**）+ 完成通知四字段。
4. **云端联调**（网关 5000）：登录墙 → start 抽题 → submit（命中/未命中各一）→ finish → history；admin 词库 save/list/remove + 403 非管理员；联调证据入回执。

## 3. 约束

- **不引入 ES**（本阶段明确决策）；不触碰其他服务/端点/既有表语义；复用 subject 题库只读，不改 subject。
- 新表 DDL 由用户执行（A1 模式），B-Impl 仅 schema 文档登记；不改 `api/` 快照与 `status/`（PM 验收后微同步）。
- 规则 8 占位符（示例关键词/文案语义化）、Conventional Commits；Apifox 同步按治理新流程（逐项比对、模块归位、用户先建模块）。

## 4. 关联

- 参考项目 `jc-club-interview`（设计蓝本）· grill 共识（PR 派发批次）· F-Impl 前端任务书（同批并行）· 字符集迁移评估（前置，A1 模式）
