# 回执：MomentItemVO 补 fromId 实现（B-Impl 小批次）

> **回执角色：** 后端实现（B-Impl）
> **日期：** 2026-08-30（Asia/Shanghai）
> **任务书：** `pm/requirements/2026-08-30/moment-item-fromid-implementation-task.md`（已派发）
> **提案：** `proposals/frontend/2026-08-30/moment-item-fromid-proposal.md`（PR #111，R2 main `b07ea765`）；PM 决策 `pm/reviews/2026-08-30/moment-item-fromid-decision.md`（PR #114，确认建议方案）
> **设计/计划：** 后端仓库 `docs/superpowers/specs/2026-08-30-moment-item-fromid-design.md`（da9c112）、`docs/superpowers/plans/2026-08-30-moment-item-fromid.md`（1177c4e，随本 PR 合入）

## 1. 来源与提交哈希

| 项 | 值 |
| --- | --- |
| 实现仓库 | jackeywilders/coderclub（后端） |
| 分支 | `feat/backend-moment-fromid`（基于 `8617d9d` = 敏感词 list PR #17 合入后 main，75 路径基线） |
| 实现头 | `1fbf0ad`（6 提交：spec + plan + VO/组装实现 + 判别性断言修复 + openapi 登记 + 最终审查文档同步） |
| PR | **#18**（feat/backend-moment-fromid → main） |
| CI | `build-and-test` + `sensitive-scan`（run 33323104704；head `1fbf0ad`，双绿核验后转人工合入） |
| 合入状态 | **R1 达成**；R2 待人工合入（用户/B-Review 在 CI 全绿后执行） |

## 2. 任务明细（对照任务书 §1 五项 + 提案 D3 建议方案 + PM 决策）

1. **VO** ✅：`MomentItemVO` 补 `fromId: string`——语义 = **动态创建人登录标识**（与 `CommentNodeVO.fromId` 同源：save 时 `StpUtil.getLoginIdAsString()` 写入 `created_by` 的登录标识串）；供前端「本人动态」精确判定（`fromId === String(当前用户 id)`）。字段插入 `nickName` 之前；`MomentBO` 无同名属性 → 不参与 MapStruct 自动映射（与 `replyCount` 同类单向字段，生成期不报错）。
2. **组装** ✅：`ShareMomentController.getMoments` 转换处 `vo.setFromId(bo.getCreatedBy())` 手动补齐（与 `createdTime` 手动补齐先例同形态）——**取动态创建人**（`MomentBO.createdBy` 直取），**不取当前查看者登录标识**（任务书字面措辞歧义已向 PM 澄清：前端判定语义要求 fromId = 创建人）。域层零改动。
3. **契约测试** ✅：`CircleContractTest.getMoments_返回分页与epoch毫秒` 补 `fromId` 字段面断言——**判别性取值** `bo.setCreatedBy("2002")` + 断言 `"2002"`（与登录标识 `"2001"` 错开：若实现误取 `StpUtil.getLoginIdAsString()` 断言必然失败，核心约束由回归测试锚定）；既有 401/字段断言零回归。
4. **源契约文档** ✅：`MomentItemVO` schema 与 getMoments 200 example 双处登记 `fromId`（string，description 注明与 `CommentNodeVO.fromId` 同源语义、供前端本人动态判定）；**路径数不变（75）**；**LF SHA before/after：`24DC841402BB5E063758A4156FC3AAF8D84609845BC218D92D0DC8FE6C7DD82A` → `26AEC009C4A823629DCC1D6EB5984773791BC3380407F846AAA7D4308F12CC90`**。
5. **快照衔接** ✅：路径数不变（75），schema 字段级变更 → 快照微同步（`MomentItemVO.fromId` 采纳）由 PM 验收批次合并执行（与敏感词 list 微同步模式相同）；前端一行切换（移除 D3 昵称临时兜底）属后续 F-Impl 小批，不在本批范围。

## 3. 测试证据

- 全仓 `mvn install -DskipTests -q` + `mvn test` 绿（exit 0，15 测试模块零失败）；circle 契约 `CircleContractTest` 23/23（含判别性 fromId 断言），circle domain 全量零回归。
- 域层/其他端点/鉴权/错误码/`CommentNodeVO`/双键消费者零改动（diff 仅 3 个代码文件 + 2 个文档 + openapi 1 个文件）。
- 审查链：spec 自检 → 子代理驱动实现（任务 1+2 TDD RED→GREEN，任务审查 1 Important = 断言无判别力 → 修复轮 ADDRESSED；任务 3 openapi 审查 clean + 3 项 ⚠️ 协调者核查闭环）→ 全分支最终审查（最强模型：**可以合并**，无 Critical/Important；Minor 1 文档取值漂移修复 + 定向复审 ADDRESSED）。

## 4. 边界遵守声明（任务书 §3）

- 仅补 `fromId` 字段 + 组装；未触碰 `MomentItemVO` 既有字段、其他端点、鉴权、错误码；未动 `CommentNodeVO` 与双键消费者。
- 前端代码零改动；未改交接仓库 `api/` 快照与 `status/sync-manifest.json`（快照微同步由 PM 验收批次执行）。
- 规则 8 示例语义化；Conventional Commits（5 个实现/文档提交 + 1 个审查文档同步提交）。

## 5. 已知限制与延后项

1. **openapi schema 格式风格小项**（最终审查 Minor）：`fromId` 属性为多行展开格式，同 schema 相邻短属性为单行紧凑格式——纯风格差异，源自计划模板预设；后续 openapi 编辑批次可顺带压缩（延后登记）。
2. **CircleContractTest 真实 Converter 依赖**（任务审查 Minor 观察）：契约测试注入真实 MapStruct converter（非 mock），映射生成代码变化可能波及契约测试——既有测试套件形态，非本批引入；对契约测试而言真实映射更贴近运行时（维持观察）。
3. **openapi 200 example 值 `"2001"`**：与测试登录标识数值重合（示例展示值，与实现文件一致；非测试取值，测试已用判别性 "2002"）——表述性，不涉 schema 语义。

## 6. 后续链

1. B-Review 复核签署 → PM 验收 → **快照微同步**（`MomentItemVO.fromId` 采纳进快照，75 路径不变）→ F-Impl 小批（前端一行切换移除 D3 临时兜底）衔接。
2. 合入提醒：PR #18 CI 双绿，**合入由人工（用户/B-Review）在 GitHub 执行**。

---
- 回执角色：后端实现（B-Impl），2026-08-30
