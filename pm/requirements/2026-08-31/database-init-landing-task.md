# 任务书：数据库数据依据落地（B-Impl）

> 派发角色：协调 PM
> 派发日期：2026-08-31
> 执行角色：后端实现（B-Impl）
> 依据：`docs/database/2026-08-31-coder-club-init.sql`（26 表 utf8mb4 重建 + ~700 条种子，PM 已落交接仓库 main，PR #140；用户已在云端库执行）
> 决策依据：grill 共识（Q1-Q12）+ 前后端代码审查不一致清单（2026-08-31）
> 批次：阶段四配套（与 interview/搜索升级/Redis 化同批）

## 1. 任务明细

### L1 SQL 落后端数据依据
- 将 `docs/database/2026-08-31-coder-club-init.sql` 落地后端 `docs/database/`（对齐既有 `doc_jc-club-init.sql` 与 seed 数据文件约定；**统一 utf8mb4_0900_ai_ci**）。
- **旧 interview 表处置**：`doc_jc-club-init.sql`/seed 中旧 `interview_history`/`interview_question_history`（jc-club 结构：`interview_url/key_words/tip/interview_id/question/user_answer`）与新 SQL **同名不同构**——登记 DROP 重建（新 SQL 已覆盖），勿误用旧列名。

### L2 实体核验与注释统一（对照新 SQL）
- `SubjectBriefEntity.subject_id`：Integer → **Long**（对齐 SQL bigint，其余 subject FK 实体均 Long）。
- `ShareCommentReplyEntity`：javadoc「DDL 复合主键 (id,parent_id)」注释过时 → 更新为「新 SQL 单列主键 id，@Id 单列映射」；**`to_id` 语义注释统一**（DB 存 `moment_id`，type1=动态 id/type2=回复目标，读时派生态作者——与 SQL 注释、实际写入 `setToId(momentId)` 三方对齐）。
- `sensitive_words.type` 默认口径：SQL `DEFAULT 0` vs 领域校验 1/2——登记（种子均为 1/2，实际影响小；如需默认 1 另议）。

### L3 种子与使用说明
- 已按审查修正：`share_moment.reply_count` 与评论种子对齐（moment1=3 / moment3=1 / moment4=1）。
- 数据使用说明登记：测试账号 `admin/test01~test04`（密码 123456，BCrypt 哈希可 `matches` 验证）、分类/题目/词库样例、interview_keyword 评分词（DFA 构建数据源）。

### L4 质量门禁
- 落地后 schema 文档与 SQL 一致性自检（表清单 26、字段、索引）；全仓 mvn + CI 双绿；回执双轨（含 `receiptCommitSha`）+ 四字段。

## 2. 约束

- 以交接仓库 SQL 为**数据依据**（运行时库已由用户按该文件执行，保持对齐）；不改既有业务字段语义（仅注释/类型统一）。
- 不改 `api/` 快照与 `status/`；规则 8 占位符（测试密码哈希非明文）；Conventional Commits。

## 3. 关联

- 数据 SQL（PR #140）· grill 共识（Q1-Q12）· 审查不一致清单（2026-08-31）· interview/Redis/搜索升级任务书（同批）
