# 回执：数据库数据依据落地（B-Impl）

> **回执角色：** 后端实现（B-Impl）
> **日期：** 2026-08-31（Asia/Shanghai）
> **任务书：** `pm/requirements/2026-08-31/database-init-landing-task.md`（已派发）
> **数据依据：** 交接仓库 main `docs/database/2026-08-31-coder-club-init.sql`（PR #140；用户已在云端库执行）
> **设计/计划：** 后端仓库 `docs/superpowers/specs/2026-08-31-database-init-landing-design.md`（e5fd53d）、`docs/superpowers/plans/2026-08-31-database-init-landing.md`（1a20196，随本 PR 合入）

## 1. 来源与提交哈希

| 项 | 值 |
| --- | --- |
| 实现仓库 | jackeywilders/coderclub（后端） |
| 分支 | `feat/backend-database-init-landing`（基于 `86a09e7`） |
| 实现头 | `7db8a33`（8 提交：spec + plan + L1 SQL + L2 实体 + L3 README + L5 JVM + 最终审查修复波 + **B-Review 对齐提交**——share_comment_reply 按 PM 裁决运行口径对齐权威 `478ed4a`，落地副本与权威 blob 逐字节一致 `8fcb38a`） |
| PR | **#20**（feat/backend-database-init-landing → main） |
| CI | build-and-test + sensitive-scan（head `7db8a33`，run 33410679502 双绿） |
| 合入状态 | **R1 达成**；R2 待人工合入（用户/B-Review 在 CI 全绿后执行） |

## 2. 任务明细（对照任务书 L1-L5）

1. **L1 SQL 数据依据** ✅：`docs/database/schema/2026-08-31-coder-club-init.sql`（26 表 / utf8mb4_0900_ai_ci / 707 条种子）落盘，删旧 `init.sql`/`doc_jc-club-init.sql`/`coderclub-seed-data-2026-08-13.sql`；与交接仓库权威文件 LF 规范化逐字节一致；**旧 interview 表 DROP 重建登记**（jc-club 结构 `interview_url/key_words/tip/interview_id/question/user_answer` 勿沿用；新 3 表 interview_history/interview_question_history/interview_keyword）。
2. **L2 实体核验** ✅：`SubjectBriefEntity.subjectId` Integer→**Long**（对齐 SQL bigint；连带 `BriefTypeHandler` 去 `Math.toIntExact` + 3 处测试断言 Long 化，聚焦测试 17 用例全绿）；`ShareCommentReplyEntity` 注释统一——**单列主键**口径 + `to_id`/`parent_id` 按 SQL 注释+种子对齐（PM 裁决；运行写路径差异见 §5 openFindings）；`sensitive_words.type` 默认 0 口径登记（README）。
3. **L3 数据说明** ✅：`docs/database/README.md` 8 节（数据依据/测试账号 admin+test01~04 密码 123456 BCrypt 可 matches 验证/种子样例/interview_keyword DFA 数据源/旧表重建/type 口径/JVM 预算/规则 8）；种子计数经协调者逐表复核（合计 707）。
4. **L5 JVM 预算** ✅：5 个 Dockerfile ENTRYPOINT 改 `["sh","-c","java $JAVA_OPTS -jar app.jar"]`；compose 注入 auth/gateway `-Xms128m -Xmx256m -XX:MaxMetaspaceSize=256m`、subject/practice/circle `-Xms128m -Xmx384m -XX:MaxMetaspaceSize=256m`；oss/interview 预算登记 README（无 compose 服务）；AGENTS/CLAUDE ENTRYPOINT 描述同步（最终审查修复）。

## 3. 测试证据

- 全仓 `mvn install -DskipTests -q` + `mvn test` 绿（exit 0）；subject Long 化聚焦测试 3 类 17 用例全绿；最终审查修复波 circle infra 编译通过。
- 一致性自检：SQL 26 表清单 + 关键表实体映射抽查（interview 3 表实体随 interview 服务任务落地）；种子计数逐表复核（707）。
- 审查链：brainstorming（澄清 2 项决策）→ SDD 执行（Task1-4 子代理 + 任务审查 clean）→ 全分支最终审查（修完再合：to_id/parent_id 注释口径 + 文档漂移 3 Important → 修复波 1f35e2b → 定向复审 **5/5 ADDRESSED**）。

## 4. 边界遵守声明（任务书 §2）

- 以交接仓库 SQL 为数据依据（运行时库已由用户执行，保持对齐）；不改既有业务字段语义（仅类型/注释统一）；未改 `api/` 快照与 `status/`；规则 8（README/回执无真实凭据，测试密码仅占位说明）；Conventional Commits。

## 5. 已知限制与延后项（openFindings）

1. **`share_comment_reply.to_id` 运行写路径与数据依据差异（PM 裁决后登记）**：种子/SQL 注释口径 = 存评论目标人员 id（type1=动态作者、type2=被回复评论者）；运行写路径 `ShareCommentDomainServiceImpl` type1 仍 `setToId(momentId)`——实体注释已按 SQL 口径改写并注明差异；**待 PM 裁决**（代码写路径对齐种子，或种子对齐代码）。
2. **`parent_id` 运行写路径同构差异**：新 SQL/种子口径 = `0=顶层`；运行写路径 type1 仍 `setParentId(-1L)`（旧 DDL 残留）——实体注释已对齐 SQL，写路径差异**待 PM 裁决**（并入上项一并处理）。
3. **`sensitive_words.type` 默认口径**：SQL `DEFAULT 0` vs 领域校验 1=黑名单/2=白名单；种子均 1/2，实际影响小（如需默认 1 另议）。
4. **旧 interview 表 DROP 重建**：新 SQL 已 `DROP TABLE IF EXISTS` + 重建（3 新表）；旧列名（interview_url/key_words/tip/interview_id/question/user_answer）勿复用——README §5 登记。
5. **DEPLOYMENT.md 同类文档漂移**：仍记载旧 ENTRYPOINT 形态（`["java","-jar","app.jar"]` 非 shell）——AGENTS/CLAUDE 已同步，DEPLOYMENT.md 后续顺手同步（不阻塞）。
6. **种子 type2 行 to_id 严格语义细节**：`"感谢支持"` 行（回复评论 1）`to_id=2` 指向被对话回复者（用户 2）而非严格"被回复评论者"（评论 1 作者=用户 3）——SQL 注释为简化表述，仅供 PM 决定是否收紧（不阻塞）。
7. **`SubjectBriefEntity` Long 化溢出语义**：断言值均在 int 范围内，未 pin 超 `Integer.MAX_VALUE` 场景（`Math.toIntExact` 移除后由抛异常变静默直通）——可选用例，延后。

## 6. 后续链

1. B-Review 复核签署 → PM 验收（to_id/parent_id 写路径差异裁决）。
2. 合入提醒：PR #20 CI 双绿，**合入由人工（用户/B-Review）在 GitHub 执行**。
3. 同批衔接：interview/搜索升级/Redis 化任务书；interview 服务接入时按 README §7 预算注入（256m/384m）。

---
- 回执角色：后端实现（B-Impl），2026-08-31
