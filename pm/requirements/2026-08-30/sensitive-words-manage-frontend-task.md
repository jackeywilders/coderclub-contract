# 任务书：A8 阶段三第二批 管理端敏感词管理页（F-Impl）

> 派发角色：协调 PM
> 派发日期：2026-08-30
> 执行角色：前端实现（F-Impl）
> 消费契约：交接仓库 `api/coderclub-openapi.json` 快照 **6262F444**（75 路径 / 119 schemas，PM 已验收）；敏感词三端点已合入 CoderClub main（list 经 PR #17 merge `8617d9de`，save/remove 既有）
> 决策依据：grill 共识 11 项（2026-08-30，用户逐项确认）+ brainstorming 设计确认（分节批准）
> 批次定位：**第二批**（管理端敏感词管理页）；本批**双轨派发**——F-Impl 本任务书 + B-Impl fromId 小实现（`moment-item-fromid-implementation-task.md`）并行

## 前置基线

- 前端项目 `G:/Dev/backend/Club/CoderClubFront`；角色分支 `claude/frontend-proposals`，建议实现分支 `feat/frontend-a8-p3-sensitive-words`（单分支单 PR）。
- 管理端沿用 A8-P1 成果：MainLayout + Sidebar（平铺 `el-menu-item`，`hasAdminRole` 控制）；管理页模式基准 = `src/views/subject/label/LabelManage.vue`（操作卡 + 表格 + 对话框）。
- 敏感词契约（快照 6262F444）：
  - `POST /circle/sensitive/words/list`——管理端只读全量（无请求体，type ASC + id ASC），`ResponseResult<List<SensitiveWordItemVO>>`，`SensitiveWordItemVO {id, words, type, createdTime}`（createdTime 存量 null 序列化省略）
  - `POST /circle/sensitive/words/save`——`SensitiveWordSaveDTO {words, type}`（required，type 1=黑名单 2=白名单，同词同类型幂等），返回 `ResponseResultBoolean`
  - `POST /circle/sensitive/words/remove`——`SensitiveWordRemoveDTO {id}`（required，逻辑删幂等），返回 `ResponseResultBoolean`
- **api:check 基线更新：74 → 75 端点，specSha256 `6262f44477a1a6887668f3514b506d6874edcc645516d471131a2d2a3a2cb439`**。

## 1. 任务明细

### T1 路由与菜单

- 管理端新增路由 `/sensitive`（MainLayout 子路由，`meta: { title: '敏感词管理' }`，沿用 `roles: ['admin_user']` 路由角色墙——与后端 `@SaCheckRole("admin_user")` 双重兜底）。
- `Sidebar.vue` 平铺新增菜单项「敏感词管理」（`v-if="hasAdminRole"`，`index="/sensitive"`，置于权限管理之后）。
- 管理端既有路由与页面零改动（仅新增）。

### T2 列表与三 tab

- 页面骨架对齐 LabelManage：操作卡（搜索 + tab + 批量删除 + 新增按钮）+ 表格卡（`el-table` 全量本地渲染，无分页——后端全量 + type ASC/id ASC 排序背书）。
- **三 tab**：黑名单（1）/ 白名单（2）/ 全部——黑/白 tab = 本地 `filter(type)`；「全部」按后端原始顺序展示。
- **tab 徽标**：各 tab 显示词条数（本地过滤后长度，如「黑名单 (12)」）。
- 表格列：多选列 + 词内容（`words`）+ 类型（1→「黑名单」danger 标签 / 2→「白名单」success 标签）+ 创建时间（`createdTime` 原样展示，null → 「—」）+ 操作列（单行删除）。

### T3 本地搜索

- 操作卡左侧搜索框：按词内容 `includes` 即时过滤**当前 tab** 列表（忽略大小写）；搜索与 tab 叠加过滤（交集）；空结果 `empty-text="暂无数据"`。

### T4 批量新增

- 「新增敏感词」按钮 → 对话框：`el-radio-group` 类型（黑名单默认）+ `el-textarea`（多行、每行一词）。
- 提交前处理：逐行 `trim()`、跳过空行、同批内去重（`save` 幂等兜底）；至少一个非空词才可提交。
- 提交：逐条 `save({words, type})`（串行执行、防重入）；**成功 N 条 / 失败 M 条汇总**（失败明细含词内容 + 原因）；全部成功 → 关对话框 + 重拉列表；全部失败 → 对话框保留 + 错误汇总；部分失败 → 汇总提示 + 重拉。
- 单条业务失败（HTTP 200 + code=400）走 `silent` 内联展示（沿用第一批 `response-interceptor` silent，401/403 不豁免）。
- 切换类型时清空已输入文本（防黑/白误放，对话框内提示）。

### T5 批量删除

- 表格多选（可跨 tab——`remove` 按 id 不涉类型）+ 操作栏「批量删除」（选中 >0 可点）+ 选中计数；单行「删除」同流程。
- 确认弹窗（红色警示）：「删除后该词将不再被拦截/放行，确定删除选中的 N 个词？」
- 执行：逐条 `remove({id})`（幂等）；**成功 N / 失败 M 汇总**（失败明细同新增）；完成后重拉列表 + 清空多选。

### T6 公共层（可测纯函数）

- 抽纯函数入 `src/utils/sensitive.ts`（本地分组/过滤/批量行解析 trim 去重/计数/时间占位等），配单测（参照第一批 `src/utils/circle.ts` 7 函数 + 18 用例模式）。
- `src/types/sensitive.d.ts`（`SensitiveWordItemVO` / `SensitiveWordSaveDTO` / `SensitiveWordRemoveDTO` 契约类型）；`src/api/sensitive.ts`（3 端点消费：list / save / remove）。

### T7 质量门禁与验收证据

- `api:check` 基线 74→75 更新（specSha256 见前置基线）并保持通过。
- build / 单测（既有用例零回归 + 新增 sensitive 纯函数用例）/ lint 全绿 + CI SUCCESS。
- 云端网关联调（回执登记）：admin 角色账号登录 → `list` 全量 → 批量新增（黑/白各一批）→ 批量删除 → 重拉核对 → 搜索/切 tab 一致性；401 登录墙、403 非管理员各一轮。
- 回执双轨：`handoff/frontend-to-backend/` 按创建日期目录（Markdown + `*-summary.json` 模板字段齐全）；完成通知四字段（实施 SHA / 回执 SHA / PR 号 / R2 状态）；PR 由用户/F-Review 在 CI 绿后合入（仓库惯例）。

## 2. 验收标准

- [ ] T1-T7 全部落地：`/sensitive` 路由 + 菜单；三 tab + 徽标；本地搜索；批量新增（逐条 save + 部分失败明细）；批量删除（确认 + 逐条 remove + 失败明细）；重拉刷新
- [ ] 3 端点消费与契约一致：list / save / remove（type 1=黑名单 2=白名单；createdTime null → 「—」）
- [ ] api:check 基线 75（specSha256 `6262f444…`）+ build/test/lint/CI 绿
- [ ] 云端 admin 联调证据入回执；回执双轨 + 四字段
- [ ] C 端零改动；管理端既有路由/页面零改动；**不含 fromId 前端切换**（随 B-Impl fromId 落地后的后续小批）

## 3. 约束

- 消费契约以快照 `6262F444` 为准；发现契约问题先写 `proposals/frontend/` 交 PM，不得改基线绕过评审。
- 业务错误统一 HTTP 200 + body code=400 口径展示 message；401 登录墙 / 403 角色墙沿用既有处理（silent 不豁免）。
- 规则 8 敏感信息占位符与 Conventional Commits 照常；不触碰 `api/` 快照与 `status/`。

## 4. 关联

- 本批双轨：B-Impl fromId 小实现任务书（`moment-item-fromid-implementation-task.md`，同一派发 PR）
- 敏感词契约提案 PR #107 · PM 决策 L1-L3 · list 验收 PR #113（快照 6262F444）· D3 fromId 决策 PR #114
