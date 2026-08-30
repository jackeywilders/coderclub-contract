# 前端评审签署：前端阶段三第一批圈子 + 消息中心实施（A8-P3-FE，T1-T5 + 基线 74）

> **签署角色：** 前端评审（F-Review）
> **签署日期：** 2026-08-30
> **任务书：** `pm/requirements/2026-08-30/phase3-frontend-circle-task.md`（派发 PR #106，taskId=A8-P3-FE，第一批 9 端点）
> **回执：** `handoff/frontend-to-backend/2026-08-30/frontend-circle-report.md` + `-summary.json`（PR #112，commit `af0c69f`，双轨齐全）
> **实现：** 前端仓库 PR #17（`feat/frontend-a8-p3-circle`，15 commits，merge `b9c22221`，2026-08-30）

## 1. 规则 9 远端证据（人链核验，MCP + git fetch 双通道）

| 字段 | 值 |
| --- | --- |
| 实施提交 SHA | `63e1408`（head；链路：`40198e3` 设计 / `5fce653`+`f9fa8f3` 计划 / `6cdfdd3` interceptor silent / `21f4a82` API+类型+utils / `d05152e` 测试 TZ / `5c6a695` store+scroll / `1eb1f30` T1 / `98f52b8` T2 / `9938249` T3 / `b86637d` T4 / `751f8f7` T4 修复 / `7a92bc4` T5 / `b47921c` 基线 74 / `63e1408` 最终审查 3 项修复） |
| 合并提交 SHA | `b9c22221`（Merge pull request #17，merge message 含 F-Review 复核结论留痕） |
| 回执提交 SHA | `af0c69f`（PR #112 主体；summary.json `receiptCommitSha` 回填待 F-Impl 补） |
| PR 号 | 前端仓库 **#17**；交接仓库 #112 |
| R2 状态 | ✅ 均已合入 `main`（前端 main HEAD=`b9c22221`，`63e1408` 为 ancestor，MCP + `git fetch origin` 双通道核验；交接仓库 PR #112 已合入 `af0c69f`） |
| 契约快照 SHA-256 | `ae967c70fbf0ca69085d2429cb586b0a3c83bdab9fb9f28d7a5a8b01f17e4f68`（74 端点，本任务零变更） |

## 2. 复核结论

✅ **A8-P3-FE 第一批（T1-T5 + 基线 74）复核通过，同意签署。** 圈子主页（树 + 无限流 + 发动态 + 评论树）、消息中心、事件驱动红点均满足任务书验收标准；9 端点消费与契约快照 AE967C70 一致；基线 63→74（specSha256 `ae967c70…`）同步正确；回执双轨齐全、证据链完整（含云端网关联调实跑证据）；已知待联调项已如实记录且 D3 已获 PM 决策，不阻塞签署。

## 3. 人链核验明细（F-Review 逐项验证：远端 blob 核验 + 本机四命令 + 代码审查）

### T1 路由与菜单 ✅

- 路由：PortalLayout children 新增 `/circle`（`CircleView.vue`，meta.title=圈子）、`/circle/messages`（`MessagesView.vue`，meta.title=消息中心），登录墙内（requiresAuth）；管理端 `/dashboard`、`/subject`、`/user`、`/role`、`/permission` 与既有路由零改动（`routes.ts` 核验 ✓）。
- PortalLayout：「圈子」由占位转真实菜单（`router-link to="/circle"`，active 高亮 `/circle` 前缀）；「模拟面试」保留占位；Header 用户区新增铃铛消息入口 + 未读数字红点（`unreadBadgeText`：0 隐藏 / >99 → 99+）。

### T2 圈子主页 ✅

- 圈子树：固定「全部动态」（默认选中）+ 大类根（点击=查全部，D4 如实呈现，后端无按大类过滤端点）+ 子圈（点击按 `circleId` 过滤）；`normalizeCircleTree` `children ?? []` 兜底（契约叶子序列化省略）。
- 动态流：`useInfiniteScroll`（IntersectionObserver + rootMargin 200px + 防重入守卫 + `reqSeq` 竞态令牌作废在途响应 + `pageNo >= totalPages`/空页置 finished + 切圈/发动态 `reset()` 重载第一页）；哨兵节点常驻 DOM，观察者挂载时序无窗口 ✓。
- `MomentCard`：头像兜底 / 昵称 / 圈子名映射（`buildCircleNameMap`，未命中不显示）/ 时间（`formatEpochTime`：24h 内相对、超出绝对 `yyyy-MM-dd HH:mm`，D5）/ 图片组 3 列 `el-image` 预览 / 评论数 / 本人删除（D3 临时判定，见 §5.1）+ 确认弹窗 + 成功从流移除（级联删评论由后端）。
- 消息跳转定位（D8）：`?momentId=` → 逐页扫描，命中 `scrollIntoView` + 高亮 2s；finished 或 20 页上限 → 「未找到该动态，可能已删除」。

### T3 发动态 ✅

- `MomentComposerDialog`：目标圈子 `el-select`（`el-option-group` 按大类分组，**仅子圈可选**，大类禁发前置兜底）+ 内容 textarea（maxlength 2000）+ `el-upload` picture-card（限 9 张，复用既有 `oss/upload`，`doUpload`：`uploadFile` + `bucket=user` + `objectName=moment/{ts}_{rand}` 唯一化防覆盖——`63e1408` 修复项 ✓）+ 成功 URL 收集 `picUrlList`。
- 前置校验：`circleId` 必选 + content/图片至少一项（发布按钮禁用兜底，与后端校验一致）；`saveMoment` 带 `silent`（D9）→ 业务失败（含敏感词「内容包含敏感词，请修改后发布」）页面内联展示；成功 → 关弹窗 + 流重置重载第一页（后端 save 返回 boolean 非 id，前端不依赖返回 id，消费一致）。

### T4 评论 ✅

- `CommentSection`：`getCommentList({momentId})` 全量树；type1 顶层 + type2 平铺「回复 @toNickName」；`fromIsMomentAuthor` → 「作者」徽标；`children ?? []` 兜底；树刷新与 replyCount 计数同步（`count-change` emit 校正）。
- 发评论（replyType=1）/ 回复（replyType=2 + targetId=目标评论 id）：带 `silent` 内联错误；成功 → 清空草稿 + 刷树 + `refreshUnRead()`；`751f8f7` 隔离提交失败与树刷新（提交失败不误刷新树）✓。
- 删除：判定 = `comment.fromId === String(当前用户 id)`（评论者本人，契约精确匹配）或动态为本人（作者可删）；`removeComment({id, replyType})` 非 silent（全局 toast）；确认弹窗注明子回复一并删除；成功刷树 + 计数（级联软删由后端，幂等）。

### T5 消息中心与红点 ✅

- `MessagesView`：全部/未读筛选 tab（`isRead=2` 契约语义 1 已读/2 未读，切 tab 重置分页）；`getMessages` 传统分页（el-pagination，id 倒序）；条目 `${fromNickName} ${msg}`（`buildMessageText` 昵称缺失兜底「有人」）+ createdTime；点击 → `/circle?momentId=<targetId>` 定位跳转。
- 红点（事件驱动，无轮询/WebSocket）：`store.refreshUnRead()` 时机 = ① CircleView onMounted ② MessagesView onMounted ③ MessagesView onUnmounted（读取即已读返回归零）④ 评论/回复成功回调后；失败静默不阻塞页面；Header 未读>0 显示数字红点。

### 公共层 ✅

- `response-interceptor` 改造：`handleResponseSuccess` 接收 `{data, config}`，HTTP 200 + code=400 业务错误支持 `silent`（silent 不 toast、页面内联；非 silent 全局 toast）；**401/403 auth 处理不受 silent 影响**（`applyAuthError` 先行，新增 3 条单测守护）✓；既有调用点 `{ data: res }` 适配无回归。
- `src/api/circle.ts`：9 端点（circle/list、moment save/getMoments/remove、comment save/list/remove、message unRead/getMessages）路径与方法与快照一致；silent 配置沿用 `Record<string, unknown>` 既有模式。
- `src/types/circle.d.ts`：7 DTO + 4 VO 与契约快照字段一致（`MomentItemVO` 无 fromId 系契约现状，D3 已提案）；`src/utils/circle.ts` 7 纯函数；`src/stores/circle.ts`（树缓存 + 红点）。
- 测试：`src/__tests__/circle.test.ts` 18 用例（TZ 无关夹具，`d05152e` 修复）全覆盖纯函数。

### 基线 74 ✅

- `api-docs-baseline.json`：`specSha256` = `ae967c70fbf0…`、`endpointCount=74`（`b47921c` 同步）；`npm run api:check` 输出 `Endpoints: 74`、`No API contract changes detected` ✓。

## 4. 验证证据（本机四命令独立复验 + CI）

| 命令 | 本机结果（2026-08-30，`feat/frontend-a8-p3-circle` = head `63e1408`） | CI |
| --- | --- | --- |
| `npm run build` | ✅ vue-tsc --noEmit + vite build exit 0 | ✅ |
| `npm test` | ✅ **45/45 pass**（8 suites，含 circle 18 用例 + interceptor silent 3 用例） | ✅ |
| `npm run api:check` | ✅ SHA `ae967c70…`，74 endpoints，No changes | ✅ |
| `npm run lint`（全量 `--fix=false`） | ✅ exit 0 | ✅ |
| 前端 CI `check`（PR #17） | — | ✅ SUCCESS（run 33308557314，2026-08-30T11:18:20Z，含 `63e1408` 最终修复后重跑） |

**云端网关联调**（回执 §5，2026-08-30 经本机网关 `localhost:5000` 实跑）：401 登录墙 → 登录 → 圈子树 → 发动态（含敏感词命中 400 文案逐字一致）→ 动态流 → 评论/回复/评论树 → 双账号未读（COMMENT/COMMENT_REPLY 目标正确，from==to 不落已验证）→ 读取即已读归零 → 删除权限与级联——全部通过；未发现前端契约消费与后端实况不一致项。

## 5. 已知待联调确认项（随回执 §6，不阻塞签署）

1. **D3 `MomentItemVO` 无创建人标识**：本批临时判定 `nickName === 昵称 || === String(id)`（误判面=昵称重复，仅影响删除入口显示，删除动作受后端「仅本人」400 兜底保护）。**已获 PM 决策确认**（`pm/reviews/2026-08-30/moment-item-fromid-decision.md`）：后端补 `fromId: string`（与 `CommentNodeVO.fromId` 同源）随下一实现轮排期派发，前端一行切换移除临时兜底；本批不派发、不阻塞。
2. **D2 `MessageVO` 无 `isRead` 条目级字段**：消息条目无法显示已读标记，本批以「全部/未读」筛选 tab 表达状态；PM 另记待评估（是否立项由 F-Review/PM 评估），不构成契约阻塞。
3. **`oss/upload` bucket/objectName 取值口径**：本批首次页面调用先例——`uploadFile` + `bucket=user` + `objectName=moment/{ts}_{rand}`（唯一化防同 key 覆盖，`63e1408` 修复）；真实图片上传链（Minio 环境）待联调确认。
4. **未读 tab 翻页即置已读**：后端「读取即已读」口径，切回未读 tab 条目减少属预期行为（如实呈现）。

**以上确认项建议 PM 验收时按回执口径登记；D3 已决策，D2/oss 项随后续批次或联调闭环。**

## 6. 签署意见

✅ **签署通过**。A8-P3-FE 第一批（T1-T5 + 基线 74）实施与回执满足任务书验收标准（9 端点消费一致、验证全绿、云端联调证据齐全、未动管理端路由），同意转协调 PM 验收（A8-P3-FE 第一批闭环；gate3 状态流转 `gate3-a8-phase3-*` 由 PM 执行）。

## 7. 版本记录

- 2026-08-30：创建（前端评审签署，转 PM 验收；前端 PR #17 已合入 `b9c22221`）。
