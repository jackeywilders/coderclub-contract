# 后端回执：A8 阶段二 practice 练题域（A8-P2-BE）

> **任务 ID：** A8-P2-BE
> **实施角色：** 后端实现（B-Impl）
> **日期：** 2026-08-27/28（Asia/Shanghai）
> **任务书：** `pm/requirements/2026-08-27/phase2-practice-implementation-task.md`（PR #82）
> **提案/决策：** `proposals/backend/2026-08-27/phase2-practice-endpoints-proposal.md`（PR #81）、`pm/reviews/2026-08-27/phase2-practice-endpoints-proposal-decision.md`（C5-C7/G1/D0）
> **后端仓库 PR：** jackeywilders/coderclub#14（base=main，CI 全绿：build-and-test + sensitive-scan）
> **契约快照：** `contractSnapshotSha256=4bfb3c72`（当前值；验收后 PM 全链同步 +17 后更新）

---

## 1. 任务概览

实现阶段二练题域：**subject internal 4 端点**（I1-I4，判分复用 Handler 工厂的**唯一判分实现**）+ 新模块 **coder-club-practice 13 端点**（P0 答题链 8 + P1 报告/排行 4 + giveUp 1）；硬条件（交卷先补差集再算率、简答不判分且不进分母、submitSubject update-or-insert 幂等、practice 全 Feign 不直连 subject 表）落实；`docs/api/coderclub-openapi.json` 登记 17 端点（LF SHA before/after 记录）；无 DDL（D0）；既有 46 端点零语义变更；网关（GW-1 已合入）链路验证全部通过。

## 2. subject internal 端点（4，`/subject/internal/*`，@SaCheckLogin，仅内部 Feign 消费）

| # | 端点 | 语义要点 |
|---|---|---|
| I1 | POST /subject/internal/random-subjects | assembleIds（`catId-labelId`，catId=subject_mapping.category_id 分类叶子 id）→ JOIN subject_info 取题型 → 配比（typeCountMap）逐型 `rand() limit` 合并去重 / 配比空全量随机；排除集 NOT IN；`<foreach>` 防注入；响应 `List<Long>` |
| I2 | POST /subject/internal/category-count | 大类→分类→标签树 + `count(distinct subject_id)` 题量（大类口径 = 子分类 id 并集防重复）；subjectCount=0 不产出；categoryType 1/2/3 层级标注 |
| I3 | POST /subject/internal/subjects-by-ids | id 集批量取题（@Size≤500）；withAnswer 开关：false 剥离 isCorrect/subjectParse，true 携带 + subjectAnswer（radio/multiple 标号串、judge=subject_judge.is_correct、brief=subject_brief.subject_answer） |
| I4 | POST /subject/internal/judge | **判分唯一实现**：扩展 `AbstractSubjectTypeHandler.judgeSubject` + 四 Handler（单选/多选 optionList isCorrect==1 标号排序集合比对【distinct】、判断 is_correct 布尔、简答 judgeable=false）；`SubjectTypeHandlerFactory` 分发；非法 type → `BaseException(400, "不支持的题目类型: "+type)` |

## 3. practice 模块（coder-club-practice，13 端点，端口 ${SERVER_PORT:3400}）

新聚合（api/app/domain/infra/starter，mirror subject 四层；`com.jackey.practice`）；双 Feign 客户端（`PracticeSubjectFeignClient` I1-I4 + `AuthUserFeignClient` list-by-identifiers，Authorization 透传 + FeignConfig 兜底）；TraceIdFilter/GlobalExceptionHandler/SaTokenConfig 镜像既有先例；虚拟线程开启（对齐 auth/subject/oss）。

| # | 端点（POST /practice/...） | 语义要点（硬条件已落实） |
|---|---|---|
| 1 | set/getSpecialPracticeContent | I2 树（有题量） |
| 2 | set/addPractice | I1 组卷 → practice_set(set_type=1) + set_detail + practice_info(complete_status=0, time_use=00:00:00)；续做（practiceId 存在/本人/未完成）直接返回；@Transactional |
| 3 | set/getSubjects | 卷内题目（I3 withAnswer=false）+ practice_detail 回填 isAnswer/answerContent；**按 set_detail 卷序重排**；I3 **500 分片**合并；**越权归属校验**（practiceId） |
| 4 | set/getPracticeSubject | 单题内容（I3） |
| 5 | set/getPreSetContent | set_type=2；orderType 1 名称/2 最新/3 最热；PageInfo |
| 6 | set/getUnCompletePractice | complete_status=0 + created_by=当前用户 → PageResult |
| 7 | detail/submitSubject | **I4 判分 → practice_detail update-or-insert（practice_id+subject_id 判定）幂等**；answer_status=(judgeable&&isCorrect)?1:0（简答→0）；**交卷后（complete_status=1）禁止提交 → 400「练习已交卷，不能继续答题」**（最终审查守卫） |
| 8 | detail/submit | **@Transactional 交卷口径：先补差集（set_detail 全题集 − 已答集 → answer_status=0/answer_content='' 批量 insert，顺序断言 inOrder）→ 重读统计：分母=全题集非简答、正确=非简答 answer_status=1 → correct_rate=correct*100/denominator（decimal(10,2) HALF_UP；分母 0→0.00）→ complete_status=1+submit_time+timeUse(格式校验) → set_heat 数据库侧原子+1** |
| 9 | detail/getReport | 口径与交卷一致（同 set_detail 权威 + practice_detail 状态）；I3 取标签 → 内存按 labelName 聚合正确率 → 星级（≥90→5/≥80→4/≥70→3/≥60→2/<60→1）；`skills[{labelName, correctRate, starLevel}]` |
| 10 | detail/getScoreDetail | practice_detail 全量（order by id） |
| 11 | detail/getSubjectDetail | **I3 withAnswer=true（C5）**：选项含 isCorrect/正确答案/我的答案/解析/标签；未作答 myAnswer=null/"" 可查看 |
| 12 | detail/getPracticeRankList | practice_info group by created_by（complete_status=1, is_deleted=0）→ count desc → topN（默认 10、@Min(1) @Max(20)、越界 400、body 可省略）→ Feign list-by-identifiers 昵称头像（缺失/失败 fallback userName，镜像 contribute 先例） |
| 13 | detail/giveUp | @Transactional 软删 practice_detail + practice_info（归属校验） |

## 4. 硬条件证据（单元/契约测试锁定）

- **交卷先补差集再算率**：`PracticeDetailDomainServiceImplTest` InOrder 断言（saveBatch 差集 → 重读统计 → updateById → incrementHeat）；硬断言差集数量/rate 25.00/分母 0→0.00。
- **简答不判分且不进分母**：`BriefTypeHandler.judgeSubject → (false,false)`；submit/getReport 统计对 subject_type=4 剔除分母/分子。
- **submitSubject update-or-insert 幂等**：selectByPracticeIdAndSubjectId 判定 + 插入/更新两分支测试。
- **全 Feign**：practice 源码无任何 subject 表直连（唯一数据通路 = PracticeSubjectFeignClient I1-I4 + AuthUserFeignClient）。
- **越权防护**：listSubjects/getPracticeSubject/submitSubject/submit/getReport/giveUp 等 practiceId 统一 `requireOwnedPractice`（存在/本人）+ 越权 400 用例。

## 5. 契约登记（docs/api/coderclub-openapi.json）

- **+17 路径**（practice 13 + internal 4），46→63 路径；既有 46 路径/50 schemas **语义零变更**（程序化 JSON 深度对比 0 差异）。
- **LF SHA-256**：before `BA74B152730A2F532A8118C18F20AB395CCD4AEA04DB672A17120833705493B1` → after `9EC37C66571E40745732880309EEB231E7DC7C67C21F37BC466059C1F9959D4D`（含 submitSubject 交卷守卫语义描述）。
- internal 标注「仅内部 Feign 消费，不向 C 端门户宣传」；全部 @SaCheckLogin 登录墙；业务错误 HTTP 200 + body code=400（全仓口径）、参数校验 HTTP 400、未登录 401；示例语义化（规则 8）。

## 6. 测试证据

- **全量**：`mvn test -B` 27 模块 **1028 例** BUILD SUCCESS（Failures 0/Errors 0）；`mvn install -DskipTests -q` exit 0。
- **PracticeContractTest 22/22**（13 端点 + 401/400/守卫/越权）；**SubjectContractTest 71/71 不回归**（既有 57 + internal 14）；Handler 判分 9 例 + 共享方法 4 例；域层（交卷口径/报告聚合/排行降级/分片/卷序）24 例；FeignConfig 4 例；round-trip 2 例；TraceIdFilterConfig 等。
- 流程：7 任务逐任务实现+审查+修复循环（0 Critical 遗留）；最终整分支审查 FIX-THEN-MERGE → 修复轮（65 文件 LF + 交卷守卫）→ 定向复审 2/2 ADDRESSED、无新破坏。

## 7. 云端/网关联调证据（真实 Nacos/MySQL/Redis 8.8.1，全经网关）

四服务本地起连云端中间件（auth/subject/gateway/practice；practice Nacos 配置 `coder-club-practice-dev.properties` 用户已建）：

| 组 | 结果 |
|---|---|
| 网关 /practice 路由转实（原预留 503 → 可达） | ✅ 200；practice 服务 UP（db/redis UP） |
| I1 random-subjects（真实 SQL 随机抽题） | ✅ 5 条 id |
| I2 category-count（现实题量树） | ✅ 树根产出 |
| I3 withAnswer=false / true（剥离/携带） | ✅ 剥离 0 isCorrect+无 parse；携带 3 isCorrect+parse |
| I4 judge（单选对/错、判断对/错、简答不可判分） | ✅ True/True、False/True、True/True、judgeable=False |
| practice getSpecialPracticeContent / addPractice / getSubjects（23 题+回填）/ getPreSetContent / getUnCompletePractice | ✅ |
| submitSubject 四题型（radio/multiple/judge 判对、brief 不计分）+ 幂等重提 | ✅ |
| submit 交卷 → getReport（total=11 correct=3 **rate=27.27** 简答剔除分母、skills+starLevel） | ✅ |
| getScoreDetail / getSubjectDetail（myAnswer/parse/含正确选项） | ✅ |
| getPracticeRankList（count 聚合 + Feign 昵称；created_by 数字 id 时按设计回退 failback） | ✅ count=3 |
| giveUp（软删后未完成列表不含该卷） | ✅ |
| 交卷后守卫 | ✅ HTTP200 + body code=400「练习已交卷，不能继续答题」 |
| practice 未登录 401 / internal 未登录 401（经网关登录墙） | ✅ |
| loginId 透传 | ✅ 行为性（链路畅通；语义由 11 个集成测试覆盖） |

**A8-P1-BE 衔接**：search/contribute/Feign/401/topN 已在此前 GW-1 联调覆盖；本轮 practice 域全 Feign 链路（Feign 跨服务 I1-I4 + list-by-identifiers）经网关实测通过。

## 8. 已知限制与观察（均已在审查/裁定中记录）

- **practice_detail 无唯一索引（D0 人类裁定保持无 DDL）**：submitSubject update-or-insert 存在低概率并发二行窗口；接受并文档化（防御 putIfAbsent/distinct 兜底）；后续可经 proposal 评估补 `uk(practice_id, subject_id)`。
- **排行昵称回退**：practice_info.created_by 存数字 loginId；auth list-by-identifiers 按 userName 查询不命中时回退 userName（= loginId 数字串）——按契约设计的 fallback 行为；真实昵称展示可在前端阶段二消费或后续优化（practice 侧存 userName 需额外 auth 数据，非本批范围）。
- **业务错误 HTTP 200 + body code=400**（全仓既有口径，契约已按此登记）；**双套 PageInfo 架构债**（subject-common 与 common 各一，后续收敛单独立项）；**update_time 不刷新**（与 subject 全 8 实体既有 onUpdateValue 基线一致）。
- 部署：Dockerfile.practice（全 27 pom 清单，auth/subject/gateway 同步）、compose +practice 段、start-practice.ps1（NACOS_ADDR 环境变量、无真实 IP）；本机无 docker，容器级实证列验收补充项；T3-IMP3 jasypt/springdoc 补全指引见 docs/gateway/README §12。

## 9. 规则 8 声明

全部提交/文档/回执无真实凭据/IP 字面量（CI sensitive-scan IPv4 模式 0 命中）；联调账号经 `CODER_CLUB_TEST_*` 用户级环境变量内存使用、未落盘/未提交/未入回执；云端 Nacos/DB/Redis 地址经环境变量/Nacos 配置注入。