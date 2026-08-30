# 阶段三配套（A8-P3-COMPA）——后端评审复核签署

> 角色：后端评审（B-Review）
> 签署日期：2026-08-30
> 任务书：`pm/requirements/2026-08-30/phase3-companion-implementation-task.md`（PR #102 批次）
> 提案/决策：`proposals/backend/2026-08-30/phase3-companion-x1-vo-amendment-proposal.md`（① V1-V4）、`phase3-companion-notrole-mapping-proposal.md`（② N1-N3）——PR #101（R2 main）；`pm/reviews/2026-08-30/phase3-companion-proposals-decision.md`
> 回执：`handoff/backend-to-frontend/2026-08-30/backend-a8p3-companion-report.md` + `-summary.json`（PR #103，head `d4004ebc`，已合入 main `59831bc`）
> 工作底稿：`designs/backend/2026-08-30/a8p3-companion-review-workpaper.md`
> 状态：**签署通过，转 PM 验收**

## 1. 复核结论

✅ **复核通过，签署本回执。** 实施 `8649eba`（CoderClub PR #16，**7 commits**——回执头"8 提交"笔误随签署勘误，其自身分解即 7）经人链核验与独立复验与提案/决策相符：

- [x] **任务 1（提案① V1-V2）**：`IdentifierUserItemVO` 增 `id` 4 副本同构（auth 源 + circle/practice/subject api 逐文件核验）；**auth 控制器 setId 必然项**（`AuthUserController:85`，手工组装无转换器——提案字面外实现项，PM 决策已认可，复核确认）；circle/practice 双键别名各 +1 行（id 键优先 + null 守卫，**查找侧零改动**实读确认）
- [x] **任务 2（提案② N1-N2）**：subject/practice `NotRoleException → 403` 与既有权限映射及 circle X3 先例**逐字同形态**（`FORBIDDEN` + "无权限访问"）；防御性同步边界（零角色注解端点 / 9 个权限注解端点既有链路未触碰）
- [x] **任务 3（PM 授权）**：源文档 `IdentifierUserItem` schema `required=["id"]` + `info.description` 修正——**与快照 DAAEECB7 的 description 字节级一致（`-ceq` True）**；LF SHA `736F6588→BF59FECD`（`git show` 独立计算，逐字一致）；74 路径不变
- [x] **独立复验（本会话实跑）**：全量 `mvn install -DskipTests` exit 0；5 模块定向测试零失败——subject **102/102**（含 403 handler 用例）、auth **46/46**（含 id 断言）、practice **29/29**（含 `@ResponseStatus` 断言）+ domain 40/40（含数字 loginId 真实昵用例）、circle domain **41/41**（含 `AuthUserDirectoryTest` **5/5**）
- [x] **边界遵守**：X1 查询层（auth domain/infra）零改动（diff 文件清单核实）；auth 仅控制器 + VO + 测试 3 文件；contribute 未动；`api/` 快照与 `sync-manifest` 未动（快照 DAAEECB7 零漂移）；无 DDL/新依赖

## 2. 规则 9 完成通知四字段（自检）

| 字段 | 值 |
| --- | --- |
| 实施提交 SHA | `8649eba`（`8649eba468ac97577acb2de5cfc0a5e30155488e`，7 commits） |
| 回执提交 SHA | `d4004ebc`（PR #103 head，已合入 main `59831bc`） |
| PR 号 | CoderClub PR #16——**已合入 main（merge `b15a735`，2026-08-30，B-Review 复核通过后执行授权合入）** |
| R2 状态 | **实施 R2 达成**（已合入 CoderClub main）；本签署随交接仓库流程合入 main |

## 3. 已知限制与观察项（打包转 PM 验收，不阻塞）

| # | 项 | 处置标注 |
| --- | --- | --- |
| 1 | 键碰撞边界（userName 恰等他人 id 串，id 键优先依赖插入顺序） | 提案① §5 已登记；如需顺序无关可两次遍历收严——本批不扩，维持登记 |
| 2 | 规格追溯缺口：CircleContractTest mock 补 id 收窄为 domain 层等价覆盖（AuthUserDirectoryTest + 三链路用例） | 回执 §5.2 已如实登记，无行为风险，知悉 |
| 3 | `IdentifierUserItem` schema 类级 description「（仅展示信息）」措辞略失准 | **随 PM 快照微同步一并修正**（回执 §5.3 建议） |
| 4 | 快照微同步（`IdentifierUserItem.id` 采纳 + description 差异消除，语义差异预计 11→10） | PM 验收批次执行 |
| 5 | 后端仓库本机 worktree 现停于 `8649eba`（detached，B-Impl 遗留；R2 已合入不影响远端） | 由用户酌情切回 main |

## 4. 关联

- 任务书 PR #102 · 提案 PR #101 · 决策（V1-V4/N1-N3）· 回执 PR #103 · 实施 CoderClub PR #16（merged `b15a735`）
- 后续：PM 验收 → 快照微同步（id 采纳 + description 差异消除，语义差异 11→10）→ 阶段三完全闭环（前端任务书衔接）

签署：后端评审（B-Review），2026-08-30
