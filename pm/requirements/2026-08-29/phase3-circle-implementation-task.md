# 任务书：A8 阶段三后端实现（circle 新模块 11 端点 + 2 既有端点扩展）

> **派发角色：** 协调 PM
> **派发日期：** 2026-08-29
> **执行角色：** 后端实现（B-Impl）
> **复核角色：** 后端评审（B-Review）
> **提案：** `proposals/backend/2026-08-29/phase3-circle-endpoints-proposal.md`（PR #94）
> **决策：** `pm/reviews/2026-08-29/phase3-circle-endpoints-proposal-decision.md`（X1-X6/D0 已确认）
> **架构：** `docs/superpowers/specs/2026-08-27-a8-backend-architecture-direction.md` §7（Q6 消息落库拉取）
> **状态：** 与网关既有链路衔接（`/circle/**` 路由 GW-1 已预留，实现后转实）

## 1. 目标

实现阶段三社区域：新建 `coder-club-circle` 聚合模块（四层：api/app/domain/infra/starter，参照 practice；含 **SaInterceptor/角色解析注册使角色注解实际生效**）+ 11 个 C 端/管理端点 + 2 个既有端点向后兼容扩展；源文档登记（已批准，作实现一部分更新 `docs/api/coderclub-openapi.json`；交接仓库快照/sync-manifest 由 PM 验收后全链同步，**你不得修改**）。**无 DDL**（D0）；BOM 需新增 caffeine 版本管理。

## 2. 实施边界（仅以下范围，禁止扩大）

### 2.1 circle 新模块 11 端点（按提案 §3 逐一实现）

- **P0 圈子/动态/评论**（7）：circle/list（两层树 + Caffeine TTL 30s）、moment/save（敏感词校验 + circleId 必须子圈 + content/picUrlList 至少一项）、moment/getMoments（分页 + Feign 昵称头像降级）、moment/remove（仅本人 + 级联软删评论 + 幂等）、comment/save（replyType 语义 + 目标校验 + 敏感词 + 消息落库 from==to 不落 + reply_count 同事务 +1）、comment/list（树形全量 + fromIsMomentAuthor + 昵称头像批量一次 Feign）、comment/remove（本人或动态作者 + 子树批量软删 + reply_count 按实际更新条数回减 + 幂等）
- **P1 消息**（2）：message/unRead（Integer，只计数不改状态）、message/getMessages（分页 + content JSON 结构化展开 + 中性文案 + 返回后按页内 ids 批量置已读幂等）
- **P1 敏感词管理**（2）：sensitive/words/save + remove（**`@SaCheckRole("admin_user")` + circle 注册 SaInterceptor/roleKeys 解析器**，非管理员 403；幂等；成功后**同步重建 DFA** 立即生效）
- **硬条件**：
  1. 敏感词 DFA（Trie）：启动全量加载 `sensitive_words` + 管理端触发重建；发布/评论黑名单命中拒绝（400 业务错误）、白名单跳过
  2. 评论树：reply_type 1/2 语义 + TreeUtils 子树收集 + 计数一致性（同事务、按实际更新条数回减）
  3. 归属/幂等：动态删除仅本人；评论删除本人或动态作者；删除类重复调用幂等 true（条件更新不命中视为已删）；越权 400
  4. 消息：msgType COMMENT→动态作者 / COMMENT_REPLY→被回复人；from==to 不落；targetId=动态 id；读取即已读幂等
  5. 身份标识一律存 `StpUtil.getLoginIdAsString()`；昵称/头像经 Feign `list-by-identifiers`（X1 扩展后）读时组装，失败降级标识串（practice 先例）
  6. circle 注册 SaInterceptor + roleKeys 解析器（subject 先例）——角色注解实际生效（X3）

### 2.2 既有端点扩展（2，向后兼容）

- **X1** `POST /auth/user/list-by-identifiers`：identifiers 中**纯数字串**同时按 `id IN (...)` 匹配（`user_name IN OR id IN`）；非数字行为完全不变；请求/响应结构零变化（仅 OpenAPI 描述补充）
- **X2** `POST /subject/getSubjectPage`：请求体新增**可选** `primaryCategoryId`——后端展开（大类自身 + 直接子分类 id 集）经 `subject_mapping` 过滤（与 internal I2 同模式），与既有过滤叠加；缺省不生效

### 2.3 工程项

- `coder-club-circle` 加入根聚合 pom（`<modules>`）；BOM（`coder-club-dependencies`）新增 **caffeine** 版本管理；依赖 common/dependencies；分页复用 common 版 `PageInfo`/`PageResult`
- 网关 `/circle/**` 路由已预留（GW-1）——实现后转实验证

## 3. 禁止事项

- 不修改/删除任何现有端点、字段、鉴权、错误码语义（X1/X2 为提案确认的可选能力扩展，按 §2.2 边界）
- 不建表/不动 DDL；不改 `api/` 快照与 `status/sync-manifest.json` 及治理文件
- 不实现 WebSocket（Q6 决策 A 后置）；不实现圈子管理 CRUD（X6 另案）；不引入新依赖（caffeine 除外，BOM 管理）

## 4. 交付与回执（规则 9 双轨）

1. 实施提交推送后端仓库（Conventional Commits；circle 模块 / 2 扩展分提交或单 PR 由你定）。
2. 源文档 `docs/api/coderclub-openapi.json` 登记 11 新端点 + 2 扩展语义（已批准），LF SHA before/after 记录。
3. 回执双轨落 `handoff/backend-to-frontend/2026-08-29/`：Markdown（来源与提交哈希、11+2 端点明细、DFA/消息/评论树实现说明、测试证据、源文档 SHA、网关联调证据）+ `*-summary.json`（模板字段：`taskId=A8-P3-BE`、`contractSnapshotSha256=2583b906`（当前值，验收后 PM 更新）、`verificationResult`）。
4. 完成通知带四字段告知 B-Review 复核签署，签署后转 PM 验收。

## 5. 验收标准

- [ ] 11 端点按提案/决策语义实现（含 DFA 立即生效、消息落库拉取幂等、评论树计数一致、归属校验、Caffeine 缓存）
- [ ] X1/X2 扩展落地且向后兼容（既有用例不回归；X2 缺省不生效用例）
- [ ] circle 角色注解实际生效（非管理员 403 用例）
- [ ] 测试：**CircleContractTest 新建**（11 端点：树/发布/列表/删除/评论/回复/消息/未读/敏感词管理/403/401/400）；SubjectContractTest/AuthContractTest 不回归（含 X1 数字 id 用例、X2 缺省用例）；全量 mvn 回归绿
- [ ] 网关联调：`/circle/**` 路由转实（预留 503 → 可达）；登录墙 401；X3 403
- [ ] 源文档登记完整（11+2），LF SHA before/after 记录
- [ ] 未改 `api/` 快照与 `sync-manifest`；无 DDL；caffeine 经 BOM
- [ ] 回执双轨 + 四字段远端证据

## 6. 关联

- 提案：`proposals/backend/2026-08-29/phase3-circle-endpoints-proposal.md`（PR #94）
- 决策：`pm/reviews/2026-08-29/phase3-circle-endpoints-proposal-decision.md`
- 架构：`docs/superpowers/specs/2026-08-27-a8-backend-architecture-direction.md` §7
- 后续：PM 验收 → 快照全链同步（+11 路径，语义差异按实际）→ 前端阶段三任务书（F-Impl：鸡圈页）