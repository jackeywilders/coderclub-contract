# 回执：阶段三配套实现（A8-P3-COMPA：X1 消费侧 VO 增补 + NotRoleException 映射同步）

> **回执角色：** 后端实现（B-Impl）
> **日期：** 2026-08-30（Asia/Shanghai）
> **任务书：** `pm/requirements/2026-08-30/phase3-companion-implementation-task.md`（验收批 PR #102）
> **提案：** `proposals/backend/2026-08-30/phase3-companion-x1-vo-amendment-proposal.md`（① V1-V4）、`phase3-companion-notrole-mapping-proposal.md`（② N1-N3）——同批 PR #101，R2 main
> **PM 决策：** `pm/reviews/2026-08-30/phase3-companion-proposals-decision.md`
> **设计/计划：** 后端仓库 `docs/superpowers/specs/2026-08-30-a8p3-companion-design.md`、`docs/superpowers/plans/2026-08-30-a8p3-companion-plan.md`

## 1. 来源与提交哈希

| 项 | 值 |
| --- | --- |
| 实现仓库 | jackeywilders/coderclub（后端） |
| 分支 | `feat/backend-a8p3-companion`（基于 A8-P3 合入基线 `583b4bb`） |
| 实现头 | `8649eba`（8 提交：spec + plan + 4 实现/文档 + 1 最终审查修复波） |
| PR | **#16**（feat/backend-a8p3-companion → main） |
| CI | `build-and-test` ✅ + `sensitive-scan` ✅（run 33293974452 首推；修复波重跑 33295007263 双绿） |
| 合入状态 | **R1 达成**（远端分支/PR 可见）；R2 待人工合入（用户/后端评审在 CI 全绿后执行） |

## 2. 三任务明细（对照任务书 §1-§3 逐条）

### 任务 1：提案①（X1 消费侧 VO 增补）

- `IdentifierUserItemVO` 新增 `id: Long`（javadoc 注明主键/required 语义/4 副本同构），**4 副本**：auth 源（`com.jackey.auth.app.entity`）+ circle-api（`com.jackey.circle.api.res`）+ practice-api（`com.jackey.practice.api.res`）+ subject-api（`com.jackey.res`）——字段块逐字同构（最终审查聚焦核验）。
- **实现必然项（提案字面未列，回执注明）**：auth 控制器 `listByIdentifiers` 为手工组装（无转换器），补 `vo.setId(u.getId())`——缺此行 `id` 恒为 null、required 语义不成立（AuthUserBO 已有 id 字段，零 BO 改动）。
- 消费方双键别名各 +1 行（null id 守卫 + `map.putIfAbsent(String.valueOf(u.getId()), u)` 置于 userName 键之前，id 键优先；查找侧零改动）：circle `AuthUserDirectory.fetch`、practice `PracticeDetailDomainServiceImpl.fetchUserMap`。

### 任务 2：提案②（NotRoleException 映射同步）

- subject / practice 两个 `GlobalExceptionHandler` 各增 `handleNotRole`：`@ExceptionHandler(NotRoleException.class)` + `@ResponseStatus(HttpStatus.FORBIDDEN)` → `fail(FORBIDDEN.getCode(), "无权限访问")`——与既有权限映射及 circle X3 先例**逐字同形态**（三服务 403 文案一致，审查实测核验）。
- 防御性同步（N2）：两服务当前零 `@SaCheckRole` 端点；9 个 `@SaCheckPermission` 端点的既有 `NotPermissionException` 链路不受影响。

### 任务 3：源契约文档更新（PM 授权）

- `IdentifierUserItem` schema 增 `id`（integer/int64 + 语义 description）并设 `"required": ["id"]`；`/auth/user/list-by-identifiers` description 追加「返回条目含 auth_user 主键 id（响应增字段，向后兼容）」。
- `info.description` 整段修正为快照 DAAEECB7 同款措辞（「10 大模块共 74 个路径 74 个操作（…A8-P3 登记 circle 圈子 11 端点…）」）——**与快照逐字一致经审查断言核验**，源-快照 description 差异归零。
- **LF SHA before/after：`736F65886FC60E758AF6AB2F1C306BF47259CBEFACF69AC94FA032C567753225` → `BF59FECD7DA3A97BBC86CA589AA2D0E21CCD450444A63CE82B8AD040E49382B4`**（提交 `f11db3d` 正文含完整链）；74 路径不变。

## 3. 测试证据

- 全仓 `mvn install -DskipTests` + `mvn test` 绿；CI 双绿（run 33295007263，head `8649eba`）。
- 新增/增强用例：AuthContractTest `$.data[0].id` 断言（auth 46/46）；**AuthUserDirectoryTest 新建 5 用例**（id 键/userName 键/未命中降级/null id 跳过/碰撞 id 键优先）；circle 三链路 id 键解析用例（moment getMoments / comment fromNickName / message fromNickName；circle domain 41/41）；practice `rankList_shouldResolveRealNickname_forNumericLoginId`（提案① §4 验收项：数字 loginId → 真实昵称，A8-P2 已知限制闭环；practice 29/29）；subject/practice 403 handler 单测（subject 102/102，含 `@ResponseStatus` 注解断言——最终审查修复波补齐，定向复验 ADDRESSED）。
- 审查链：spec/计划双自检 → 内联 TDD（每任务 RED→GREEN→commit）→ 全分支最终审查（1 Important 修复波 + 定向复验；3 Minor 延后登记见 §5）。

## 4. 边界遵守声明（任务书 §5）

- X1 查询层（auth domain/infra）零改动；auth 服务仅触控制器 VO 组装一行；contribute nickMap 未动（V4 后续排期）；不为既有端点叠 `@SaCheckRole`（N3）；`api/` 快照与 `sync-manifest` 未动；74 路径无结构差异；无 DDL；无新依赖。

## 5. 已知限制与延后项

1. **键碰撞边界**（userName 恰等他人 id 串）：提案① §5 已登记，概率可忽略；当前「id 键优先」依赖双键插入顺序（putIfAbsent 不覆盖），若将来需顺序无关可两次遍历收严——提案登记在案，本批不扩。
2. **规格追溯缺口（登记）**：规格 §2.3 的「CircleContractTest mock 数据补 id」在计划/实现中收窄为 domain 层 AuthUserDirectoryTest + 三链路用例（等价覆盖，无行为风险）。
3. `IdentifierUserItem` schema 类级 description「（仅展示信息）」措辞已略失准（现含主键）——随 PM 快照微同步一并修正。
4. subject/practice 防御性 403 无自然触发端点（N2 既定），单测为直接 handler 调用 + 注解存在性断言。

## 6. 后续链

1. B-Review 复核签署 → PM 验收 → **快照微同步**（`IdentifierUserItem.id` 采纳 + description 差异消除，语义差异预计 11→10）→ 前端阶段三任务书衔接。
2. 合入提醒：PR #16 CI 双绿，**合入由人工（用户/B-Review）在 GitHub 执行**。

---
- 回执角色：后端实现（B-Impl），2026-08-30
