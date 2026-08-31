# DATABASE-INIT-LANDING 数据库数据依据落地——后端评审复核工作底稿

> 角色：后端评审（B-Review）
> 日期：2026-08-31
> 任务书：`pm/requirements/2026-08-31/database-init-landing-task.md`；数据依据 SQL：交接仓库 PR #140（权威 `docs/database/2026-08-31-coder-club-init.sql`）
> 回执：`handoff/backend-to-frontend/2026-08-31/backend-database-init-landing-report.md` + `-summary.json`（PR #146，head `373de34` 已合入 main；回执分支 `claude/backend-database-init-landing-receipt` 同步实施头至 `7db8a33`，head `4738ec4`，main 版待随后续提交更新）
> 实施：CoderClub PR #20（head `7db8a33`，8 commits；**本会话复核 + 对齐核验通过后已合入 main `8cfb40b0`，R2 达成**）

## 1. 人链核验：实施提交存在性与一致性

| 项 | 证据 | 结果 |
| --- | --- | --- |
| 提交对象 | `git cat-file -t 7db8a33` 成功（走 7892 代理 fetch `feat/backend-database-init-landing`）；远端 PR #20 head 与本地对象一致 | ✅ |
| CI | PR #20 head `7db8a33`：build-and-test ✅（job 99549181282，run 33410679502，15:55:00Z 完成）+ sensitive-scan ✅（job 99549181466）——GitHub API 逐 job 核实；对齐提交后重跑双绿 | ✅ |
| 提交数 | **8 commits**（7 实施 + 1 对齐提交 `7db8a33`：share_comment_reply 对齐 PM 裁决运行口径） | ✅ |
| summary 一致性 | 回执分支 `4738ec4`：`implementationCommitSha=7db8a33`、`receiptCommitSha=5e204ce`、PR #20 一致（main 版仍 1f35e2b，待同步合入） | ✅ |
| PR #20 合入 | 本会话独立复核（CI 双绿 + 代码级复核 + SQL 字节核验 + 本地测试复验全过，含对齐闭环）后以 merge 方式合入 main（merge `8cfb40b0`，B-Review 授权合入人身份）——**R2 达成**（main tip 核验 `8cfb40b0`） | ✅ |

## 2. 代码级复核（对照回执与任务书 L1-L5，实读源码 @ `7db8a33`）

| 核对项 | 证据 | 结果 |
| --- | --- | --- |
| **L1 SQL 数据依据** | `docs/database/schema/2026-08-31-coder-club-init.sql`：**26 表**（`CREATE TABLE` 计数实测）、utf8mb4_0900_ai_ci、种子 707（回执逐表复核）；旧 3 文件（`init.sql`/`doc_jc-club-init.sql`/`coderclub-seed-data-2026-08-13.sql`）已删（实测不存在） | ✅ |
| **L1 权威一致性（对齐闭环）** | 落地副本 @ `7db8a33` 与交接仓库权威（`478ed4a`）**逐字节一致**：SHA256 均 = `6AB9F81CC8AAFAA9949E845C8703424E15A074B638A67239E7490DBA5202DFB0`（LF 字节态独立重算，非转录） | ✅ |
| **L1 旧表重建登记** | 旧 jc-club 结构 interview 表（`interview_url`/`key_words`/`tip` 等旧列）DROP 重建登记 README §5，新 3 表勿沿用旧列名 | ✅ |
| **L2 Long 化** | `SubjectBriefEntity.subjectId` Integer→Long；`BriefTypeHandler` 去 `Math.toIntExact` 直赋；3 处测试断言（BriefTypeHandlerTest/SubjectBriefServiceImplTest/SubjectInternalDomainServiceImplTest）Long 化 | ✅ |
| **L2 实体注释** | `ShareCommentReplyEntity`：类 javadoc 单列主键口径；`to_id` javadoc = 运行口径（type1=动态id/type2=回复目标评论id；读时派生人员语义；写路径 type1 存 moment_id）；`parent_id` = -1=顶层（**对齐 PM 裁决，与权威 SQL/运行写路径三方一致**） | ✅ |
| **L2 type 口径** | `sensitive_words.type` SQL 默认 0 vs 领域校验 1/2：种子均 1/2、影响小，已登记 README §6（PM 裁决随签） | ✅ |
| **L3 README** | `docs/database/README.md` 8 节：数据依据/测试账号（admin、test01~04，123456 BCrypt 可 matches 验证，不落明文）/种子样例/interview_keyword DFA 源/旧表重建/type 口径/JVM 预算/规则 8 | ✅ |
| **L5 JVM 预算** | 5 Dockerfile（auth/subject/practice/circle/gateway）ENTRYPOINT → `["sh","-c","java $JAVA_OPTS -jar app.jar"]`；compose 注入 auth/gateway `-Xms128m -Xmx256m -XX:MaxMetaspaceSize=256m`、subject/practice/circle `-Xms128m -Xmx384m -XX:MaxMetaspaceSize=256m`；oss/interview 预算登记 | ✅ |
| **边界** | 本批不改 `api/` 快照与 `status/`；无运行时 DDL（SQL 已由用户云端执行）；docs/superpowers spec/plan 属 B-Impl 范围 | ✅ |

## 3. 独立复验（本底稿复核时执行）

| 命令/动作 | 结果 |
| --- | --- |
| `git archive 7db8a33` 隔离目录全量 `mvn install -DskipTests -q` + `mvn test` | **exit 0，BUILD 全绿**（7db8a33 与首验 1f35e2b 代码逻辑零差异——对齐提交仅 SQL 文档 + 实体注释） |
| SQL 字节态 SHA（`git cat-file blob`） | 落地副本 = 权威 `478ed4a` = `6AB9F81C…` 逐字节一致 |
| 表清单/旧文件 | CREATE TABLE 计数 26；旧 3 SQL 文件不存在 |
| 一致性自检 | 关键表实体映射抽查（subject_brief Long 化、share_comment_reply 注释、interview 3 表登记） |

## 4. 对齐过程登记（B-Review 复核发现 → 用户裁决 → B-Impl 修复 → 闭环）

1. **复核发现**：落地副本与 `ShareCommentReplyEntity` 注释停留在 PM 裁决前口径（to_id=人员语义、parent_id=0 顶层），与 PM 裁决后权威 `478ed4a`（to_id=momentId、parent_id=-1）不一致。
2. **用户裁决**（2026-08-31）：**先对齐再合入**。
3. **B-Impl 对齐**：追加提交 `7db8a33`（2 文件 9+/9-：SQL `share_comment_reply` 段 to_id/parent_id 列注释 + 5 行种子 type1 行 to_id=momentId/parent_id=-1、type2 行 parent_id=目标评论 id；实体 to_id/parent_id javadoc 同步运行口径，代码逻辑零改动）。
4. **独立核验**：落地副本 @ 7db8a33 与权威 `478ed4a` 逐字节一致（SHA 独立重算）；CI 重跑双绿（run 33410679502）。**闭环，授权合入**。

## 5. 延后项核查（回执 openFindings + 本底稿观察，均不阻塞）

| # | 项 | 复核意见 |
| --- | --- | --- |
| 1 | `sensitive_words.type` DEFAULT 0 vs 领域 1/2 | PM 裁决已随签（种子均 1/2，默认 1 需另议），接受 |
| 2 | DEPLOYMENT.md 仍记旧 ENTRYPOINT 形态 | AGENTS/CLAUDE 已同步；DEPLOYMENT.md 同步延后（非阻塞），接受 |
| 3 | 种子 type2 `to_id` 严格语义（"感谢支持"行 to_id=2 vs 严格被回复者用户 3） | SQL 注释简化表述，PM 可后续收紧（可选），接受 |
| 4 | `SubjectBriefEntity.subjectId` Long 溢出语义未钉（Math.toIntExact 移除后溢出变静默透传） | 超出 Integer.MAX 现实不可达，可选测试延后，接受 |
| 5 | **[新增观察]** `ShareCommentReplyEntity.id` 字段注释仍写「DDL 复合主键 (id,parent_id) 按 id 单列映射」（类 javadoc 已改单列主键） | 既有遗留注释残留（非本批引入），表述性；后续注释统一批次可顺手修正——[仅供参考] |

## 6. 复核结论

**通过，签署。** 回执声明（8 提交、26 表/707 种子、Long 化、L5 JVM、对齐后权威一致）与人链核验、代码实读、SQL 字节核验、独立测试复验逐项一致；对齐闭环（用户裁决先对齐再合入 → B-Impl `7db8a33` → 独立核验逐字节一致）完整；PR #20 已按授权合入 main（`8cfb40b0`），R2 达成。未发现 [必须修复]/[建议修改] 问题（1 处既有注释残留 [仅供参考]）。

## 7. 关联

- 任务书 · 数据依据 SQL PR #140 · 回执 PR #146（head `373de34` 合入 main；分支 `4738ec4` 同步实施头待合入）· 实施 CoderClub PR #20（merged `8cfb40b0`）
- 后续：回执文档实施头同步合入 main → PM 验收（openFindings 已裁决）→ 阶段四 interview 服务任务（interview 3 表实体随服务落地）
