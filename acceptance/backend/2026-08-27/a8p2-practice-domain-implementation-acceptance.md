# PM 验收：A8 阶段二 practice 练题域后端（A8-P2-BE）+ 快照全链同步

> 角色：协调 PM
> 验收日期：2026-08-28
> 任务书：`pm/requirements/2026-08-27/phase2-practice-implementation-task.md`（PR #82）
> 提案/决策：PR #81 / `pm/reviews/2026-08-27/phase2-practice-endpoints-proposal-decision.md`（C5-C7/G1/D0）
> 回执：`handoff/backend-to-frontend/2026-08-27/backend-a8p2-practice-domain-report.md` + `-summary.json`（PR #84）
> 复核签署：`acceptance/backend/2026-08-27/a8p2-practice-domain-review-signoff.md`（B-Review）
> 状态：**验收通过；快照全链同步完成（+17，46→63 路径，语义差异 21→38）**

## 1. 验收依据（规则 9 远程核验）

- R1/R2：回执（PR #84）+ 签署均已合入交接 main；实施 CoderClub PR #14（open 未合入，CI 全绿——合入由用户/后端评审执行，同 A2/A5 先例；验收以人链 + CI + 云端验证（实施分支本地运行连云端中间件经网关）为依据）
- 四字段：实施 `a57f6b8a`（25 commits）｜ 回执 `c24b51e3` ｜ PR #14/#84 ｜ R2 回执侧合入

## 2. 验收标准逐项（对照任务书 §5，全绿）

| 项 | 证据 | 结论 |
| --- | --- | --- |
| 17 端点（internal 4 + practice 13） | 路径逐一登记（源文档 17/17）；模块四层结构 | ✅ |
| 判分唯一实现 | `AbstractSubjectTypeHandler.judgeSubject` 扩展 + 4 Handler + Factory（practice 无复制判分，源码级验证） | ✅ |
| 硬条件 | 交卷先补差集再算率（InOrder 断言 + 云端 rate=27.27 简答剔除）；submitSubject 幂等 + 交卷后 400 守卫；全 Feign 无直连；越权防护（6 端点 requireOwnedPractice） | ✅ |
| C5-C7/G1/D0 | withAnswer 通路 / 内存聚合星级 / 简答不计分不进分母 / giveUp / 无 DDL | ✅ |
| 测试 | **1028 例全量绿**（SubjectContractTest 71/71 不回归、PracticeContractTest 22/22） | ✅ |
| 源文档 | 46→63 路径；LF SHA `BA74B152…` → `9EC37C66…`（B-Review 复核逐字一致）；既有 46 路径语义零变更（程序化深度对比，仅既有脱敏例差异） | ✅ |
| 云端/网关联调 | 预留域转实；I1-I4 真实 SQL/Feign；全状态机（建卷→四题型作答→交卷→报告/星级→明细→排行→giveUp→守卫 400/401） | ✅ |

## 3. 快照全链同步（本验收完成）

- **源**：`docs/api/coderclub-openapi.json`（实施提交 `a57f6b8a`，PR #14 open 待合入）LF SHA `9EC37C66571E40745732880309EEB231E7DC7C67C21F37BC466059C1F9959D4D`
- **快照**：`api/coderclub-openapi.json` 同步 +17 路径（practice 13 + subject internal 4）+ 46 schema → **63 paths / 96 schemas**；LF SHA `4BFB3C72…` → `2583B90679ED990DB8BC11BA9EED0FCCBF0AF3DBEDFF8B84CDA35159F0B05C01`（快照更新提交 `PENDING` 回填）
- **语义差异**：21 → **38**（+17：13 practice C 端 + 4 internal）；pathCount/operationCount 63
- `status/pm.json` 与 `status/sync-manifest.json` contractSnapshot 全链同步（同批提交）

## 4. SAP 观察项处置（登记跟进，不阻塞）

| 观察项 | 处置 |
| --- | --- |
| practice_detail 无唯一索引（并发二行窗口，防御已兜底） | openFinding 登记：后续 proposal 评估补 `uk(practice_id, subject_id)` |
| 双套 PageInfo 架构债 | openFinding 登记：单独立项收敛（common/subject-common 合一套） |
| docker 容器级冒烟（本机无 Docker） | 验收补充项：有 docker 环境后全栈冒烟（README §12） |
| 排行昵称回退（数字 loginId 场景） | [仅供参考]：前端阶段二可优化（消费端展示 userName 或后续 practice 侧存 userName） |

## 5. 验收结论与后续

- **验收通过**：A8 阶段二后端（practice 域 + internal 端点）闭环；网关链路全通。
- 实施 PR #14 未合入 CoderClub main——**请用户/后端评审执行合入**（CI 全绿，R2 后源 commit 更新）。
- **后续**：前端阶段二任务书（F-Impl：练习列表/答题页/分析报告 + 「简答不计分」展示 + 练习榜启用）→ 回执 → 签署 → 验收（阶段二整体收尾 + state 推进）。
- state 保持 `gate3-a8-phase1-accepted`（阶段二前端未完成，收尾时推进）。

## 6. 关联

- 提案 PR #81 · 决策 `pm/reviews/2026-08-27/phase2-practice-endpoints-proposal-decision.md` · 签署 `acceptance/backend/2026-08-27/a8p2-practice-domain-review-signoff.md`
- 并行：GW-1 验收（`acceptance/backend/2026-08-27/gw1-gateway-implementation-acceptance.md`）
- 本验收：`acceptance/backend/2026-08-27/a8p2-practice-domain-implementation-acceptance.md`

验收：协调 PM，2026-08-28