# 前端门户化实施回执（A8-P1：T1 门户壳/路由 + T2 三栏首页 + T3 翻页 + T4 搜索 + T5 登录 + T6 userinfo 对齐 + 基线 46 端点）

> 回执角色：前端实现（F-Impl）
> 回执日期：2026-08-27
> 任务书：`pm/requirements/2026-08-27/frontend-portalization-task.md`（派发 PR #73，`917cc7eb`）
> 依据：`docs/agents/verification-workflow.md` §6 双轨（Markdown + `*-summary.json`）
> 契约快照：`4bfb3c72…`（零变更，本任务未改交接仓库 `api/` 快照与 `sync-manifest.json`）

## 1. 来源与提交哈希

| 字段 | 值 |
| --- | --- |
| 来源项目 | `G:/Dev/backend/Club/CoderClubFront`（前端代码仓库，private） |
| 来源分支 | `feat/portal-a8-phase1`（基于 main `3d34dc6` 创建，8 commits 一体交付） |
| 实施提交 SHA | `a413b19`（docs 基线46）、`18f90a2`（api 函数）、`5ff840a`（userinfo 对齐）、`7fa0aad`（三栏首页）、`dfe44c7`（搜索页）、`557a94c`（登录门户化）、`a2089d3`（刷题翻页）、`6909558`（门户壳+路由） |
| 合并提交 SHA | `cf9d460b`（Merge pull request #12，mergedAt 2026-08-27T04:18:09Z，合入授权 = 用户，F-Impl 经 GitHub MCP 执行 merge） |
| PR 号 | 前端仓库 **#12** |
| R2 状态 | ✅ 已合入 `main`（远端核验：`main` HEAD = `cf9d460b`，API 通道） |
| 契约快照 SHA-256 | `4bfb3c72…`（交接仓库当前快照，本任务零变更） |

## 2. T1 门户壳 + 路由重构

- 新建 `src/layout/PortalLayout.vue`：顶部 Header（Logo「鸡翅CLUB」+ 主菜单 刷题(激活)/练题/鸡圈/模拟面试(占位提示「开发中，敬请期待」) + 全局搜索框(回车→`/search?t=`) + 用户菜单 个人资料/管理后台(仅 admin)/退出）+ 内容区 `max-w-screen-xl` 居中 + 明色主题；`userInfo.nickName` 展示（T6 对齐）。
- `src/router/routes.ts` 重构：门户 `'/'` 挂 PortalLayout（`''`→HomeView 题库、`subject/answer/:id`、`search`）；管理端按模块分包挂 MainLayout（`/dashboard`、`/subject`(category/label/list/edit/:id?)、`/user`(profile/manage)、`/role/manage`、`/permission/manage`）——**URL 全保持**；**移除 `/subject/browse` 路由**（`SubjectBrowse.vue` 文件保留）；404 保留；守卫（`requiresAuth`/`roles` meta 子级继承）未动。
- `src/layout/Sidebar.vue`：移除已废弃「题目浏览」菜单项（`Reading` 图标为全局注册无 import 残留，全仓已清零该图标引用）。

## 3. T2 三栏题库首页（`src/views/home/HomeView.vue`）

- 左栏分类三级联动：`queryPrimaryCategory({categoryType:0})` → `queryCategoryByPrimary({categoryType,parentId})` → `queryLabelByCategoryId({categoryId})`（CSS scroll-snap 横向彩卡自实现，零新依赖）；二级选中 → 中栏 `categoryId` 过滤、标签选中 → `labelId` 过滤；「清除筛选」重置。
- 中栏题目列表：`getSubjectPage`（A2 收窄 6 字段 `pageNo/pageSize20/subjectType?/subjectDifficult?/categoryId?/labelId?`）；全题型/3 难度筛选；行点击 → 刷题页携带 query 上下文（page/categoryId/labelId/subjectType/subjectDifficult，未选传空串）；el-pagination。
- 右栏：出题贡献榜 `getContributeList({topN:10})`（userName/nickName/count 降序，前三名高亮）+ 综合练习榜占位「敬请期待」。
- 列表/级联加载带请求序号令牌竞态防护（各任务修复轮）。

## 4. T3 刷题页同页翻页（`src/views/subject/answer/SubjectAnswer.vue`）

- 保留判分交互（`SubjectAnswerPanel` 行为未改）与「退出答题」按钮。
- 翻页采用任务书首选方案：query 上下文（page/categoryId/labelId/subjectType/subjectDifficult）→ `getSubjectPage` 拉当前页列表（pageSize 20）→ 列表内相邻 id 同页切题（`router.replace` 保持上下文）；跨页拉相邻页（`data.totalPages` 边界）；首页无上一题/末页无下一题禁用；**刷新可恢复**。
- 「题目不存在」空态按钮改跳 `'/'`（原 `/subject/browse` 已移除）；点赞/收藏未实现（本期外）。

## 5. T4 搜索页（`src/views/search/SearchView.vue`）

- `t` 参数回显 + 自动搜索；`getSubjectPageBySearch({keyWord,pageNo,pageSize20})`；**空串不发请求**（契约语义）；空态「很抱歉，没有找到相关题目」；列表项题目名/题型/难度/标签，点击 → 刷题页（page 上下文）；分页。
- 头部搜索复用接线：`watch route.query.t`（停留 `/search` 再搜可重搜）；竞态令牌 + 空路径 loading 复位（修复轮覆盖）。

## 6. T5 门户化登录（`src/views/login/LoginView.vue`）

- 品牌化明色卡片（「鸡翅CLUB」+「欢迎回来」）；账密登录沿用（`/auth/login` userName/password，A10 已对齐）；登录成功跳 `'/'`；注册入口次级化；「微信扫码登录」占位按钮（点击提示「公众号登录配置未就绪，敬请期待」；`/wx-login` 路由与 WxLoginView 保留不动）。

## 7. T6 userinfo 链路字段对齐（openFinding `userinfo-fields-mismatch` 闭合）

`userName`/`nickName` 对齐：`src/types/auth.d.ts`（UserInfo）、`src/layout/Navbar.vue`、`src/layout/PortalLayout.vue`（新建即用新字段）、`src/views/user/UserProfile.vue`（含提交载荷 `updateUserInfo` 键 `nickName`，对齐 `AuthUserUpdateDTO`）、`src/views/user/UserManage.vue`（表格列/接口/确认文案）——全链路消费残留为 0（形参/注释除外）。

## 8. 配套：前端契约基线 46 端点同步

- 本地快照 `local/coderclub-openapi.json`（SHA `4bfb3c72a445…`，46 endpoints）→ `npm run api:check` 确认恰 3 端点新增（`POST /auth/user/list-by-identifiers`、`POST /subject/getContributeList`、`POST /subject/getSubjectPageBySearch`）→ `--update-baseline` 更新 `docs/frontend/handoff/api-docs-baseline.json`（46 endpoints，`specSha256` `4bfb3c72…`）→ 复跑 `No API contract changes detected`。
- `src/api/subject.ts` 新增 5 个函数：`queryPrimaryCategory`/`queryCategoryByPrimary`/`queryLabelByCategoryId`/`getSubjectPageBySearch`/`getContributeList`（auth list-by-identifiers 为后端 Feign 内部用，前端不接）。

## 9. 验证结果

| 命令 | 结果 |
| --- | --- |
| `npm run build` | vue-tsc --noEmit + vite build exit 0（全懒加载解析） |
| `npm test` | 10/10 pass，exit 0 |
| `npm run api:check` | SHA `4bfb3c72a445…`，46 endpoints，No changes，exit 0 |
| `npm run lint`（主范围 src/scripts） | exit 0（全量 lint 受本机遗留 `.worktrees/` 干扰为环境问题；CI 干净 clone 无此 issue） |
| `git diff --check` | 干净 |
| 前端 CI | PR #12 `check` SUCCESS（run 33038587769，2026-08-27T04:11:03Z 完成） |
| 审查 | SDD 逐任务实现 + 任务级审查（含 4 轮修复）+ 全分支最终宽范围审查 PASS（零 Critical/零 Important） |

## 10. 已知限制（不阻塞合入，最终审查确认）

1. **categoryId 一级过滤语义**（任务书规格空白，待 PM/后端确认）：`getSubjectPage.categoryId` 是否支持按一级分类递归过滤；当前前端取二级分类 id（叶子级等值过滤，保守合理）。若后端不支持一级过滤，一级选中仅展开二级候选而不过滤列表——需补交互提示（另案）。
2. **组件级单测**：仓库无 .vue 测试运行器且本任务零新依赖约束（未引 vitest）；竞态/交互以类型检查 + 代码审查 + 手工时序推演覆盖（任务报告已记录）。
3. 基线文件 CRLF→LF 一次性质整文件换行（脚本 `check-api-spec.mjs` 固定输出 LF；语义变更仅 3 端点 + 头部；后续可加 `.gitattributes eol=lf` 规范化）。
4. CI 修复记录：首次推送因 git-data API 通道误用（blob `content` 按 base64 语义传入致存为 base64 文本）致 3 个 .ts 解析失败；已查明（最小实验证实 blobs API 直接存明文）并全分支重推（明文 content），远端 blob 与本地原文 9/9 SHA 匹配核验，CI 复跑 SUCCESS。

## 11. 声明

- 未修改交接仓库 `api/` 快照、`status/sync-manifest.json` 与任何治理文件；未触碰后端项目（规则 8/19）。
- 提交/PR 无真实环境信息（规则 8）；远端操作（分支/提交/PR/合入）经 GitHub MCP / API 通道（规则 17）。
- 前端 main 已合入（`cf9d460b`）；本地前端仓库 main 停留旧提交（git 传输受限未 fetch），以远端核验为准。

## 12. 版本记录

- 2026-08-27：创建（任务书派发后经 SDD 全流程实施；PR #12 合入 main 后落回执）。
