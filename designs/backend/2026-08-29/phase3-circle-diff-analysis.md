# A8 阶段三 circle 社区域——差异分析（B-Review）

> 角色：后端评审（B-Review）
> 日期：2026-08-29（Asia/Shanghai）
> 任务书：`pm/requirements/2026-08-28/phase3-circle-contract-proposal-task.md`（PR #93，提交 `d2a5414`）
> 架构方向：`docs/superpowers/specs/2026-08-27-a8-backend-architecture-direction.md` §7（Q6 决策 A：消息落库拉取，WebSocket 后置）
> 参考实现：jc-club `jc-club-circle`（控制器/服务/敏感词包/实体 + `doc_jc-club-init.sql` 表结构逐行对照）
> 表结构基线：云端核验（与 schema 文档一致）；share_circle/share_moment/share_comment_reply/share_message + sensitive_words 共 5 表
> 注：任务书原指定落 `2026-08-28/` 目录，按交接仓库治理规则 6（日期目录以创建日期为准）落 `2026-08-29/`，偏差随完成通知交 PM 追认。

## 1. 任务 1：差异分析 8 要点结论（逐条三选一）

| # | 差异点 | 结论 | 明细 |
| --- | --- | --- | --- |
| 1 | 圈子树结构（parent_id=-1 语义）与缓存取舍 | **现有表支持（无 DDL）+ Spring Cache 注解 + Caffeine TTL 30s** | 两层树：`parent_id=-1` 大类 + 子圈（`idx_parent_id` 已有）；`GET /circle/share/circle/list` 走 `@Cacheable`（`CaffeineCacheManager`，`spring.cache.caffeine.spec=expireAfterWrite=30s`，BOM 需新增 caffeine 版本管理——见 §4 依赖影响）。grilling Q3：零依赖方案与 TTL 方案注解代码相同，选 TTL 形态对齐蓝本；圈子 CRUD 不纳入本阶段（无写入端点），TTL 过期为唯一失效路径，够用 |
| 2 | 动态/评论列表昵称头像组装（created_by 存 userName 还是 loginId） | **存 loginId 串（对齐 practice 先例）+ 扩展 `list-by-identifiers` 数字 id 匹配** | grilling Q1。事实链：auth 登录 `StpUtil.login(user.getId())`（`AuthLoginController:49`）→ loginId = 用户 id 数字串；practice 全链 `getLoginIdAsString()` 落 `created_by`（`PracticeDetailController:64/74/84/95`）；而 `list-by-identifiers` 底层仅 `user_name IN (...)`（`AuthUserServiceImpl:38`）——practice 排行把 id 串当 userName 传入，真实数据下昵称解析降级为数字串（潜在显示缺陷，A8-P2 云端验证核验了链路 200 与条目数，未断言昵称渲染）。**决策**：circle 三表（moment/comment/message）`created_by`/`from_id`/`to_id` 一律存 `StpUtil.getLoginIdAsString()`（归属校验简单、与 practice 一致）；随本提案扩展 `/auth/user/list-by-identifiers`：纯数字标识同时按 id 匹配（`user_name IN (...) OR id IN (...)`），向后兼容、practice 代码零改动、排行昵称顺带修复。降级策略沿用 practice 先例（Feign 失败/缺失 → 兜底展示标识串） |
| 3 | 评论树：复合主键 (id,parent_id) 与子树删除、reply_count 一致性 | **现有表支持（无 DDL，实现设计明确）** | `share_comment_reply` 复合主键 `(id, parent_id)` 但 id 自增事实唯一——entity 以 `id` 为 `@Id(keyType=Auto)`、`parentId` 普通列（MyBatis-Flex 单列主键约束，全表按 id 访问）；jc-club 的 `root_node/leaf_node/children` varchar 列未被树构建实际使用（`listComment` 为内存 buildTree），我们**不写这些列**。树构建：查询 moment 下全部未删评论 → 内存组树（reply_type=1 为根节点，reply_type=2 按 parent_id 递归挂载，支持回复套回复）→ VO `children[]` 嵌套返回（全量不分页，蓝本一致）。子树删除：组树收集目标节点+全部后代 ids → 事务内批量软删 → `reply_count` 按**实际更新条数**回减（`incrReplyCount(momentId, -count)`）；动态删除：按 moment_id 全量软删评论（计数无需回减，动态已删）。计数一致性 = 每次增删同事务内 ± 实际条数 |
| 4 | 消息：content JSON 语义 + 读取即已读并发口径 | **现有表支持（无 DDL）+ 契约形态升级** | grilling Q5。落库形态沿用：`content` = JSON `{"msg","msgType","targetId"}`（msgType=COMMENT/COMMENT_REPLY，targetId=动态 id）；`is_read` 沿用表语义 1已读/2未读。**契约形态（区别于蓝本）**：`ShareMessageVO` 结构化展开 content（msgType/targetId/msg 三字段）并补 `fromId`/`fromNickName`（昵称读时经 `list-by-identifiers` 批量组装，与动态列表同模式）；`msg` 存**中性文案**（"评论了你的动态"/"回复了你的评论"），昵称由前端实时拼接——写路径零 Feign、昵称永不过期（jc-club 的 reply 文案写死昵称且 VO 不暴露 from_id，属缺陷，见 §3 E3）。`unRead` 返回 **Integer 未读总数**（蓝本 Boolean，数字徽标交互更通用，新端点无兼容包袱）；`getMessages` 按可选 `isRead` 过滤（null=全部）+ 分页，**返回后按页内 ids 批量置已读**（蓝本口径；置已读为幂等更新，并发重复置读无害）。自评论/自回复（from==to）不落消息（蓝本会落，属噪音，轻量增强） |
| 5 | 敏感词 DFA 形态 + 管理端点鉴权 | **现有表支持（无 DDL）+ 刷新增强 + 管理角色收敛** | grilling Q4。DFA 形态对齐蓝本：`WordContext` 启动全量加载 `sensitive_words`（type 1黑 2白）→ Trie Map；`WordFilter.check()` 黑名单命中 → 拒绝（业务错误）、白名单词跳过；skip 间隔混淆检测不启用（简化，蓝本可选能力不引入）。**增强**：save/remove 后**同步重建 DFA**（蓝本仅写库不刷新、重启才生效，属缺陷——量级小重建成本可忽略，见 §3 E2）。管理端点鉴权：`@SaCheckRole("admin_user")`（auth_role 既有角色键，零 DDL 零新角色）；circle 服务实现时注册 SaInterceptor + roleKeys 会话解析器（复制 subject `SaTokenWebConfig`/`SubjectSaTokenConfigure` 先例，角色注解实际生效）——与 openFinding `auth-role-check-gap` 不冲突（auth 自身缺口另案，circle 从一开始配齐）。方法形态：POST + JSON body（蓝本 GET+query 不采纳，任务书已定 POST） |
| 6 | 归属/越权（动态/评论删除） | **需实现增强（无 DDL）** | 蓝本 remove 无任何归属校验（信任前端，§3 E1）。我们对齐 practice `requireOwnedPractice` 模式：**动态删除 = 仅动态作者本人**（`created_by == loginId`，否则业务错误）；**评论删除 = 评论者本人 或 动态作者**（任务书"本人/作者"口径；动态作者删除他人评论同走子树软删+回减）；管理员删除不纳入本阶段（无管理后台场景，后续如需另案） |
| 7 | 字符集 | **无需迁移** | share_circle/share_moment/share_comment_reply/share_message/sensitive_words 5 表均为 utf8mb4（云端核验，与 `doc_jc-club-init.sql` 一致）；无 latin1/utf8mb3 风险表（区别于 interview 域） |
| 8 | **categoryId 一级过滤语义（openFinding `categoryId-primary-filter-semantics` 随附）** | **随本阶段扩展（无 DDL）** | grilling Q2。事实：`subject_info` 无 `primary_category_id` 列，大类↔题目关系全在 `subject_mapping`；getSubjectPage 现有过滤仅 `subjectDifficult/categoryId/labelId/subjectType`（`SubjectPageQueryDTO`）。**决策**：`getSubjectPage` 请求体新增可选 `primaryCategoryId`——后端展开（大类自身 + 直接子分类 id 集）经 `subject_mapping` 过滤（与 internal I2 `categoryCount` 已验证同模式），与既有过滤参数叠加，响应结构不变、向后兼容。openFinding 就此关闭：**一级 = primaryCategoryId，二级 = categoryId，语义显式、不做隐式递归**（subject_category 单表自关联共享 id 空间，隐式递归有歧义，不采纳） |

## 2. 表结构基线（云端核验，与 schema 文档一致）

| 表 | 关键列 | 字符集 |
| --- | --- | --- |
| `share_circle` | parent_id(-1 大类, idx) / circle_name / icon | utf8mb4 |
| `share_moment` | circle_id(idx) / content / pic_urls(URL JSON 数组串) / reply_count(默认 0) | utf8mb4 |
| `share_comment_reply` | moment_id(idx) / reply_type(1评论 2回复) / to_id/to_user / reply_id/reply_user / to_user_author/replay_author(是否作者) / content / pic_urls / parent_id；**复合主键 (id,parent_id)**，root_node/leaf_node/children 三列弃用不写 | utf8mb4 |
| `share_message` | from_id / to_id(idx) / content(JSON) / is_read(1已读 2未读) | utf8mb4 |
| `sensitive_words` | words / type(1黑 2白) | utf8mb4 |

## 3. 对照蓝本的增强/冲突点（明示交 PM）

| # | 点 | jc-club 行为 | 我们的设计 | 性质 |
| --- | --- | --- | --- | --- |
| E1 | 删除越权 | remove 无归属校验 | 动态=本人；评论=本人或动态作者（对齐任务书+practice 先例） | 增强 |
| E2 | 敏感词刷新 | save/remove 仅写库，重启才生效 | save/remove 后同步重建 DFA | 增强 |
| E3 | 消息契约 | VO 不暴露 from_id；msg 文案昵称不一致/写死过期 | 结构化 VO + 中性文案 + 昵称读时组装（§1.4） | 契约升级 |
| E4 | 自评论噪音 | from==to 也落消息 | from==to 不落 | 增强 |
| E5 | 管理端形态 | GET+query、零鉴权 | POST+JSON body、`@SaCheckRole("admin_user")` | 增强（任务书已定 POST） |
| E6 | 圈子管理 | save/update/remove circle 三端点 | **不纳入本阶段**（任务书清单外，差异分析明示；后续管理端另案） | 范围裁剪 |
| X1 | 既有端点扩展 | — | `list-by-identifiers` 数字 id 匹配（§1.2，顺带修复 practice 排行昵称） | **需 PM 确认** |
| X2 | 既有端点扩展 | — | `getSubjectPage` 新增可选 `primaryCategoryId`（§1.8，openFinding 关闭） | **需 PM 确认** |

## 4. 依赖与部署影响（B-Impl 参考，无契约面）

- **BOM**：`coder-club-dependencies` 新增 caffeine 版本管理 + circle 模块引入（`spring.cache.caffeine.spec` 纯 yaml 配置，注解代码与零依赖方案相同）。
- **新模块**：`coder-club-circle`（api/app/domain/infra/starter 四层，参照 practice）；不直连任何其他域表，用户信息仅经 Feign `list-by-identifiers`（Q4 边界延续）。
- **网关**：零改动——`/circle/**` 路由已在 GW-1 预留，circle 端点全量登录墙（无白名单新增）；敏感词管理端点登录 + 角色双检。
- **docker-compose**：新增 circle 服务段（随实现任务，参照 practice 段）。

## 5. DDL 变更清单

**无**。5 表已有且字符集一致；评论复合主键不改 DDL（id 自增事实唯一，entity 单列映射）；`practice_detail` 唯一索引（openFinding `practice-detail-unique-index`）属 practice 域另案，不混入本阶段。

## 6. 端点清单定稿（11 个，差异分析为准）

任务书 10 行中消息行（unRead/getMessages）按方法语义拆分为 2 端点 → **11 端点**：C 端 9（圈子 1 + 动态 3 + 评论 3 + 消息 2）+ 管理 2（敏感词 save/remove）。全量定义见提案 `proposals/backend/2026-08-29/phase3-circle-endpoints-proposal.md`。优先级：P0 = 圈子树/动态/评论核心链（#1-7），P1 = 消息（#8-9）与敏感词管理（#10-11）。

## 7. 关联

- 本次结论随提案 `proposals/backend/2026-08-29/phase3-circle-endpoints-proposal.md` 一并提交。
- X1/X2 既有端点扩展 + E 系列增强 → PM 确认（连同 DDL=0 结论）。
- grilling 决策记录：Q1 身份语义 / Q2 categoryId / Q3 缓存 / Q4 管理鉴权 / Q5 消息形态，2026-08-29 与用户逐项确认。

---
- 分析角色：后端评审（B-Review）
- 日期：2026-08-29
