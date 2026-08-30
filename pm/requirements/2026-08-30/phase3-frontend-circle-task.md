# 任务书：A8 阶段三前端 鸡圈主页 + 消息中心（A8-P3-FE 第一批，F-Impl）

> 派发角色：协调 PM
> 派发日期：2026-08-30
> 执行角色：前端实现（F-Impl）
> 消费契约：交接仓库 `api/coderclub-openapi.json` 快照 **AE967C70**（74 路径 / 117 schemas，PM 已验收）；后端 circle 11 端点已合入 CoderClub main（PR #15 merge `583b4bb` + 配套 PR #16 merge `b15a735`，R2）
> 决策依据：grill 共识四项（2026-08-30）——范围 C 全量分期 / 滚动无限加载 / 事件驱动红点 / 管理页待词库 list 另批
> 关联设计：`docs/superpowers/specs/2026-08-26-a8-frontend-portal-design.md`（阶段三节；本任务书按实际后端 11 端点契约细化，spec 预估 5 端点的差异以此为准）
> 批次定位：**第一批**（鸡圈主页 + 消息中心，9 端点）；第二批（管理端敏感词管理页）待词库 list 端点（另案提案）合入快照 75 后派发

## 前置基线

- 前端项目 `G:/Dev/backend/Club/CoderClubFront`；角色分支 `claude/frontend-proposals`，建议实现分支 `feat/frontend-a8-p3-circle`（单分支单 PR）。
- 门户壳/路由/登录墙沿用 A8-P1 成果；practice 三页模式（A8-P2）为页面与组件风格基准。
- **api:check 基线更新：63 → 74 端点，specSha256 `ae967c70fbf0ca69085d2429cb586b0a3c83bdab9fb9f28d7a5a8b01f17e4f68`**。

## 1. 任务明细

### T1 路由与菜单

- `/circle` 路由新增，Header 主菜单「鸡圈」由占位（点击提示开发中）转激活。
- 消息中心路由 `/circle/messages`；Header 用户区新增消息入口（未读红点，见 T5）。
- 管理端 dashboard 与既有路由零改动。

### T2 鸡圈主页（`/circle`）

- **布局**：左侧圈子树 + 右侧动态流（1200px 内容区风格对齐门户）。
- **圈子树**：`GET /circle/share/circle/list` 两层树渲染（大类根 + 子圈，叶子 `children:[]`，`CircleNodeVO`：id/circleName/icon）；点击**子圈** → `getMoments` 按 `circleId` 过滤；点击**大类** → 清空过滤（`circleId` 缺省查全部，后端无按大类过滤端点，如实呈现）。
- **动态流**：`POST /circle/share/moment/getMoments`（pageNo/pageSize/circleId，`created_time` 倒序）+ **滚动无限加载**（IntersectionObserver；防重复加载守卫 + 无更多数据到底提示；切圈重置分页）。
- **条目**（`MomentItemVO`：id/circleId/content/picUrlList/replyCount/nickName/avatar/createdTime）：图片组渲染（picUrlList 数组）、回复数展示、`createdTime` 为 epoch 毫秒需格式化；本人动态显示删除入口（见 T4 口径的动态侧删除）。

### T3 发动态

- 弹窗组件：目标圈子选择（**仅子圈可选**，大类禁发——后端对大类/不存在圈子返回业务失败 code=400，前端前置禁选兜底）+ 内容文本 + 图片上传（复用既有 `oss/upload` 契约，成功 URL 组装 `picUrlList`；content 与 picUrlList 至少一项，与后端校验一致并前置提示）。
- 发布成功 → 动态流顶部刷新/重载第一页；业务失败（含敏感词命中「内容包含敏感词，请修改后发布」）按 HTTP 200 + code=400 口径展示 message。

### T4 评论

- 动态条目展开评论树：`POST /circle/share/comment/list` 全量树渲染（`CommentNodeVO`：children 嵌套；`fromIsMomentAuthor` 显示作者徽标；type2 回复显示「回复 @toNickName」指向；`replyCount` 与列表条目一致）。
- 发评论（replyType=1）/ 回复（replyType=2，目标为评论）：成功后刷新评论树与 replyCount；敏感词 400 同 T3 口径。
- 删除：`POST /circle/share/comment/remove`（评论者本人或动态作者可删，其余后端 400）；确认弹窗；删除成功刷新树与计数（子树级联软删由后端完成，幂等 true）。
- 动态删除：`POST /circle/share/moment/remove`（仅本人，非本人后端 400；幂等 true）；确认弹窗；成功后从流中移除（级联删评论由后端完成）。

### T5 消息中心与未读红点

- **红点（事件驱动，grill 定案，无轮询/无 WebSocket）**：数据源 `GET /circle/share/message/unRead`；刷新时机 = 进入 `/circle` 或 `/circle/messages` 时 + 从消息页返回时（消息页读取即已读后返回应归零）+ 发评论/回复成功后；Header 未读>0 显示数字红点。
- **消息列表**：`POST /circle/share/message/getMessages`（分页 id 倒序；isRead 筛选 1/2 可选）+ `MessageVO`（msgType/msg 中性文案/fromNickName/createdTime 格式化）。
- **点击跳转**：targetId 为动态 id（后端口径）——跳转鸡圈页并定位对应动态（定位实现方式 F-Impl 自定：滚动定位或弹层展示，任务书不限定）。

### T6 质量门禁与验收证据

- `api:check` 基线 63→74 更新（specSha256 见前置基线）并保持通过。
- build / 单测（既有用例零回归）/ lint 全绿 + CI SUCCESS；新增页面逻辑单测按 A8-P2-FE 口径处理（vitest 延后项不阻塞）。
- 云端网关联调：经网关 401 登录墙 + 登录态核心链（发动态→评论→回复→双账号未读→读取即已读→删除级联）至少一轮真实请求证据（回执登记）。
- 回执双轨：`handoff/frontend-to-backend/` 按创建日期目录（Markdown + `*-summary.json` 模板字段齐全）；完成通知四字段（实施 SHA / 回执 SHA / PR 号 / R2 状态）；PR 由用户/F-Review 在 CI 绿后合入（仓库惯例）。

## 2. 验收标准

- [ ] T1-T5 全部落地：鸡圈主页（树+无限流+发动态+评论树）、消息中心、事件驱动红点
- [ ] 9 端点消费与契约一致：circle/list、moment save/getMoments/remove、comment save/list/remove、message unRead/getMessages
- [ ] api:check 基线 74（specSha256 `ae967c70…`）+ build/test/lint/CI 绿
- [ ] 云端网关联调证据入回执；回执双轨 + 四字段
- [ ] 未动管理端既有路由与页面；敏感词管理页不在本批（第二批）

## 3. 约束

- 消费契约以快照 `AE967C70` 为准；发现契约问题先写 `proposals/frontend/` 交 PM，不得改基线绕过评审。
- 业务错误统一 HTTP 200 + body code=400 口径展示 message；401 由门户登录墙承接（沿用 A8-P1）。
- 规则 8 敏感信息占位符与 Conventional Commits 照常。

## 4. 关联

- 快照 AE967C70（PR #105 批次）· 后端 circle PR #15（`583b4bb`）/ 配套 PR #16（`b15a735`）· A8-P3-BE 验收 PR #102 · A8-P3-COMPA 验收 PR #105
- 词库 list 端点提案（另案任务书，同批派发 B-Review）→ 合入快照 75 后派发本任务第二批（管理端敏感词管理页）
