# A8 阶段二 practice 练题域（A8-P2-BE）——后端评审复核签署

> 角色：后端评审（B-Review）
> 签署日期：2026-08-28
> 任务书：`pm/requirements/2026-08-27/phase2-practice-implementation-task.md`（PR #82）
> 提案/决策：`proposals/backend/2026-08-27/phase2-practice-endpoints-proposal.md`（PR #81）、`pm/reviews/2026-08-27/phase2-practice-endpoints-proposal-decision.md`（C5-C7/G1/D0）
> 回执：`handoff/backend-to-frontend/2026-08-27/backend-a8p2-practice-domain-report.md` + `-summary.json`
> 工作底稿：`designs/backend/2026-08-27/gw1-a8p2-review-workpaper.md`（§3/§4 A8-P2 部分）
> 状态：**签署通过，转 PM 验收**

## 1. 复核结论

✅ **复核通过，签署本回执。** 实施 `a57f6b8a`（CoderClub PR #14，open 未合入，CI 全绿）经人链核验与独立复验与提案/决策相符：

- [x] **17 端点完整**：subject internal 4（I1 随机抽题/I2 类目计数/I3 批量取题/I4 判分）+ practice 13（P0 答题链 8 + P1 报告/排行 4 + giveUp 1）；路径逐一登记（source doc 17/17）
- [x] **判分唯一实现**：`AbstractSubjectTypeHandler.judgeSubject` 扩展 + 4 Handler（radio/multiple 集合相等比对、judge 布尔、brief `judgeable=false`）；`buildStandardAnswer` 标准侧唯一；Factory 分发
- [x] **硬条件锁定**：交卷**先补差集再算率**（InOrder 断言、分母剔除简答）、submitSubject **update-or-insert 幂等** + **交卷后禁止提交 400 守卫**、**全 Feign 不直连 subject 表**、越权防护（requireOwnedPractice 覆盖 6 端点）
- [x] **C5/C6/C7/G1/D0**：getSubjectDetail I3 withAnswer=true；报告标签聚合→星级；简答不进分母；giveUp 软删；DDL=无
- [x] **契约登记**：46→63 路径 +17；既有 46 路径语义零变更；`contractSnapshotSha256=4bfb3c72` 零漂移
- [x] **独立复验**：SubjectContractTest **71/71** + PracticeContractTest **22/22**，BUILD SUCCESS
- [x] **源文档 SHA**：LF `BA74B152…93B1 → 9EC37C66…9D4D` 与回执逐字一致
- [x] 云端/网关联调（原预留 503→可达；I1-I4 真实 SQL/Feign；全状态机 addPractice→submit→report rate=27.27→rank→giveUp→守卫 401）——回执声明 + CI + 复验佐证

## 2. 规则 9 完成通知四字段（自检）

| 字段 | 值 |
| --- | --- |
| 实施提交 SHA | `a57f6b8a`（`a57f6b8ae7142a8c4b1e5cfbc32b8936af297dfc`，25 commits 含 final-review） |
| 回执提交 SHA | `c24b51e3`（summary 记录） |
| PR 号 | CoderClub PR #14（open 未合入 main，CI 全绿） |
| R2 状态 | 回执已合入交接仓库 main；实施 PR #14 未合入 CoderClub main（合入由用户/后端评审执行） |

## 3. SAP 观察项（打包转 PM/验收，不阻塞）

- **docker 容器冒烟**：本机无 Docker → 容器级实证（Dockerfile.practice 全 27 pom、compose +practice 段）列为验收补充（README §12）；mvn 层复验本会话已完成。
- **practice_detail 唯一索引**（D0 人类裁定保持无 DDL）：submitSubject update-or-insert 低概率并发二行窗口，防御 putIfAbsent/distinct 兜底——后续可经 proposal 评估补 `uk(practice_id, subject_id)`。
- **双套 PageInfo 架构债**：common 与 subject-common 各一（practice 用 common 版）——单独立项收敛，不随本任务。
- [仅供参考] 排行昵称回退：`practice_info.created_by` 存 loginId（数字），list-by-identifiers 按 userName 不命中回退 userName——契约 fallback 设计，前端阶段二可优化。

## 4. 关联

- 任务书 PR #82 · 提案 PR #81 · 决策 C5-C7/G1/D0 · 实现计划 `docs/superpowers/plans/2026-08-27-a8-p2-practice-domain-plan.md`
- 并行：GW-1（PR #13 已合入）· 验收：PM 快照全链同步 +17（46→63 路径）
- 本签署：`acceptance/backend/2026-08-27/a8p2-practice-domain-review-signoff.md`

签署：后端评审（B-Review），2026-08-28