# 前端阶段三第一批实施回执（A8-P3-FE：圈子主页 + 消息中心，T1-T5，9 端点）

> 回执角色：前端实现（F-Impl）
> 回执日期：2026-08-30
> 任务书：`pm/requirements/2026-08-30/phase3-frontend-circle-task.md`（交接仓库 PR #106，taskId=A8-P3-FE）
> 依据：`docs/agents/verification-workflow.md` §6 双轨（Markdown + `*-summary.json`）
> 契约快照：`AE967C70`（74 路径，specSha256 `ae967c70fbf0ca69085d2429cb586b0a3c83bdab9fb9f28d7a5a8b01f17e4f68`，本任务零变更）
> 契约提案：`proposals/frontend/2026-08-30/moment-item-fromid-proposal.md`（D3，随本批提交交接仓库）

## 1. 来源与提交哈希

| 字段 | 值 |
| --- | --- |
| 来源项目 | `G:/Dev/backend/Club/CoderClubFront`（前端代码仓库，private） |
| 来源分支 | `feat/frontend-a8-p3-circle`（基于 main `5e68c1d`，14 commits 一体交付） |
| 设计提交 SHA | `40198e3`（docs(design): A8-P3-FE circle + messages design (T1-T6)） |
| 计划提交 SHA | `5fce653`（docs(plan): A8-P3-FE circle implementation plan (10 tasks)）、`f9fa8f3`（docs(plan): fix ambient type imports） |
| 实施提交 SHA | `6cdfdd3`（interceptor silent）、`21f4a82`（API 层 + 类型 + utils）、`d05152e`（测试 TZ 修复）、`5c6a695`（store + infinite scroll）、`1eb1f30`（T1 菜单）、`98f52b8`（T2 动态流）、`9938249`（T3 发动态）、`b86637d`（T4 评论树）、`751f8f7`（T4 修复）、`7a92bc4`（T5 消息中心）、`b47921c`（基线 74）、`63e1408`（最终审查 3 项修复：OSS key 唯一化 / 树加载失败降级 / 嵌套回复展平计数） |
| PR 号 | 前端仓库 **#17**（`feat/frontend-a8-p3-circle` → `main`，CI check=success） |
| R2 状态 | 待用户/F-Review 合入 PR #17（CI 已绿） |
| 契约快照 SHA-256 | `ae967c70fbf0ca69085d2429cb586b0a3c83bdab9fb9f28d7a5a8b01f17e4f68`（交接仓库当前快照，74 路径，本任务零变更） |

## 2. T1-T5 实现说明

### T1 路由与菜单（`src/router/routes.ts` + `src/layout/PortalLayout.vue`）

- 路由：PortalLayout children 新增 `/circle`（`CircleView.vue`，meta.title=圈子）、`/circle/messages`（`MessagesView.vue`，meta.title=消息中心），`requiresAuth` 登录墙内；管理端 dashboard 与既有路由零改动。
- 菜单：PortalLayout「鸡圈」移出 `comingSoonMenus`，新增 `<router-link to="/circle">圈子</router-link>`，高亮 `route.path.startsWith('/circle')`；「模拟面试」保持占位。
- 铃铛入口：Header 用户头像左侧新增消息铃铛，`unReadCount > 0` 显示数字红点（`unreadBadgeText`：0 隐藏 / >99 → 99+），点击跳 `/circle/messages`。

### T2 圈子树 + 动态无限流（`CircleView.vue` + `MomentCard.vue`）

- 圈子树：固定「全部动态」节点（默认选中，D4）+ 大类根（icon+名称，点击=选回全部）+ 子圈（点击按 `circleId` 过滤）；`children ?? []`（D4 契约叶子节点序列化省略兜底）。
- 动态流：`MomentCard` 列表 + 哨兵（`useInfiniteScroll`，pageSize=10，防重入 + `pageNo > totalPages` 置 finished）；选中 circleId watch → `reset()+load`；圈子名靠 `buildCircleNameMap`（store 扁平化 id→name 映射，未命中不显示）。
- 卡片：头像（null 首字母 `el-avatar` 兜底）+ 昵称 + 圈子名 + 时间（D5：epoch 毫秒 → 24h 内相对时间 / 超出 `yyyy-MM-dd HH:mm`）；`picUrlList` 3 列网格 `el-image`（`preview-src-list` 大图）；底部评论（replyCount）+ 删除（本人动态显示，判定 D3 临时兜底；确认弹窗 → `removeMoment({id})` → 成功从流移除，级联删评论由后端完成）。
- 定位模式（D8）：`?momentId=` 进入 → 逐页扫描，找到 → `scrollIntoView` + 高亮闪烁；找不到 → 继续至 finished 或 20 页上限 → 提示「未找到该动态，可能已删除」。

### T3 发动态（`MomentComposerDialog.vue`）

- 目标圈子 `el-select`（大类 `option-group` 分组，仅子圈可选）+ content textarea + `el-upload` picture-card（自动 `oss.uploadFile`，成功 URL 收集 `picUrlList`）。
- 前置校验：`circleId` 必选、`content.trim()` 或图片至少一项（发布按钮禁用兜底）。
- `saveMoment` 带 `silent`（D9）→ 页面内联错误（含敏感词文案）；成功 → 关弹窗 + 流 `reset()+load` 第一页。

### T4 评论树（`CommentSection.vue`）

- 展开 → `getCommentList({momentId})` 全量树；type1 顶层列表；type2 平铺于父评论回复区，显示「回复 @toNickName」；`fromIsMomentAuthor` → 「作者」徽标；`children ?? []`。
- 删除：判定 = `comment.fromId === String(当前用户 id)`（评论者本人）或动态为本人（作者可删任何评论）；确认弹窗（注明子回复一并删除）；`removeComment({id, replyType})` 不带 silent（D9）；成功刷树 + replyCount。
- 发评论/回复：底部单输入框，回复模式前缀「回复 @toNickName」+ 可取消（`replyType=2` + `targetId` 必带）；成功 → 刷树 + replyCount + `refreshUnRead()`（D10）；带 silent（D9，内联错误）。
- `751f8f7`：隔离评论提交错误路径与树刷新（提交失败不误刷新树）。

### T5 消息中心 + 红点 + 定位（`MessagesView.vue` + store + PortalLayout 铃铛）

- `MessagesView.vue`：1200px 卡片；筛选 tab「全部 / 未读」（未读传 `isRead=2`；切 tab 重置分页）；`getMessages` 传统分页（`el-pagination`，id 倒序）；条目 = 头像 + `${fromNickName} ${msg}`（`buildMessageText`，昵称缺失兜底「有人」）+ 时间字符串；条目无已读标记（D2）；点击 → `/circle?momentId=<targetId>` 定位。
- 红点（`src/stores/circle.ts`）：`refreshUnRead()` 时机 = ① `CircleView` onMounted ② `MessagesView` onMounted ③ `MessagesView` onUnmounted（覆盖「读取即已读后返回归零」）④ 评论/回复成功回调后（D10 事件驱动，无轮询/WebSocket）。
- `oss.uploadFile`：复用既有 OSS 上传端点，本批首次页面调用（bucket/objectName 取值口径见 §7 待确认项 3）。

## 3. 9 端点消费明细

| # | 函数 | 方法 + 路径 | 消费点 | silent |
|---|---|---|---|---|
| 1 | `getCircleTree` | GET `/circle/share/circle/list` | CircleView 圈子树（store fetchCircleTree 缓存） | 否 |
| 2 | `saveMoment` | POST `/circle/share/moment/save` | MomentComposerDialog 发布 | 是（D9） |
| 3 | `getMoments` | POST `/circle/share/moment/getMoments` | CircleView 无限流（circleId 可选）+ 定位扫描 | 否 |
| 4 | `removeMoment` | POST `/circle/share/moment/remove` | MomentCard 删除（幂等，非本人 400 兜底） | 否 |
| 5 | `saveComment` | POST `/circle/share/comment/save` | CommentSection 评论/回复 | 是（D9） |
| 6 | `getCommentList` | POST `/circle/share/comment/list` | CommentSection 全量树 | 否 |
| 7 | `removeComment` | POST `/circle/share/comment/remove` | CommentSection 删除（带 replyType，幂等） | 否 |
| 8 | `getUnReadCount` | GET `/circle/share/message/unRead` | store.refreshUnRead（红点） | 否 |
| 9 | `getMessages` | POST `/circle/share/message/getMessages` | MessagesView 分页（isRead 筛选） | 否 |

敏感词 2 端点（`/circle/sensitive/words/*`）不消费（第二批）。

## 4. 验证结果

| 命令 | 结果 |
| --- | --- |
| `npm run build`（vue-tsc + vite） | exit 0 |
| `npm test` | 45/45 pass（8 suites, 0 fail） |
| `npm run lint` | exit 0 |
| `npm run api:check` | `Endpoints: 74`、`SHA-256: ae967c70…`、**No API contract changes detected** |
| CI | 前端 PR #17 `check` conclusion=success（含最终修复 `63e1408` 后重跑） |
| 审查 | 任务级审查 10 轮全部通过（task-1..9 报告留档）；全分支最终审查 3 项修复已定向复审 ADDRESSED，合并就绪 |

## 5. 云端网关联调证据（2026-08-30 实跑）

**环境**：本机六微服务已启动（auth 3100 / subject 3000 / oss 3200 / circle 3500 / practice 3400 / **gateway 5000**），联调全部经**网关 `localhost:5000`**；测试账号 `test01` / `test02`（密码 123456）。请求体以 UTF-8 文件承载（Git Bash 内联中文编码会触发参数校验失败，非业务问题）。

### 5.1 401 登录墙

```text
GET  http://localhost:5000/circle/share/circle/list （无 token）
→ HTTP 401 {"success":false,"code":401,"message":"未登录或Token已过期","data":null}
```

### 5.2 登录

```text
POST http://localhost:5000/auth/login {"userName":"test01","password":"123456"}
→ {"code":200,"success":true,"data":{"token":"D8it…","userInfo":{"id":10,"userName":"test01","nickName":"测试一号"}}}  （test02 同，id=11，昵称「测试二号」）
```

### 5.3 圈子树

```text
GET http://localhost:5000/circle/share/circle/list（Authorization: test01 token）
→ data=[{id:1,"circleName":"Java圈子",icon,children:[{id:2,"涨薪圈"},{3,"系统设计圈"},{4,"性能优化圈"},{5,"面试经验圈"}]}]
```
两层树结构、叶子 `children:[]`、`parent_id=-1` 大类根语义均与契约一致。

### 5.4 发动态（T3 链路）

```text
POST http://localhost:5000/circle/share/moment/save {circleId:2, content:"联调动态：圈子功能验证", picUrlList:["https://image/test/m1.png"]}
→ {"code":200,"success":true,"data":true}
```
**发现 1**：`moment/save` 响应 `data` 为 boolean 成功标志（非动态 id）——前端按设计「发布成功 → 流刷新第一页取最新条」消费（`getMoments` 倒序首条即新动态，id=7），不依赖返回 id，契约消费一致。敏感词命中验证：`{content:"免费领取赌博神器"}` → `{"code":400,"message":"内容包含敏感词，请修改后发布"}`，**文案与任务书 T3 逐字一致**（前端 silent 内联展示该 message）。

### 5.5 动态流（T2）

```text
POST /circle/share/moment/getMoments {pageNo:1,pageSize:10} → total=6，list[0]={id:7,content:"联调动态：圈子功能验证",replyCount:0}
```
倒序、replyCount、分页字段与契约一致。

### 5.6 评论 → 回复 → 评论树（T4）

```text
POST /circle/share/comment/save {momentId:7, replyType:1, content:"test02 评论：不错"} → data:true（发现 2：comment/save 同返回 boolean，前端靠刷新树取 id，一致）
POST /circle/share/comment/save {momentId:7, replyType:2, targetId:9, content:"test02 回复：补充"} → data:true
POST /circle/share/comment/list {momentId:7}
→ data=[{id:9, fromNickName:"测试二号", replyType:1, fromIsMomentAuthor:false, children:[{id:10,fromNickName:"测试二号",toNickName:"测试二号",replyType:2},{id:11,fromNickName:"测试一号",toNickName:"测试二号",replyType:2}]}]
```
树形嵌套、`fromIsMomentAuthor` 徽标数据、`toNickName` 回复指向、type1/type2 结构全部与契约一致（T1 为动态作者时徽标语义由 `fromIsMomentAuthor` 提供）。

### 5.7 双账号未读 → 读取即已读（T5）

```text
T1 发动态 + T2 评论（→ 动态作者 T1 收 COMMENT）；T2 回复自己评论（→ from==to 不落，无消息）；T1 回复 T2 的评论（→ 被回复人 T2 收 COMMENT_REPLY）
GET /circle/share/message/unRead → T1: {"data":1}（COMMENT「评论了你的动态」from 测试二号）｜ T2: {"data":1}（COMMENT_REPLY「回复了你的评论」from 测试一号）
POST /circle/share/message/getMessages {pageNo:1,pageSize:10} → 各 1 条（msgType/targetId/msg/fromNickName 齐全，msg 为中性文案）
GET /circle/share/message/unRead（读取后）→ T1: {"data":0} ｜ T2: {"data":0}
```
**关键语义验证**：评论/回复分别产生 `COMMENT` / `COMMENT_REPLY` 且目标人正确（动态作者 / 被回复评论者）；**from==to 不落库**（T2 回复自己评论未产生消息）与「读取即按页 ids 置已读 → 未读归零」均与任务书后端口径一致。

### 5.8 删除权限与级联（T4）

```text
T2 删 T1 的动态 → {"code":400,"message":"无权删除"}（仅本人，任务书口径）
T2 删自己的回复（id=10, replyType=2）→ {"code":200,"data":true}（评论者本人可删，幂等）
T1 删动态 id=7 → {"code":200,"data":true}；随后 getMoments 中 id=7 消失（级联删除生效）；getCommentList {momentId:7} → {"code":400,"message":"动态不存在或已删除"}（评论随动态级联删除，接口兜底）
```

### 5.9 联调结论

401 登录墙、登录态核心链（发动态 → 评论 → 回复 → 双账号未读 → 读取即已读 → 删除级联）全部通过；未发现前端契约消费与后端实况不一致项。发现的 2 处接口形态（moment/comment save 返回 boolean 而非 id）前端消费方式已核对一致，登记入回执备查。`oss/upload` 图片上传真实链路未在本轮执行（Minio 依赖与账号 token 注入路径已由实现核对，见 §6 待确认项 3）。

## 6. 待联调确认项

1. **`MessageVO` 无 `isRead` 条目级字段**（D2）：消息条目无法显示已读标记，本批以「全部 / 未读」筛选 tab 表达状态；是否立项由 PM/F-Review 评审决定。
2. **`MomentItemVO` 无创建人标识**（D3）：本批临时判定 `nickName === 当前用户昵称 || nickName === String(当前用户 id)`（误判面=昵称重复，后端 `moment/remove` 非本人 400 兜底）；提案 `fromId` 已提交（`proposals/frontend/2026-08-30/moment-item-fromid-proposal.md`），待 PM 评审。
3. **`oss/upload` 响应 URL 字段 / bucket / objectName 取值口径**：`uploadFile` 本批为首次页面调用先例，以实现时契约/后端实况核对为准，联调确认。
4. **未读 tab 翻页即置已读**：后端「读取即已读」口径，切回未读 tab 条目减少属预期行为（如实呈现）。

## 7. D0 文案差异说明

- 任务书原文使用「鸡圈」；用户 2026-08-30 于设计确认时更名，Header 主菜单与页面标题统一使用**「圈子」**（路由 `/circle` 与契约不变，仅 UI 文案）。

## 8. 来源契约核验

- 消费快照来源：交接仓库 `origin/main` `api/coderclub-openapi.json`（SHA e3f5462）→ 前端 `local/coderclub-openapi.json`（ignored）。
- `npm run api:check -- --update-baseline` 生成基线（`b47921c`）：`endpointCount=74`、`specSha256=ae967c70…`；复核 `api:check` 输出 No changes。
- 哈希不一致时本回执不成立；本批 74 路径全部消费端点均来自该快照，未自行推断字段/方法/鉴权。

## 9. Frontend 声明

我确认以上消费文件、来源、哈希和验证结果真实可复核；未确认的字段、方法、鉴权或错误码没有被前端自行推断。

- Frontend 角色：前端实现（F-Impl）
- 日期：2026-08-30
