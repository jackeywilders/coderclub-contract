# PM 验收：A8 阶段一后端 3 门户端点实现（A8-P1-BE）

> 角色：协调 PM
> 验收日期：2026-08-27
> 任务书：`pm/requirements/2026-08-26/backend-phase1-portal-endpoints-implementation-task.md`（PR #69）
> 决策：`pm/reviews/2026-08-26/portal-phase1-search-contribute-proposal-decision.md`（PR #68，C1-C4）
> 回执：`handoff/backend-to-frontend/2026-08-26/backend-a8-phase1-endpoints-report.md` + `-summary.json`（PR #70）
> 复核签署：`acceptance/backend/2026-08-26/a8-phase1-endpoints-review-signoff.md`（B-Review，PR #71）
> 状态：**验收通过，A8 阶段一后端闭环；快照全链同步完成（+3 语义差异，18 → 21）**

## 1. 验收依据（规则 9 远程核验）

| 层级 | 判定对象 | 证据 | 结论 |
| --- | --- | --- | --- |
| R1 | 回执双轨 + 签署文件远端可见 | `handoff/.../backend-a8-phase1-endpoints-*`、`acceptance/backend/2026-08-26/a8-phase1-endpoints-review-signoff.md` 均在 main | ✅ |
| R2 | 回执（PR #70）、签署（PR #71）、决策（#68）、任务书（#69）均合入交接 main；实施 CoderClub PR #12 merged（merge `7ed442e`，main 顶端核验） | API 通道核验 | ✅ |
| 四字段 | 实施 head `ceaffe4`（8 commits，含修复轮）、回执 tip `f435699`、PR #12/#70/#71、R2 已合入 | summary + 签署一致 | ✅ |

## 2. 验收标准逐项核对（对照任务书 §5）

| 要求 | 证据 | 结论 |
| --- | --- | --- |
| 3 端点按决策语义实现 | search（`@NotNull` + C4 空串空页 + `subject_name` 单列 LIKE + distinct + VO AutoMapper 修复轮）、contribute（C3 `created_by` 分组 + topN 归一 + Feign nickName 降级 userName）、auth list-by-identifiers（≤100 + 空数组 `[]` 不 400） | ✅ |
| 回归 + 新用例 | SubjectContractTest **57/57**、AuthContractTest **12/12**（含 `ceaffe4` 补 401/@Size 用例；回执称 10/10 为签署时点前口径）、全量 mvn test exit 0 | ✅ |
| 源文档登记 | 3 路径 + 9 schema；LF SHA `A8C6A460…` → `BA74B152…`（PM 本地复核一致） | ✅ |
| 未改快照/sync-manifest；未动其他端点/表结构/索引 | 声明 + B-Review 边界核对 | ✅ |
| 回执双轨 + 四字段 | 双轨落 `handoff/backend-to-frontend/2026-08-26/`（PR #70）；通知字段齐 | ✅ |

## 3. 备注处置（B-Review 签署 §4 / 用户转述，[仅供参考] 不阻塞）

| 备注 | 处置 |
| --- | --- |
| 回执 summary `implementationCommitSha=c4e1efb` 未含最终 tip `ceaffe4` | 验收以最终实施 head **`ceaffe4`** 为准（PK 人链已核验；summary 保留初版不补正，同 A2/A5 先例）；状态文件与快照同步记录按 `ceaffe4` |
| 回执称 Auth 10/10，实为 12/12 | 覆盖更全，非实质差异；验收记录以 12/12 为准 |
| topN 归一边界无专属单测 | 云端真实验证时补充（见 §4） |

## 4. 已知限制（云端验证，验收后跟进）

- groupBy/search SQL 真实执行、subject→auth Feign 跨服务真实联调、401 端到端体验、topN 边界——按 A2/A5 先例，云端环境（`CODER_CLUB_TEST_*` 凭据已就绪）补充真实请求验证（验收后由 B-Impl/用户执行），验证结果随后续任务回执。

## 5. 快照全链同步（本验收完成）

- **源**：`docs/api/coderclub-openapi.json`（CoderClub main `7ed442e`，实施提交 `ceaffe4`）LF SHA `BA74B152730A2F532A8118C18F20AB395CCD4AEA04DB672A17120833705493B1`
- **快照**：`api/coderclub-openapi.json` 同步 +3 路径（`/subject/getSubjectPageBySearch`、`/subject/getContributeList`、`/auth/user/list-by-identifiers`）+ 9 schema；46 paths / 50 schemas；LF SHA `8EBCDA53…` → `4BFB3C72A44550EBD6BAA9F37CC455CE760AEDC88F534453B9451EB4CABA715E`
- **语义差异**：18 → **21**（+3 A8 阶段一门户端点，无结构/安全破坏）
- `status/pm.json` 与 `status/sync-manifest.json` contractSnapshot 全链同步（同批提交）

## 6. 验收结论与后续

- **验收通过**：A8 阶段一后端闭环。前端门户化可据快照（46 端点）开发。
- **state**：保持 `gate3-a2-impl-accepted`（阶段一整体未完成，前端门户化后统一评估推进）。
- **后续**：前端门户化任务书（F-Impl）→ 回执 → 验收 → 云端真实验证补充。

## 7. 关联

- 任务书 `pm/requirements/2026-08-26/backend-phase1-portal-endpoints-implementation-task.md`（PR #69）；决策（PR #68）；提案（PR #67）；签署 `acceptance/backend/2026-08-26/a8-phase1-endpoints-review-signoff.md`（PR #71）
- 本验收：`acceptance/backend/2026-08-26/a8-phase1-endpoints-implementation-acceptance.md`

验收：协调 PM，2026-08-27