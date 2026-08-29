# Proposal：A8 阶段三 circle 社区域契约（批量提案：11 新增 + 2 既有端点扩展）

> **提案角色：** 后端评审（B-Review）
> **日期：** 2026-08-29
> **任务书：** `pm/requirements/2026-08-28/phase3-circle-contract-proposal-task.md`（PR #93，提交 `d2a5414`）
> **差异分析：** `designs/backend/2026-08-29/phase3-circle-diff-analysis.md`（同批提交，含 grilling Q1-Q5 决策记录）
> **架构方向：** `docs/superpowers/specs/2026-08-27-a8-backend-architecture-direction.md` §7（Q6 决策 A：消息落库拉取，WebSocket 后置不进验收）
> **状态：** 待 PM 确认
> 注：落盘目录按治理规则 6 以创建日期为准（2026-08-29），任务书原路径 2026-08-28 的偏差随完成通知交 PM 追认。

## 1. 范围与边界

- 新增 **11 端点**（一次批量提案）：circle 域 C 端 9 个（圈子 1 + 动态 3 + 评论 3 + 消息 2）+ 敏感词管理 2 个；任务书 10 行中消息行（unRead/getMessages）按方法语义拆分为 2 端点。
- **扩展 2 个既有端点**（§2，向后兼容、显式列出交 PM 确认）：`list-by-identifiers` 数字 id 匹配、`getSubjectPage` 可选 `primaryCategoryId`（openFinding `categoryId-primary-filter-semantics` 随本提案关闭）。
- circle 域为**新模块**（`coder-club-circle`，api/app/domain/infra/starter 四层，参照 practice；模块级实现由 B-Impl 任务书定）。
- **消息形态（Q6 决策 A）**：落库 + 拉取，无 WebSocket 依赖；**敏感词**：DFA（Trie）+ 管理端触发重建。
- 不修改/删除任何现有端点、字段、鉴权、错误码语义（扩展项为**新增可选能力**，见 §2）；未动 `api/` 快照与 `sync-manifest`；DDL 变更 = **无**（差异分析 §5）。

## 2. 既有端点扩展（2 个，需 PM 确认）

> 两项均为**向后兼容的可选能力新增**，不改既有请求/响应既有字段语义；确认后由 B-Impl 随本阶段实现。

### 2.1 `POST /auth/user/list-by-identifiers`：标识匹配扩展

| 项 | 定义 |
| --- | --- |
| 现状 | `identifiers` 仅按 `user_name IN (...)` 匹配（`AuthUserServiceImpl:38`） |
| 扩展 | 标识集合中**纯数字串**同时按 `id IN (...)` 匹配（查询条件 `user_name IN (...) OR id IN (...)`；非数字标识行为完全不变） |
| 契约面 | 请求/响应结构零变化（`UserIdentifierQueryDTO`/`IdentifierUserItemVO` 不动）；仅 OpenAPI 描述补充匹配语义 |
| 动因 | circle 三表存 loginId 串（对齐 practice 先例），昵称解析需 id 匹配；**顺带修复 practice 排行昵称显示的潜在缺陷**（practice 代码零改动） |
| 影响 | 兼容性：既有消费方（practice/subject Feign）行为不变或变优；无破坏性 |

### 2.2 `POST /subject/getSubjectPage`：新增可选 `primaryCategoryId`

| 项 | 定义 |
| --- | --- |
| 现状 | 过滤字段 `subjectDifficult/categoryId/labelId/subjectType` + 分页；无一级分类过滤 |
| 扩展 | 请求体新增**可选** `primaryCategoryId: Long`——后端展开（大类自身 + 直接子分类 id 集）经 `subject_mapping` 过滤（与 internal I2 `categoryCount` 同模式），与既有过滤参数叠加 |
| 契约面 | 新增可选字段；响应结构零变化；缺省时不生效（向后兼容） |
| 动因 | 门户首页"点击大类"过滤语义（openFinding `categoryId-primary-filter-semantics`）；语义定界：**一级 = primaryCategoryId，二级 = categoryId**，显式不递归 |
| 影响 | 前端消费为可选；无 DDL（`subject_info` 无 primary 列，经 mapping 过滤） |

## 3. circle 域新增端点（11 个）

> 统一：C 端 `@SaCheckLogin`（门户登录墙）；敏感词管理 `@SaCheckRole("admin_user")` + circle 服务注册 SaInterceptor/roleKeys 解析器（subject 先例，角色注解实际生效）；`ResponseResult` 包装；分页复用 `PageInfo`/`PageResult`（common 版）；身份标识一律存 `StpUtil.getLoginIdAsString()`；昵称/头像经 Feign `list-by-identifiers`（扩展后）读时组装，失败降级标识串（practice 先例）；示例语义化（规则 8）。

### P0 圈子/动态/评论核心链

| # | 端点 | 请求 | 响应 | 语义要点 |
| --- | --- | --- | --- | --- |
| 1 | `GET /circle/share/circle/list` | 无 | `ResponseResult<List<CircleNodeVO>>`：`{id, circleName, icon, children:[{id, circleName, icon}]}`（两层树） | 圈子树：`parent_id=-1` 大类 + 子圈；`@Cacheable`（Caffeine TTL 30s，`expireAfterWrite`；本阶段无圈子写入端点，TTL 过期为唯一失效路径） |
| 2 | `POST /circle/share/moment/save` | `MomentSaveDTO{circleId 必填, content?, picUrlList?:List<String>}` | `ResponseResult<Boolean>` | 发布动态：circleId 必须为子圈（`parent_id != -1`，否则 400）；content/picUrlList **至少一项非空**；content 黑名单命中拒绝（白名单跳过）→ 400 业务错误；落 `pic_urls`（JSON 数组串）+ `reply_count=0` + `created_by=loginId` |
| 3 | `POST /circle/share/moment/getMoments` | `MomentPageQueryDTO{circleId?, pageNo, pageSize}` | `ResponseResult<PageResult<MomentItemVO>>`：`{id, circleId, content, picUrlList, replyCount, nickName, avatar, createdTime}` | 动态分页（`created_time` DESC；circleId 可选过滤）；批量昵称头像（Feign，缺失降级标识串）；`picUrlList` 由 `pic_urls` 反序列化 |
| 4 | `POST /circle/share/moment/remove` | `MomentRemoveDTO{id 必填}` | `ResponseResult<Boolean>` | 删除动态（**仅本人**，否则 400 无权）：动态软删 + 该动态全部评论按 moment_id 批量软删（事务内）；重复删除幂等返回 true |
| 5 | `POST /circle/share/comment/save` | `CommentSaveDTO{momentId 必填, replyType 必填(1评论 2回复), targetId?(replyType=2 必填), content?, picUrlList?}` | `ResponseResult<Boolean>` | 评论/回复：动态须存在未删（400）；content/picUrlList 至少一项；敏感词校验同 #2；replyType=1 → `parent_id=-1`、to=动态；replyType=2 → `parent_id=reply_id=targetId`、to=被回复评论者（目标不存在 400）；落库后消息落库（msgType=COMMENT→动态作者 / COMMENT_REPLY→被回复人；**from==to 不落**，targetId=动态 id）；`reply_count` 同事务 +1 |
| 6 | `POST /circle/share/comment/list` | `CommentListQueryDTO{momentId 必填}` | `ResponseResult<List<CommentNodeVO>>`：`{id, momentId, replyType, content, picUrlList, parentId, fromId, fromNickName, fromAvatar, toId, toNickName, toAvatar, fromIsMomentAuthor, createdTime, children:[…]}` | 某动态全部评论（树形全量，reply_type=1 为根、reply_type=2 按 parent_id 递归嵌套，支持回复套回复；`fromIsMomentAuthor` = 评论者是否动态作者，对应蓝本 to_user_author/replay_author 语义合并）；昵称头像批量组装（from/to 两集合合并一次 Feign） |
| 7 | `POST /circle/share/comment/remove` | `CommentRemoveDTO{id 必填, replyType 必填}` | `ResponseResult<Boolean>` | 删除评论（**评论者本人或动态作者**，否则 400 无权）：内存组树收集目标+全部后代 ids → 事务内批量软删 → `reply_count` 按**实际更新条数**回减；重复删除幂等返回 true |

### P1 消息（落库拉取，无 WebSocket）

| # | 端点 | 请求 | 响应 | 语义要点 |
| --- | --- | --- | --- | --- |
| 8 | `GET /circle/share/message/unRead` | 无 | `ResponseResult<Integer>` | 当前登录人未读总数（`to_id=loginId` 且 `is_read=2` 且未删；**读取即已读不适用本端点**——只计数不改状态） |
| 9 | `POST /circle/share/message/getMessages` | `MessagePageQueryDTO{isRead?(1已读 2未读，null=全部), pageNo, pageSize}` | `ResponseResult<PageResult<MessageVO>>`：`{id, msgType, targetId, msg, fromId, fromNickName, createdTime}` | 消息分页（`id` DESC）；content JSON 结构化展开 + from 昵称读时组装；**返回后按页内 ids 批量置已读**（幂等，并发重复置读无害）；`msg` 中性文案（"评论了你的动态"/"回复了你的评论"），昵称由前端拼 `fromNickName` |

### P1 敏感词管理（管理端）

| # | 端点 | 请求 | 响应 | 语义要点 |
| --- | --- | --- | --- | --- |
| 10 | `POST /circle/sensitive/words/save` | `SensitiveWordSaveDTO{words 必填, type 必填(1黑 2白)}` | `ResponseResult<Boolean>` | 新增敏感词（**@SaCheckRole("admin_user")**，非管理员 403）；同词同类型已存在 → 幂等返回 true 不重复入库；成功后**同步重建 DFA**（立即生效，修复蓝本重启才生效缺陷） |
| 11 | `POST /circle/sensitive/words/remove` | `SensitiveWordRemoveDTO{id 必填}` | `ResponseResult<Boolean>` | 删除敏感词（**@SaCheckRole("admin_user")**）：逻辑删（幂等 true）；成功后同步重建 DFA |

## 4. 错误码与通用约定

- 鉴权：C 端全部 `@SaCheckLogin`（无登录态 401，网关/服务双保险）；敏感词管理端点叠加 `@SaCheckRole("admin_user")`（无角色 **403**——circle 自带 GlobalExceptionHandler 映射 Sa-Token `NotRoleException`，为本系统首个实际生效的角色注解端点）。
- 校验：Jakarta Validation 缺必填 → 400；业务错误 `BaseException(400, message)`，不新增错误码枚举。语义化错误：非法圈子（不存在或为大类）/ 动态不存在或已删除 / 回复目标不存在 / 内容包含敏感词，请修改后发布 / 无权删除（非本人或非动态作者）。
- 分页：`PageInfo{pageNo 默认 1, pageSize 默认 20}` → `PageResult{records, total, pageNo, pageSize}`（语义同 `getSubjectPage`）。
- 并发/幂等：删除类端点重复调用幂等 true（条件更新 `is_deleted=0` 不命中视为已删）；评论计数增删同事务；消息置已读幂等。
- 网关：零改动——`/circle/**` 路由 GW-1 已预留且默认登录墙，无白名单新增。

### 4.1 语义化示例（节选，规则 8：全部为样本值）

```jsonc
// #3 getMoments 响应 data.records 节选（昵称解析成功 + 降级各一）
[
  { "id": 2, "circleId": 2, "content": "示例动态内容", "picUrlList": ["<oss-url>"],
    "replyCount": 6, "nickName": "示例昵称A", "avatar": "<oss-url>", "createdTime": 1756425600000 },
  { "id": 3, "circleId": 2, "content": "示例动态内容B", "picUrlList": null,
    "replyCount": 0, "nickName": "10002", "avatar": null, "createdTime": 1756420000000 }
]

// #9 getMessages 响应 data.records 节选（msg 为中性文案，昵称前端拼接）
[
  { "id": 10, "msgType": "COMMENT", "targetId": 2, "msg": "评论了你的动态",
    "fromId": "10003", "fromNickName": "示例昵称B", "createdTime": "2026-08-29 12:00:00" }
]

// #5 comment/save 请求（回复场景）
{ "momentId": 2, "replyType": 2, "targetId": 15, "content": "示例回复内容", "picUrlList": null }
```

> 示例中 `fromId: "10003"` 为 loginId 串（数字 id），昵称经扩展后的 `list-by-identifiers` 解析（§2.1）；解析失败降级展示标识串（示例第二条 `nickName: "10002"` 即降级形态）。

## 5. 待 PM 决策项

| # | 项 | 建议 | 需 PM 确认 |
| --- | --- | --- | --- |
| X1 | `list-by-identifiers` 数字 id 匹配扩展 | 随本阶段实现（向后兼容，顺带修复 practice 排行昵称显示） | ✅ |
| X2 | `getSubjectPage` 新增可选 `primaryCategoryId` | 随本阶段实现（openFinding `categoryId-primary-filter-semantics` 关闭） | ✅ |
| X3 | 敏感词管理鉴权 | `@SaCheckRole("admin_user")`（既有角色，零 DDL；circle 注册 SaInterceptor 使注解生效） | ✅ |
| X4 | 消息契约形态 | 结构化 VO + 中性文案 + 昵称读时组装；unRead 返回 Integer | ✅ |
| X5 | 蓝本增强项 E1-E5 | 归属校验 / DFA 刷新 / 消息结构化 / 自评论不落 / POST+角色（差异分析 §3） | ✅ 知悉 |
| X6 | 圈子管理 CRUD（save/update/remove circle） | 不纳入本阶段（任务书清单外，后续管理端另案） | ✅ 知悉 |
| D0 | DDL 变更 | 无（5 表全支撑，字符集一致） | ✅ 知悉 |

## 6. 约束遵守声明

- 仅新增 §3 端点 + §2 两项**可选能力扩展**（后者以提案列示，PM 确认后才随实现落地；本提案本身未改任何契约源/运行时源）。
- 未动 `api/` 快照与 `sync-manifest`（PM 验收后全链同步：预计 +11 新端点 + 2 扩展语义差异）。
- 消息落库拉取形态，无 WebSocket 依赖（Q6 决策 A；WebSocket 为后置可选增强，不进验收标准）。
- 示例均为语义化样本，无真实环境信息（规则 8）。

## 7. 关联与后续

- 任务书：`pm/requirements/2026-08-28/phase3-circle-contract-proposal-task.md`（PR #93）；架构方向 PR #79 §7
- 差异分析：`designs/backend/2026-08-29/phase3-circle-diff-analysis.md`（grilling Q1-Q5 决策记录）
- openFinding 关联：`categoryId-primary-filter-semantics`（X2 关闭）；`auth-role-check-gap`（circle 自身配齐，不阻塞；auth 另案）；`practice-detail-unique-index`（practice 域另案，不混入）
- 后续：PM 确认（含 X1-X6/D0）→ B-Impl 实现任务书（`coder-club-circle` 新模块 + 2 既有端点扩展，BOM caffeine）→ 回执 → B-Review 签署 → PM 验收 → 快照全链同步 → 前端阶段三任务书（F-Impl：鸡圈页）

---
- 提案角色：后端评审（B-Review）
- 日期：2026-08-29
