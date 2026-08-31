# 数据库数据依据落地（DATABASE-INIT-LANDING）——PM 验收

> 验收角色：协调 PM
> 验收日期：2026-08-31
> 回执：`handoff/backend-to-frontend/2026-08-31/backend-database-init-landing-report.md` + `-summary.json`（PR #146，已合入 main）
> 复核签署：`acceptance/backend/2026-08-31/backend-database-init-landing-review-signoff.md`（PR #149，merged，MCP 核验；工作底稿 `designs/backend/2026-08-31/`）
> 状态：**验收通过**

## 1. 验收结论

✅ **DATABASE-INIT-LANDING 验收通过。** 实施 head `7db8a33`（8 commits，经 CoderClub PR #20 合入 main `8cfb40b0`）经 B-Review 复核签署（PR #149）与 PM 独立核验，与任务书 `pm/requirements/2026-08-31/database-init-landing-task.md`（L1-L5）相符——数据依据 SQL 落盘、实体核验/注释统一、README 数据说明、部署 JVM 预算落地。

## 2. 规则 9 核验链（四字段）

| 字段 | 值 |
| --- | --- |
| 实施提交 SHA | `7db8a33`（最终 head，8 commits 含对齐修正；回执登记的 `1f35e2b` 为合入前 tip，B-Review 注记已说明） |
| 合并提交 SHA | `8cfb40b0`（CoderClub PR #20 merge，2026-08-31T16:15:44Z） |
| 回执提交 SHA | `373de34`（PR #146，已合入 main；`receiptCommitSha` 已填） |
| PR 号 | CoderClub #20（merged `8cfb40b0`）；交接仓库回执 #146、签署 #149（merged） |
| R2 状态 | ✅ 双达成：实施合入 CoderClub main（HEAD=`8cfb40b0`）；回执/签署均合入交接仓库 main |

## 3. PM 独立复核（非签署转录）

1. **后端远端实测（MCP）**：CoderClub main HEAD = `8cfb40b0`（PR #20 merge），R2 生效性确认。
2. **对齐闭环确认**：B-Review 复核发现落地副本/实体注释与 PM 裁决后权威 `478ed4a` 不一致 → 用户裁决先对齐再合入 → B-Impl 追加 `7db8a33` → **落地副本与权威逐字节一致**（SHA `6AB9F81C…` 独立重算）——to_id/parent_id 以运行口径（momentId/-1）对齐闭环。
3. **内容核验**：L1 SQL 落盘（26 表/707 种子，删旧 3，与权威 LF 一致）；L2 `SubjectBriefEntity.subjectId` Integer→Long（连带 BriefTypeHandler + 测试）；L3 README（测试账号/种子/interview_keyword/旧表重建/type 口径/JVM 预算）；L5 5 Dockerfile + compose JVM 预算（256m/384m 分组）——与任务书及 JVM 预算表一致。
4. **快照零变更**：本批为数据依据/实体/部署层落地，**无契约端点变化**——快照 `74417DD8` 零变更。

## 4. openFindings 处置（PM 裁决登记）

| finding | 处置 |
| --- | --- |
| `share_comment_reply.to_id/parent_id` 写路径差异 | **裁决：以运行口径为准**（to_id=momentId、parent_id=-1，A8-P3 已验收语义）；代码不动，**数据依据已修正对齐**（PR #147：注释 + 种子） |
| `sensitive_words.type` 默认 0 | 登记（领域校验 1/2，种子均 1/2，默认仅防漏） |
| DEPLOYMENT.md 漂移 | 后续同步（不阻塞） |

## 5. 小瑕疵/待办登记（不阻塞）

| 项 | 说明 |
| --- | --- |
| 回执实施头待同步 | main 版回执 `implementationCommitSha` 仍 `1f35e2b`，B-Review 分支已同步 `7db8a33`——**提请 B-Impl 同步合入**（回执修正） |

## 6. 后续

1. **interview 服务任务**：interview 3 表实体随服务落地（第三批，`coder-club-interview`）。
2. 第二批四线（subject-search/redis/r2/D2）并行推进；D2 已回执（PR #148）待 R2 + 签署。
3. 阶段四快照微同步批次：interview 端点（75→83）+ D2 isRead（字段采纳）合并执行。

---

验收人：协调 PM，2026-08-31
