# A8 后端架构方向设计（阶段二~四 + 现有优化）

> 日期：2026-08-27（Asia/Shanghai）
> 状态：**已批准（grilling Q1-Q7 逐项确认）→ 本稿落盘**
> 来源：参考项目 `jc-club`（鸡翅CLUB 完整后端）深度勘察 + CoderClub 现状对比 + grilling 七项决策
> 定位：后端视角总体设计（与 `2026-08-26-a8-frontend-portal-design.md`（前端视角）配套）；阶段二~四实施按本稿 + 分阶段 proposal/writing-plans 推进

---

## 1. 背景与目标

A8 前端门户化已闭环（state `gate3-a8-phase1-accepted`），阶段二（练题）、三（社区）、四（面试）将新增三个后端域。用户提供参考后端项目 `jc-club`（前端参考项目 `jc-club-front-master` 的配套后端），要求：以 jc-club 为蓝本对比现有 CoderClub 后端，确定**现有后端优化方向**与**新域后续开发方案**。本次讨论（grilling Q1-Q7）已逐项确认，本稿落盘供分阶段实施引用。

## 2. 现状与参考项目对比

### 2.1 参考项目 jc-club 全貌（勘察摘要）

| 维度 | jc-club | 评估 |
| --- | --- | --- |
| 形态 | 8 个独立 Maven 服务：gateway(5000)/oss/auth/subject/practice/circle/interview/wx，各自独立仓、独立 pom | 微服务拆分完整但版本各自管 |
| 技术栈 | Java 8 + Spring Boot 2.4.2 + Cloud Alibaba 2021.1 + Sa-Token（仅 gateway+auth）+ OpenFeign + MyBatis-Plus 3.4 + RocketMQ + XXL-Job + ES(subject) + MapStruct + Druid | 版本偏旧 |
| 鉴权 | 网关 SaReactorFilter 路径规则（`/subject/subject/add` 等 checkPermission），loginId header 透传 + LoginContextHolder；业务服务零鉴权，信任 header | 集中式，权限在 Redis（`auth.role:{userName}`/`auth.permission:{userName}`） |
| 分层 | auth/subject 四层（api/application/domain/infra/common）；practice/circle/interview 两段式（api+server，判分退化为手写 if/else） | 两段式为退化 |
| practice | 12 接口完整状态机（草稿→续答→单题判分→交卷→报告→排行→放弃）；直连 subject 8 张表；随机组卷 SQL（order by rand + exclude + CONCAT 组装）；报告内存聚合标签星级；排行 count 聚合 | **蓝本**（含 1 个口径 bug：先算率后补差集） |
| interview | 双引擎（JiChi 规则兜底：PDF 解析 + DFA 关键词 + subject_type=4 随机 8 题 + 分数段文案；AlBL LLM：阿里云百炼，**apiKey 硬编码在类中**，SSE 解析脆弱） | 规则引擎形态可借鉴；硬编码禁止 |
| circle | 动态/评论树/消息 + WebSocket 即时推送 + DFA 敏感词（WordContext/WordFilter Trie + 白名单）+ Caffeine 30s 缓存在线 | 敏感词/树实现可参考；WebSocket 评估后置 |
| 登录 | wx 服务公众号验证码 → Redis openId → Sa-Token 签发 | 我们已定扫码占位，不复制 |
| 技术债 | 密钥硬编码（Nacos/MySQL/MinIO/LLM）、无全局异常（try-catch 样板）、三套 Result/PageResult 不一致（practice 用 `result`、circle/interview 用 `records`）、AI 解析脆弱 + SSRF（任意 URL 下载）、死代码（DemoController 等）、复合主键设计怪异、网关路由名与 Nacos 名不一致 | 全部避免项 |

### 2.2 CoderClub 现状（对比基准）

| 维度 | 现状 |
| --- | --- |
| 形态 | 单仓聚合 5 模块（auth/subject/common/dependencies/oss），docker-compose 部署 mysql/redis/auth/subject |
| 技术栈 | Sa-Token 4（`sa-token-spring-boot4-starter` + `sa-token-redis-jackson`，**Redis 共享存储**）；统一 `ResponseResult`/`PageInfo`/`GlobalExceptionHandler`；四层结构（app/domain/infra/common + api 模块）；契约测试体系（SubjectContractTest 57/57、AuthContractTest 12/12） |
| 鉴权 | 业务服务内 `@SaCheckLogin`（+ Redis 共享 token）；A8-P1 已建跨服务 Feign（`AuthUserFeignClient.listByUserNames` 携 Sa-Token 透传） |
| 契约 | 快照 46 端点（`4BFB3C72`），语义差异 21；云端 25 表与 schema 文档核验一致 |
| 前端 | 门户化完成（A8-P1）：vite proxy 多目标直连各服务 |

### 2.3 结论

- **照搬**：practice 练题状态机、随机组卷思路、DFA 敏感词、双引擎抽象、面试规则引擎形态。
- **不照搬**：独立仓拆分、两段式分层、密钥硬编码、无全局异常、三套 Result、WebSocket（后置评估）、wx 服务、旧技术栈版本。
- **已有优势延续**：单仓聚合、统一分层/异常/响应/分页、契约测试、Redis 共享 token（为网关低成本引入提供前提）。

## 3. 决策记录（grilling Q1-Q7，全部获批）

| # | 决策 | 结论 |
| --- | --- | --- |
| Q1 | 工程形态 | **单仓聚合继续**：新增 `coder-club-practice`/`coder-club-circle`/`coder-club-interview` 模块入现有聚合；每域一个 docker 镜像/服务部署（docker-compose 扩展） |
| Q2 | 网关 | **引入 Spring Cloud Gateway**（统一入口/登录校验/loginId 透传） |
| Q3 | 网关时机 | **网关先行**：独立任务线与阶段二并行，覆盖现有 auth/subject + 后续新域；登录校验级（权限留服务内）、匿名白名单、header 覆写防伪造、CORS 统一；现有 `@SaCheckLogin` 保留双保险（零迁移）；契约/前端代码/契约测试零改动 |
| Q4 | 数据访问 | **全 Feign 契约化**：题目读（随机抽题/类目计数/批量取题）与**判分**收敛到 subject 域内部端点（标注 internal），practice/interview 纯消费——判分规则单一实现，业务行为一致 |
| Q5 | 阶段二范围 | **P0 答题链 + P1 报告/排行一起做**（约 12 端点全量一次提案） |
| Q6 | 阶段三范围 | 动态/评论/敏感词 + 消息落库拉取；**WebSocket 后置**为可选增强（不进验收标准） |
| Q7 | 优化清单 | A 组随任务顺带（死代码扫描、docker-compose 扩展、云端验证机制化）；B 组实现期决策（判分收敛、索引后置评估）；C 组按既定（WebSocket、vitest 评估、A9 敏感扫描） |

## 4. 工程形态（Q1 细则）

- 新域模块结构（对齐现有）：`coder-club-practice` / `coder-club-circle` / `coder-club-interview`，各含 api / app(controller) / domain / infra / starter 子模块（参照 auth/subject 既有四层）；依赖 `coder-club-dependencies`（版本管理）与 `coder-club-common`。
- 新域之间不直接依赖；跨服务仅经 Feign（`-api` 模块中的 FeignClient + FeignConfig 透传机制，参照 `AuthUserFeignClient` 模式）。
- 部署：docker-compose 新增 `coder-club-practice`/`coder-club-circle`/`coder-club-interview`/`coder-club-gateway` 服务（参照现有 auth/subject 服务段）；本地新增 `start-practice.ps1` 等（参照 `start-auth.ps1`）。

## 5. 网关专项（Q2/Q3 细则）

### 5.1 模块与依赖

- 新模块 `coder-club-gateway`（starter 形态独立应用）：`spring-cloud-starter-gateway` + `sa-token-reactor` 系 + `sa-token-redis-jackson`（**同一 Redis 存储**，与业务服务共享 token 体系）；服务发现：**统一沿用现有 Nacos 注册中心**（docker-compose 内亦可用服务名直连，实现期验证取舍）。
- 注解说明：网关为 WebFlux 环境，用 `sa-token-reactor` 过滤器（**非**业务服务的 `spring-boot4-starter` servlet 版）；两者同 token 存储（Redis），双向可校验。

### 5.2 鉴权模型

- **网关职责（登录校验级）**：SaReactorFilter 拦截全部请求；未登录（无有效 token）→ 401；白名单路径直接放行。**权限校验不迁移**——现有服务内权限逻辑（admin 系列端点等）维持现状，避免双份权限漂移。
- **loginId 透传**：网关 GlobalFilter 解析 Sa-Token 取 loginId → 写入请求头（如 `loginId`）转发下游；**必须覆盖客户端传入的同名头**（防伪造）；下游保持现有 `LoginContextHolder`/Feign 透传机制（现有 FeignConfig 透传 satoken 头不变，两机制并存兼容）。
- **匿名白名单（已知列举，实现期验证补全）**：`/auth/login`、`/auth/register`、`/auth/wx-login`、`/oss/upload`、`/oss/getUrl` 及网关健康检查路径等；登录后端点（`/auth/user/info` 等）必须校验。**风险：漏配导致登录/注册瘫痪——实现期以契约 46 端点逐项核对白名单**（B-Impl 网关任务验收项）。
- **401 语义**：未登录 401 从网关返回（业务服务 `@SaCheckLogin` 仍保留双保险，行为不变）；契约测试（standalone MockMvc）不经过网关，不受影响。

### 5.3 路由表（按契约 46 端点前缀；StripPrefix 实现期按实际 controller 路径确认）

| 前缀 | 目标服务 | 说明 |
| --- | --- | --- |
| `/auth/**` | coder-club-auth | 现有路径直通（controller 路径即 `/auth/...`） |
| `/subject/**` | coder-club-subject | 同上 |
| `/oss/**` | coder-club-oss | 同上（upload 为直连 Upload action，网关放行白名单内） |
| `/practice/**` | coder-club-practice | 阶段二新增 |
| `/circle/**` | coder-club-circle | 阶段三新增 |
| `/interview/**` | coder-club-interview | 阶段四新增 |

### 5.4 CORS

- CORS 统一配置在网关（GatewayCorsConfig 允许域名列表占位符化）；各业务服务不再各自处理（现有无显式 CORS 则无迁移）。

### 5.5 兼容性清单（已验收部分零改动）

- 契约路径零变更（网关透明路由）；前端代码零改动（仅 vite proxy/部署 env 改单入口）；业务服务 `@SaCheckLogin` 保留；Feign 透传现状保留；契约测试不受影响；A8-P1 已验收前端无返工。

### 5.6 部署与运行

- docker-compose：新增 gateway 容器（对外暴露网关端口，如 5000；auth/subject 容器保持内部端口，对外仅经网关——**云端/本地过渡期可双暴露**，切换完成后收敛）。
- 本地：`start-gateway.ps1`（Nacos 凭据沿用用户级环境变量模式）；前端 `vite.config` proxy 目标改网关单入口。
- 云端真实入口切换：随网关任务验收后由用户/运维执行（真实域名映射占位符约定）。

### 5.7 风险与注意点

1. 匿名白名单枚举遗漏（§5.2，验收强制项）
2. loginId header 伪造（网关覆写，必做）
3. 网关单点（docker-compose 依赖链 + 部署注意事项；发布前评估冗余）
4. WebSocket 未被本网关方案涵盖（后置项，届时评估网关 WS 透传或独立通道）

## 6. 阶段二：practice 练题域（Q4/Q5 细则）

### 6.1 数据访问边界（Q4：全 Feign）

- practice 不直连 subject 表；题目能力全部经 subject 域**内部端点**（标注 internal，不对外宣传，参照 `list-by-identifiers` 定位）：
  - `随机抽题`：按标签/分类组装条件 + 数量 + 排除集 → 返回题目 id 集（内部）
  - `类目计数`：专项练习内容（大类→分类→标签 + 题目量）数据源（内部）
  - `批量取题`：按 id 集取题目详情（题干/选项，不含答案）与答案比对所需数据（内部，或按需合并进判分端点）
  - `判分`：提交作答（题目 id/类型/答案集）→ subject 域按题型规则判分返回对错（**判分规则唯一实现**，复用现有题型 Service/Handler）
  - 端点最终形态与数量由 B-Review 差异分析 + proposal 定稿（预计 3-4 个 internal 端点）
- practice 自身 C 端端点走契约（12 接口蓝本，§6.2）；用户信息（昵称头像）复用现有 `auth list-by-identifiers`。

### 6.2 端点集（12 接口蓝本，P0+P1 同批）

| # | 端点（POST /practice/...） | 语义要点（参考 jc-club 蓝本） |
| --- | --- | --- |
| 1 | `set/getSpecialPracticeContent` | 专项练习内容：大类→分类→标签树（有题量才算） |
| 2 | `set/addPractice` | 开始专项练习：assembleIds（`catId-labelId`）→ 组装题目 → 建草稿 practice_info → 返回 setId |
| 3 | `set/getSubjects` | 套卷题目列表（含续答：带 practiceId 回填已答状态 isAnswer/answerContent；首进建草稿） |
| 4 | `set/getPracticeSubject` | 单题内容（不含答案） |
| 5 | `set/getPreSetContent` | 预设套卷列表（orderType 排序：名称/时间/热度） |
| 6 | `set/getUnCompletePractice` | 未完成练习分页（complete_status=0） |
| 7 | `detail/submitSubject` | 单题提交：Feign 判分 → 落 practice_detail（answer_status/answer_content 排序逗号串）→ 幂等更新 |
| 8 | `detail/submit` | 交卷：**先补未答差集记录，再算 correct_rate**（修正 jc-club 先算后补的口径 bug）→ 完成态 + set_heat+1 |
| 9 | `detail/getReport` | 评估报告：正确题数（n/m）+ 按标签聚合正确率 → 技能星级列表 |
| 10 | `detail/getScoreDetail` | 答题明细（题号/题型/对错） |
| 11 | `detail/getSubjectDetail` | 单题答案详情（选项含 isCorrect/正确答案/我的答案/解析/标签） |
| 12 | `detail/getPracticeRankList` | 综合练习榜（practice_info count 聚合 + Feign 昵称头像；门户首页右栏练习榜启用） |

- 可选：`detail/giveUp`（放弃：软删明细 + 删 practice_info）——纳入与否由 B-Review 差异分析定。
- 报告/排行数据源全部现有 4 表可支撑（云端核验）；`time_use` 格式 "HH:mm:ss"、`answer_content` 排序逗号串、`correct_rate` decimal(10,2) 字段语义沿用。

### 6.3 练题状态机（蓝本细化）

`开始(addPractice/getSubjects) → 草稿(complete_status=0, time_use=00:00:00) → 单题作答与判分(submitSubject) → [续答: practiceId 回填] → 交卷(submit: 补差集→算率→完成) → 报告/解析(getReport/getScoreDetail/getSubjectDetail) → 排行(getPracticeRankList)`；并发/幂等：单题判分 update-or-insert；放弃可选。

### 6.4 分层与实现约束

- CoderClub 四层结构；判分逻辑**不再在 practice 内实现**（Feign 调 subject 判分端点）——与 jc-club 的手写 if/else 反模式划清界限。
- 随机组卷逻辑落 subject 内部端点（参照 jc-club SQL：CONCAT(category_id,'-',label_id) in (assembleIds) + excludeSubjectIds + order by rand() limit N，数量配比 单选10/多选6/判断4 等由 proposal 定）。
- 测试：practice 契约测试（草稿/续答/判分/交卷口径/报告聚合/排行）+ subject internal 端点契约用例；Feign 联调以契约测试 mock + 云端真实验证双覆盖。

## 7. 阶段三：circle 社区域（Q6 细则）

### 7.1 端点集（蓝本 + 我们表结构；全部 C 端消费）

| 端点 | 语义 |
| --- | --- |
| `GET /circle/share/circle/list` | 圈子树（Caffeine 短缓存可选） |
| `POST /circle/share/moment/save` / `getMoments` / `remove` | 动态发布（敏感词校验）/分页列表（批量用户昵称头像）/删除（级联 + 回减评论数） |
| `POST /circle/share/comment/save` / `list` | 评论/回复（reply_type 1评论 2回复；parent_id 语义）/树形列表；保存后消息落库 |
| `GET|POST /circle/share/message/unRead` / `getMessages` | 未读/消息列表（读取即已读） |
| `POST /circle/sensitive/words/save` / `remove` | 敏感词管理（sensitive_words 表） |

### 7.2 敏感词 DFA

- 参考 jc-club 形态：`WordContext` 启动全量加载 `sensitive_words`（words/type 1黑 2白）→ DFA Trie Map；`WordFilter`（replace/include/check，白名单跳过，skip 间隔可选）；发布/评论时 `check()` 含敏感词 → 拒绝（业务错误）。
- 实现放 circle common/infra；表已有默认数据（黑：赌博/代开发票；白：招聘——云端核验）。

### 7.3 评论树

- `share_comment_reply`（moment_id/reply_type/to_id/to_user/reply_id/reply_user/content/parent_id...复合主键已定，云端核验）——树构建（TreeUtils）与子树批量软删 + `reply_count` 回减；删除语义与计数一致性为验收点。

### 7.4 消息（Q6 决策 A）

- 消息落库（`share_message`：from_id/to_id/content JSON{msg,msgType,targetId}/is_read）+ 列表/未读接口；**读取即已读**；无 WebSocket（后置可选增强，不进验收）。
- content JSON 与 msgType（COMMENT/COMMENT_REPLY）沿用既有样例语义。

### 7.5 图片

- 动态/评论图片走 OSS（契约已具 `/oss/upload`），pic_urls 为 URL JSON 数组字符串（字段语义沿用）。

## 8. 阶段四：interview 面试域（既定延续 + 细节补充）

### 8.1 端点集（5 接口）

| 端点 | 语义 |
| --- | --- |
| `POST /interview/analyse` | 简历解析 → 关键词（InterviewVO{questionList}） |
| `POST /interview/start` | 按关键词生成 ≤8 题（InterviewQuestionVO） |
| `POST /interview/submit` | 提交作答 → avgScore/tips（落库 interview_history + detail） |
| `POST /interview/getHistory` | 历史分页 |
| `GET /interview/detail` | 单次面试答题详情 |

### 8.2 引擎抽象（AI mock，既定）

- `InterviewEngine` 接口 + Spring 注册表（ApplicationContextAware 收集，按 `engine` 分发）——参照 jc-club 双引擎抽象。
- **JuChiMockEngine（默认兜底）**：简历 PDF 解析 → DFA 关键词提取（词典 = `subject_label` 全量 labelName 建树）→ 经 subject internal 端点按标签随机抽 `subject_type=4`（简答）题 ≤8 → 评分 = 分数段规则 + 内置文案（示例文案占位符/中性化，不复制 jc-club 玩梗文案原样——文案实现期定）。
- **LLM 引擎仅保留接口 + 配置骨架（阶段四不接真实模型）**：密钥**禁止硬编码**——按环境变量占位符约定（用户级）接入；真实接入资源到位后启用（同扫码登录占位逻辑）。

### 8.3 表映射与字符集

- `interview_history`（avg_score/key_words/tip/interview_url/created_by）、`interview_question_history`（interview_id/score/key_words/question/answer/user_answer）字段语义与云端核验一致。
- **字符集风险（既有提示）**：interview 两表为 latin1/utf8mb3——阶段四实施前评估 utf8mb4 迁移（DDL 类，按 A1 模式用户执行），回执须记录字符集检查结论。

## 9. 优化清单（Q7 细则）

### A 组（随任务顺带）
1. 死代码/调试残留扫描清理：新域实现前，B-Impl 对现有 auth/subject 扫描（jc-club 有 DemoController 先例）；发现即清（提交独立，回执记录清单）
2. docker-compose 扩展：gateway + 三新域服务段（随各自任务加入）
3. 云端真实验证机制化：A8-P1-BE 待办（search/contribute SQL 执行、Feign 联调、401 端到端、topN 边界）在网关引入后一并验证（网关 + 服务双链路）；后续每域验收后沿用

### B 组（实现期决策）
4. 判分能力收敛（Q4 落地：subject 域判分/抽题/组装内部端点化，含题型 Service 复用/必要重构）
5. 索引与性能：search LIKE / contribute count 当前量级小，数据增长后评估索引（不提前建）

### C 组（后置/既定）
6. WebSocket（Q6）；前端 vitest（阶段二评估）；安全暴露面与全历史敏感扫描（A9 门禁既有流程）
7. 配置外部化（Nacos 环境变量 + 测试凭据环境变量已在用，无新动作）

## 10. 落地顺序与依赖

- **阶段二链**：① phase-2 任务书更新（吸收 Q4 全 Feign + Q5 P0/P1）→ ② B-Review 差异分析 + proposal（subject internal 端点 + practice 12 端点 + 判分语义 + DDL 差异清单）→ ③ PM 确认 → ④ B-Impl 实现（**网关任务线并行**：coder-club-gateway 模块 + 白名单验证 + loginId 透传 + 部署/入口切换）→ ⑤ 回执 → B-Review 签署 → PM 验收 → 快照全链同步 → ⑥ 云端真实验证（网关链路）→ ⑦ 前端阶段二任务书（F-Impl：练习三页）
- **阶段三链**（circle）：同构（proposal → 实现 → 验收 → 前端）
- **阶段四链**（interview）：同构（含字符集迁移评估前置）
- 每阶段契约变更走 `proposals/` + PM 确认；快照同步按既有模式。

## 11. 风险与待决

| 项 | 说明 | 处置 |
| --- | --- | --- |
| 网关匿名白名单 | 枚举遗漏 → 登录瘫痪 | 实现期按 46 端点逐项核对（验收强制项） |
| practice 判分/内部端点语义 | 端点形态未定稿 | B-Review proposal 定稿 + PM 确认 |
| categoryId 一级过滤语义 | openFinding（阶段一遗留） | 后端确认（随阶段二） |
| interview 表字符集 | latin1/utf8mb3 | 阶段四前迁移评估（A1 模式） |
| 云端真实验证 | A8-P1-BE 已知限制 | 网关引入后一并执行 |
| 登录扫码/WX/LLM 资源 | 均未就绪 | 占位（既有决策），资源到位再联调 |

## 12. 关联

- 前端门户设计：`docs/superpowers/specs/2026-08-26-a8-frontend-portal-design.md`（PR #64）
- 阶段二提案任务书：`pm/requirements/2026-08-27/phase2-practice-contract-proposal-task.md`（PR #78，**待按 Q4/Q5 更新**）
- 参考项目勘察：jc-club / jc-club-front-master（本稿 §2.1 为勘察摘要）
- 契约快照：`api/coderclub-openapi.json`（46 端点，`4BFB3C72`）；state：`gate3-a8-phase1-accepted`