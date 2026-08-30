# 任务书：阶段三配套实现（X1 消费侧 VO 增补 + NotRoleException 映射，B-Impl 小批次）

> 派发角色：协调 PM
> 派发日期：2026-08-30
> 执行角色：后端实现（B-Impl）
> 提案（已 PM 确认）：`proposals/backend/2026-08-30/phase3-companion-x1-vo-amendment-proposal.md`（任务 1）、`proposals/backend/2026-08-30/phase3-companion-notrole-mapping-proposal.md`（任务 2），同批 PR #101（R2 main）
> PM 决策：`pm/reviews/2026-08-30/phase3-companion-proposals-decision.md`（V1-V4 / N1-N3 全部确认）
> 批次：小批次——两提案单分支单 PR

## 1. 任务 1：提案① 实现（X1 消费侧 VO 增补）

按提案 §2/§3 逐条执行：

1. `IdentifierUserItemVO` 新增 `id: Long`（required 语义——auth 对每个命中用户恒返回主键），**4 处副本同构**：auth 源（`com.jackey.auth.app.entity`）+ circle-api / practice-api / subject-api 三份消费副本（javadoc「跨服务字段一致」约定保持）。
2. 消费方双键别名各 +1 行：circle `AuthUserDirectory`（`domain/support/AuthUserDirectory.java:44` 附近）与 practice `PracticeDetailDomainServiceImpl.fetchUserMap`（`:509` 附近）——`map.putIfAbsent(String.valueOf(u.getId()), u)`（id 键），保留既有 `putIfAbsent(u.getUserName(), u)`；**查找侧零改动**。
3. 测试：auth 契约测试 VO 结构回归（新增 `id` 断言）；circle/practice 消费方契约测试 mock 数据补 `id` 字段；401 与 Feign 失败降级路径（标识串兜底）零回归。
4. 验收口径 = 提案① §4：practice 综合练习榜数字 loginId 场景返回真实 nickName（A8-P2 已知限制闭环）；circle 动态列表/评论树/消息三处昵称生效；全模块测试绿。

## 2. 任务 2：提案② 实现（NotRoleException 映射同步）

按提案 §2 逐条执行：

1. subject / practice 两个 `GlobalExceptionHandler` 各增补一个映射：`@ExceptionHandler(NotRoleException.class)` + `@ResponseStatus(HttpStatus.FORBIDDEN)` → `ResponseResult.fail(ResultCodeEnum.FORBIDDEN.getCode(), "无权限访问")`——与两服务既有 `NotPermissionException` 映射及 circle X3 先例**逐字同形态**。
2. 单测：两服务各增 `NotRoleException → 403` 用例（响应体 `{success:false, code:403, message:"无权限访问"}`），对齐 circle 契约用例形态。
3. 验收口径 = 提案② §5：既有测试零回归（subject/practice 全模块）；交接仓库 `api/` 快照与 `status/sync-manifest.json` 不动；74 路径源文档无结构差异。

## 3. 任务 3：源契约文档更新（PM 授权）

1. `docs/api/coderclub-openapi.json`：`IdentifierUserItemVO` 增 `id`（Long，required）——提案① §2 的 OpenAPI 登记。
2. **PM 授权**：`info.description` 头部措辞 63→74 修正（消除上轮任务书冻结遗留）——改为与快照治理文案同款：「……覆盖认证、用户、角色、权限、分类、标签、题目、文件存储、练习、圈子 10 大模块共 74 个路径 74 个操作（A8-P2 登记 practice 13 端点 + subject internal 4 端点，A8-P3 登记 circle 圈子 11 端点；internal 端点仅内部 Feign 消费，不向 C 端门户宣传）……」，统一响应段与鉴权墙段保持快照同款（快照侧 `DAAEECB7` 已含该文案）。改后源-快照 description 差异归零。
3. 回执登记源文档 LF SHA before/after（before = `736F65886FC60E758AF6AB2F1C306BF47259CBEFACF69AC94FA032C567753225`）。

## 4. 交付与回执（规则 9）

1. 分支 `feat/backend-a8p3-companion` → CoderClub PR；CI 全绿后由用户/B-Review 合入（沿用仓库惯例，PM 不代合）。
2. 回执双轨：`handoff/backend-to-frontend/2026-08-30/`（Markdown 报告 + `*-summary.json`，落盘目录按创建日期；summary 模板字段齐全），完成通知四字段（实施 SHA / 回执 SHA / PR 号 / R2 状态）。
3. 快照衔接：实现合入后由 PM 做快照微同步（`IdentifierUserItemVO.id` 采纳 + description 差异消除，语义差异预计 11→10），随实现验收批次执行。

## 5. 约束

- 不改动提案范围外的端点/字段/鉴权/错误语义；X1 查询层（已就位）不动；auth 服务不触及（`auth-role-check-gap` openFinding 另案）；不为既有端点叠加 `@SaCheckRole`（提案② N3 边界）。
- 契约变更以本任务书引用的已确认提案为准，实现中如发现提案与运行时现实冲突，停手并交回 PM/B-Review，不自行决定。
- 敏感信息占位符约定（规则 8）与提交规范（Conventional Commits）照常。

## 6. 关联

- 提案 PR #101 · PM 决策 `pm/reviews/2026-08-30/phase3-companion-proposals-decision.md` · A8-P3-BE 回执 PR #97 · 复核签署 PR #100 · A8-P3 实施 CoderClub PR #15（merged `583b4bb`）
- 验收登记基线：快照 `DAAEECB7`（74 路径，语义差异 11）
