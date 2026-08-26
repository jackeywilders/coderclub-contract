# 任务书：前端门户化实施（A8 阶段一前端，T1-T6 一体交付）

> **派发角色：** 协调 PM
> **派发日期：** 2026-08-27
> **执行角色：** 前端实现（F-Impl）
> **复核角色：** 前端评审（F-Review）
> **设计依据：** `docs/superpowers/specs/2026-08-26-a8-frontend-portal-design.md`（PR #64，已批准）§4
> **后端就绪：** 快照 46 端点（`api/coderclub-openapi.json`，SHA `4BFB3C72`，PR #72 已合入）——搜索/贡献榜/批量用户查询端点已可用
> **关联 openFinding：** `userinfo-fields-mismatch`（pm.json，A10 发现）——本任务 T6 一并处理

## 1. 目标

把前端从「后台管理形态」重构为「门户形态」：顶部 Header 门户壳 + 题库即首页（三栏）+ 刷题页（判对错 + 同页翻页）+ 搜索页 + 门户化登录（扫码占位），并完成用户信息链路契约字段对齐。管理端（dashboard 布局及全部管理路由）原样保留。

## 2. 实施边界（仅以下范围，禁止扩大）

### T1 门户壳（PortalLayout + 路由重构）

- 新建门户布局（参照现有布局实现方式）：顶部 Header（Logo「鸡翅CLUB」+ 主菜单四项 + 全局搜索框 + 用户菜单）+ 内容区（约 1200px 居中）+ 明色主题（亮色 + 白卡 + 分类彩卡，Element Plus 默认蓝为主色）。
- Header 细节：
  - 主菜单：**刷题**（激活，`/`）+ **练题** / **鸡圈** / **模拟面试**（占位，点击 `ElMessage` 提示「开发中，敬请期待」）。
  - 搜索框：回车 → 跳 `/search?t=关键词`。
  - 用户菜单：个人资料（→ `/user/profile`，沿用管理页）、管理后台（→ `/dashboard`）、退出（调 `/auth/logout` 后清登录态跳 `/login`）。
- 权限守卫：门户布局下无登录态 → 跳 `/login`（沿用现有登录态机制）。
- 路由组织：
  - 门户布局：`/`（题库首页）、`/subject/answer/:id`（刷题页，从管理布局移入）、`/search`（搜索页，新增）、`/login`（门户视觉登录页）。
  - 管理布局保留：`/dashboard`、`/subject/category|label|list|edit/*`、`/user/profile|manage`、`/role/manage`、`/permission/manage`、404。
  - **原 `/subject/browse` 从管理布局移除**（浏览功能由门户首页 `/` 承接，管理端浏览经 `/subject/list`）。

### T2 三栏题库首页（门户首页 `/`）

- 左栏「分类三级联动」：大类横向滚动卡片（CSS scroll-snap 自实现横向滚动，不引入 Swiper 依赖；分类彩卡色板实现期自定）→ 二级分类 → 三级标签；数据源组合：`queryPrimaryCategory` → `queryCategoryByPrimary` → `queryLabelByCategoryId`（**零新增接口**）；切换联动刷新中栏列表。
- 中栏「题目列表」：`getSubjectPage`（A2 收窄后 6 字段：pageNo/pageSize/subjectType/subjectDifficult/categoryId/labelId）；**全题型**（1 单选/2 多选/3 判断/4 简答）、**难度 3 档**（1 简单/2 中等/3 困难）、分页（默认 20/页）；题目行点击 → 刷题页（携带列表上下文 query 参数，见 T3）。
- 右栏「排行榜」：出题贡献榜（`getContributeList`：userName/nickName/count 降序展示）+ 综合练习榜（占位卡片「敬请期待」，阶段二启用）。

### T3 刷题页（`/subject/answer/:id`）

- 保留现有「做题判对错」交互（`SubjectAnswerPanel` 不做行为改动）；退出按钮保留（A10 已合入）。
- 新增同页「上一题/下一题」翻页：路由查询参数携带列表上下文（`page`/`categoryId`/`labelId`/`subjectType`/`subjectDifficult`）；
  - 翻页机制（推荐实现）：同页内切换题目 id，下一题/上一题的 id 来源 = 按上下文重新调用 `getSubjectPage` 取该页列表（可靠、刷新可恢复）；若实现简便可行，可用轻量内存缓存（sessionStorage 级）替代，但**必须满足刷新后仍可翻页**（即上下文参数途径必须可用）。
  - 边界：首页无「上一题」、末页无「下一题」（按钮禁用）；越页时按上下文拉取对应页。
- 点赞/收藏交互**延后**（不在本任务）。

### T4 搜索页（`/search`，新增）

- 顶部搜索框（带 `t` 参数回显）+ 结果列表：`getSubjectPageBySearch`（`keyWord` + pageNo/pageSize；可选复用 subjectType/subjectDifficult/categoryId/labelId 筛选，阶段一前端可不传）；列表项展示题目名/摘要，点击 → 刷题页（携带上下文）。
- 空态：「很抱歉，没有找到相关题目」。
- 契约语义（后端已实现）：keyWord 缺失 400；空串 → 空列表（不 400）——前端不发空串请求。

### T5 登录与扫码占位（`/login` 门户化）

- 登录页门户视觉改造（品牌化卡片、明色）；账密登录沿用（`/auth/login` userName/password，A10 已对齐）；注册入口保留但次级化（次级链接 → `/register`，现有注册页不改动）。
- 「微信扫码登录」入口：占位按钮，点击提示「公众号登录配置未就绪，敬请期待」；契约 `/auth/wx-login` 已存在，真实对接待公众号资源到位（真实凭据占位符约定、不落库，本任务不做资源对接）。

### T6 用户信息链路契约字段对齐（openFinding `userinfo-fields-mismatch`）

契约 `UserInfoVO`/`LoginUserInfo`/`AdminAuthUser` 字段为 `userName`/`nickName`，对齐以下文件（`username`/`nickname` → `userName`/`nickName`，含类型定义、展示与提交载荷）：

- `src/types/auth.d.ts`
- 门户 Header 用户信息展示（原 `layout/Navbar.vue` 对应部分）
- `src/views/user/UserProfile.vue`
- `src/views/user/UserManage.vue`

### 配套（必做）：前端契约基线同步

- `docs/frontend/handoff/api-docs-baseline.json`（前端 api:check 基线）从 43 端点更新为 **46 端点**（同步快照 `4BFB3C72` 对应新增 3 端点：getSubjectPageBySearch/getContributeList/auth user list-by-identifiers + 相关 schema 引用）；`npm run api:check` 通过（基线 SHA 从 `0dae8d3a` 更新）。

## 3. 禁止事项

- 不修改后端项目、交接仓库 `api/` 快照、`status/sync-manifest.json` 及任何治理文件（契约快照 `4BFB3C72` 零变更）。
- 不引入新依赖（横向滚动自实现；不引 Swiper 等）。
- 不重写/不改管理端功能逻辑（T6 字段对齐除外）；不改变答题判分行为；不做扫码真实对接。
- 不扩大范围：点赞/收藏、练题/鸡圈/面试页面、个人中心门户化均不在本任务。

## 4. 交付与回执（规则 9 双轨）

1. 实施提交推送到前端仓库（`G:/Dev/backend/Club/CoderClubFront`），提交信息按 Conventional Commits（如 `feat(portal): portal layout + home tri-column (A8 phase-1)`、`feat(subject): same-page prev/next in answer (A8 phase-1)`、`feat(search): search page (A8 phase-1)`、`fix(auth): align user-info chain fields userName/nickName (A8 phase-1)`）；建议单 PR 或按模块多 PR（由你定，回执注明）。
2. 回执双轨提交到交接仓库 `handoff/frontend-to-backend/2026-08-27/`：Markdown 正文（来源与提交哈希表、T1-T6 逐项明细、路由/组件清单、基线同步证据、验证输出）+ 同目录 `*-summary.json`（模板字段：`taskId=A8-P1-FE`、`sourceProject=G:/Dev/backend/Club/CoderClubFront`、`contractSnapshotSha256=4bfb3c72`（零变更）、`verificationResult`、`verificationDate`）。
3. 完成通知带规则 9 四字段（实施 SHA、回执 SHA、PR 号、R2 状态），告知前端评审复核签署；回执经 `claude/frontend-proposals` PR 合入交接仓库 main（governance-check 自动合并）。
4. 前端评审复核签署后通知 PM；PM 验收后推进阶段一收尾（state 评估、云端真实验证衔接 A8-P1-BE 已知限制）。

## 5. 验收标准

- [ ] 门户壳/路由重构完成：`/` 三栏首页、`/subject/answer/:id` 门户化 + 同页翻页（刷新可恢复）、`/search` 可用、`/login` 门户化 + 扫码占位；原 `/subject/browse` 已移除；管理布局路由完整可用
- [ ] userinfo 链路 `userName`/`nickName` 对齐（T6 文件无 `username`/`nickname` 消费残留——形参/注释除外）
- [ ] 前端基线 46 端点同步 + `npm run api:check` 通过（基线 SHA 更新记录）
- [ ] `npm test` 无回归 + 新增用例（门户路由守卫/搜索空态等，范围实现期定并记录）；`npm run lint`、`npm run build` 通过
- [ ] 回执双轨落 `handoff/frontend-to-backend/2026-08-27/`，通知带四字段远端证据

## 6. 关联

- 设计：`docs/superpowers/specs/2026-08-26-a8-frontend-portal-design.md`（PR #64）
- 后端端点决策：`pm/reviews/2026-08-26/portal-phase1-search-contribute-proposal-decision.md`（PR #68）；实现验收 `acceptance/backend/2026-08-26/a8-phase1-endpoints-implementation-acceptance.md`（PR #72）
- 契约快照：`api/coderclub-openapi.json`（46 端点，`4BFB3C72`）
- openFinding：`userinfo-fields-mismatch`（pm.json）
- 前端评审复核：签署回执（`acceptance/frontend/2026-08-27/`）后转 PM 验收