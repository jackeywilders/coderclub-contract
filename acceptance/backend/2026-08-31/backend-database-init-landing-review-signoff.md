# DATABASE-INIT-LANDING 数据库数据依据落地——后端评审复核签署

> 角色：后端评审（B-Review）
> 签署日期：2026-08-31
> 任务书：`pm/requirements/2026-08-31/database-init-landing-task.md`
> 回执：`handoff/backend-to-frontend/2026-08-31/backend-database-init-landing-report.md` + `-summary.json`（PR #146，head `373de34` 已合入 main；回执分支 `4738ec4` 已同步实施头 `7db8a33`，main 版回执待同步合入）
> 工作底稿：`designs/backend/2026-08-31/backend-database-init-landing-review-workpaper.md`
> 状态：**签署通过，转 PM 验收**

## 1. 复核结论

✅ **复核通过，签署本回执。** 实施 `7db8a33`（CoderClub PR #20，8 commits）经人链核验与独立复验与任务书/规格相符：

- [x] **L1 SQL 数据依据**：26 表 / utf8mb4_0900_ai_ci / 707 种子落盘，删旧 3 文件；**落地副本与交接仓库权威（`478ed4a`）逐字节一致**（SHA `6AB9F81C…` 独立重算）；旧 interview 表 DROP 重建登记（勿用旧列名）
- [x] **L2 实体核验**：`SubjectBriefEntity.subjectId` Long 化（连带 `BriefTypeHandler` 去 `Math.toIntExact` + 3 处测试断言）；`ShareCommentReplyEntity` 注释统一（单列主键 + to_id/parent_id **运行口径**，与权威 SQL/写路径三方一致）；`sensitive_words.type` 默认 0 口径登记
- [x] **L3 README**：8 节数据说明（测试账号 BCrypt 可验证、种子样例、interview_keyword DFA 源、旧表重建、type 口径、JVM 预算、规则 8）
- [x] **L5 JVM 预算**：5 Dockerfile ENTRYPOINT shell 形态 + compose JAVA_OPTS（auth/gateway 256m、subject/practice/circle 384m）；oss/interview 预算登记
- [x] **独立复验（本会话实跑）**：隔离目录全量 `mvn install -DskipTests` + `mvn test` **exit 0**；SQL 字节态 SHA 独立重算与权威一致；26 表计数/旧文件删除实测
- [x] **CI 双绿**：run 33410679502（GitHub API 逐 job 核实 build-and-test + sensitive-scan，对齐提交后重跑）
- [x] **边界遵守**：不改 `api/` 快照与 `status/`；无运行时 DDL（SQL 已由用户云端执行）；docs/superpowers 属 B-Impl 范围

## 2. 对齐闭环登记（本批核心处置）

- **复核发现**：落地副本与实体注释停留在 PM 裁决前口径（人员语义/0 顶层），与裁决后权威 `478ed4a`（to_id=momentId、parent_id=-1）不一致。
- **用户裁决**：先对齐再合入 → **B-Impl 追加提交 `7db8a33`**（SQL `share_comment_reply` 段注释+种子 + 实体 javadoc 同步运行口径，代码逻辑零改动）。
- **独立核验**：落地副本 @ 7db8a33 与权威 `478ed4a` **逐字节一致**（SHA 独立重算）→ 授权合入。

## 3. 规则 9 完成通知四字段（自检）

| 字段 | 值 |
| --- | --- |
| 实施提交 SHA | `7db8a33`（`7db8a3331fe485d61cec1aeaa3bcaee94e13344a`，8 commits 含对齐提交） |
| 回执提交 SHA | `5e204ce`（交接仓库 PR #146 回执提交，已合入 main `373de34`；回执分支 `4738ec4` 已同步实施头 `7db8a33`，main 版回执待同步合入） |
| PR 号 | CoderClub PR #20——**已合入 main（merge `8cfb40b0`，2026-08-31，B-Review 复核通过后执行授权合入）** |
| R2 状态 | **实施 R2 达成**（已合入 CoderClub main，main tip 核验 `8cfb40b0`）；本签署随交接仓库流程合入 main |

## 4. 延后项与观察项（打包转 PM 验收，不阻塞）

| # | 项 | 处置标注 |
| --- | --- | --- |
| 1 | `sensitive_words.type` DEFAULT 0 vs 领域 1/2 | PM 已裁决（种子均 1/2，默认 1 需另议），随签登记 |
| 2 | 回执文档 main 版实施头仍 `1f35e2b`（分支已同步 `7db8a33`） | 随本签署批次或后续提交同步合入 main |
| 3 | DEPLOYMENT.md 仍记旧 ENTRYPOINT 形态 | AGENTS/CLAUDE 已同步，DEPLOYMENT.md 后续同步（非阻塞） |
| 4 | 种子 type2 `to_id` 严格语义细节（"感谢支持"行） | SQL 注释简化表述，PM 可后续收紧（可选） |
| 5 | `SubjectBriefEntity.subjectId` Long 溢出语义未钉 | 现实不可达，可选测试延后 |
| 6 | `ShareCommentReplyEntity.id` 字段注释残留旧「复合主键」表述（[仅供参考]） | 既有遗留，后续注释统一批次顺手修正 |

## 5. 关联

- 任务书 · 数据依据 SQL PR #140 · 回执 PR #146 · 实施 CoderClub PR #20（merged `8cfb40b0`）
- 后续：回执文档同步合入 main → PM 验收（openFindings 已裁决）→ 阶段四 interview 服务任务（interview 3 表实体随服务落地）

签署：后端评审（B-Review），2026-08-31
