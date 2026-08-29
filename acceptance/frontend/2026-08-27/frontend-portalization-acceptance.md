# 前端评审签署：前端门户化阶段一（A8-P1，T1-T6）

> **签署角色：** 前端评审（F-Review）
> **签署日期：** 2026-08-27
> **任务书：** `pm/requirements/2026-08-27/frontend-portalization-task.md`（PR #73，`917cc7eb`）
> **回执：** `handoff/frontend-to-backend/2026-08-27/frontend-portalization-report.md` + `-summary.json`（PR #74 主体 / PR #75 receiptCommitSha 回填，均合入交接仓库 main）
> **实现：** 前端仓库 PR #12（`feat/portal-a8-phase1`，8 commits，merge `cf9d460b`，2026-08-27T04:18:09Z）

## 1. 规则 9 远端证据（人链核验）

| 字段 | 值 |
| --- | --- |
| 实施提交 SHA | `a413b19`（基线46）/`18f90a2`（api 函数）/`5ff840a`（userinfo 对齐）/`7fa0aad`（三栏首页）/`dfe44c7`（搜索页）/`557a94c`（登录）/`a2089d3`（翻页）/`6909558`（门户壳+路由） |
| 合并提交 SHA | `cf9d460b`（Merge pull request #12） |
| 回执提交 SHA | `60d7f5bb`（回执主体，PR #74；PR #75 回填 receiptCommitSha 后同值） |
| PR 号 | 前端仓库 **#12**；交接仓库 #74/#75 |
| R2 状态 | ✅ 均已合入 `main`（前端 main HEAD=`cf9d460b`，API 通道核验；交接仓库 PR #74/#75 已合入） |
| 契约快照 SHA-256 | `4bfb3c72…`（46 endpoints，api 文件实测 SHA-256 `4bfb3c72a445…`，零变更） |

## 2. 复核结论

✅ **A8-P1（T1-T6）复核通过，同意签署。** 门户化六块实现 + 基线 46 端点同步均满足任务书验收标准；回执双轨齐全、证据链完整；附带发现不阻塞。

## 3. 人链核验明细（F-Review 逐项验证，API 通道 + 本地独立验证）

### T1 门户壳 + 路由重构 ✅

- `src/layout/PortalLayout.vue`（新增）：Header（鸡翅CLUB + 刷题激活 / 练题·鸡圈·模拟面试占位「开发中，敬请期待」+ 全局搜索回车→`/search?t=` + 用户菜单：个人资料→`/user/profile`、管理后台→`/dashboard`（仅 admin）、退出→logout 后跳 `/login`）；内容区 `max-w-screen-xl` 居中；`nickName` 展示（T6 对齐）。
- `src/router/routes.ts`：门户 `/` 挂 PortalLayout（`''`→HomeView、`subject/answer/:id`、`search`）；管理端 `/dashboard`、`/subject`（category/label/list/edit/:id?）、`/user`（profile/manage）、`/role/manage`、`/permission/manage` 全保留、URL 不变；**`/subject/browse` 已移除**；404 保留；守卫 `requiresAuth`→`/login`、roles 校验→`/dashboard` 未动。
- `src/layout/Sidebar.vue`：移除「题目浏览」菜单项，无图标引用残留。

### T2 三栏题库首页 ✅（`src/views/home/HomeView.vue`，新增）

- 左栏三级联动：`queryPrimaryCategory({categoryType:0})` → `queryCategoryByPrimary` → `queryLabelByCategoryId`；CSS scroll-snap 横向彩卡自实现（零新依赖）；二级/标签选择联动中栏，清除筛选重置。
- 中栏：`getSubjectPage`（A2 收窄 6 字段，pageNo/pageSize 20、全题型 4 档/难度 3 档）；行点击携带 query 上下文 → 刷题页。
- 右栏：贡献榜 `getContributeList({topN:10})`（userName/nickName/count 降序、前三高亮）+ 练习榜占位。
- 竞态防护：list/secondary/label 三组请求序号令牌（旧响应丢弃）。

### T3 刷题页同页翻页 ✅（`SubjectAnswer.vue`）

- 判对错交互（SubjectAnswerPanel）与「退出答题」按钮保留未改。
- query 上下文（page/categoryId/labelId/subjectType/subjectDifficult）→ `getSubjectPage` 拉当前页（pageSize 20）→ 同页 `router.replace` 切题；跨页拉相邻页（`totalPages` 边界）；首页无上一题/末页无下一题禁用；**刷新可恢复**（query 参数途径）；「题目不存在」空态跳 `/`（原 browse 已移除）；subject/list 双竞态令牌。

### T4 搜索页 ✅（`src/views/search/SearchView.vue`，新增）

- `t` 参数回显 + 自动搜索；`getSubjectPageBySearch({keyWord,pageNo,pageSize20})`；**空串不发请求**（契约语义）；空态「很抱歉，没有找到相关题目」/「输入关键词开始搜索」区分；停留 `/search` 再搜经 `watch route.query.t` 重搜；竞态令牌 + 空路径 loading 复位。

### T5 门户化登录 ✅（`LoginView.vue`）

- 品牌化明色卡片（鸡翅CLUB + 欢迎回来）；账密登录沿用（`/auth/login` userName/password，A10 已对齐）；登录成功跳 `/`；注册次级化（→`/register`）；「微信扫码登录」占位（点击提示「公众号登录配置未就绪，敬请期待」）；`/wx-login` 与 WxLoginView 保留不动。

### T6 userinfo 链路字段对齐 ✅（openFinding `userinfo-fields-mismatch` 闭合）

| 文件 | userName/nickName 落地 | 残留 |
| --- | --- | --- |
| `src/types/auth.d.ts` | UserInfo `userName`/`nickName` | 0 |
| `src/layout/Navbar.vue` | `nickName?.charAt(0)`、`nickName \|\| '用户'` | 0 |
| `src/layout/PortalLayout.vue` | 新建即用 `nickName` | 0 |
| `src/views/user/UserProfile.vue` | `userName` 展示、`nickName` 表单项/提交载荷（对齐 AuthUserUpdateDTO） | 0 |
| `src/views/user/UserManage.vue` | 表格列/类型/查询/确认文案 `userName`/`nickName` | 0 |

（精确区分大小写扫描 `\busername\b`/`\bnickname\b`：5 文件命中 0；初扫的「残留」均为 `userName`/`nickName` 的 case-insensitive 误报，已复核。）

### 配套：基线 46 端点 ✅

- `docs/frontend/handoff/api-docs-baseline.json`：`specSha256` = `4bfb3c72a445…`、`endpointCount=46`；新增 3 端点（getSubjectPageBySearch / getContributeList / auth list-by-identifiers）均在快照中。
- `src/api/subject.ts` 新增 5 函数（queryPrimaryCategory/queryCategoryByPrimary/queryLabelByCategoryId/getSubjectPageBySearch/getContributeList）；auth list-by-identifiers 为后端 Feign 内部用，前端不接。

## 4. 验证证据（本机四命令独立复验 + CI）

| 命令 | 本机结果（2026-08-27，`feature/portal-a8-phase1` 分支 = PR #12 内容） | CI |
| --- | --- | --- |
| `npm run build` | ✅ vue-tsc + vite build exit 0 | — |
| `npm test` | ✅ 10/10 pass, 0 fail | ✅ |
| `npm run api:check` | ✅ SHA `4bfb3c72a445…`，46 endpoints，No changes | ✅ |
| `npm run lint`（全量 `--fix=false`） | ✅ exit 0（A10 清理 worktrees 后全量首轮干净） | ✅ |
| 前端 CI `check`（PR #12） | — | ✅ SUCCESS（run 33038587769，2026-08-27T04:11:03Z） |

## 5. 已知限制（随回执，不阻塞签署）

1. **categoryId 一级过滤语义**待 PM/后端确认（当前取二级 id 等值过滤，保守合理；若后端不支持一级递归过滤需补交互提示，另案）。
2. **组件级单测**受零依赖约束未引 vitest；以类型检查 + 审查 + 时序推演覆盖（回执已记录）。
3. 基线 CRLF→LF 一次性质规范化（脚本固有输出 LF，语义变更仅 3 端点 + 头部）。
4. CI 修复记录（回执 §10.4）：首次推送因 git-data API 通道误用已证伪并全分支重推，远端 blob 与本地原文 9/9 SHA 匹配，CI 复跑 SUCCESS——已核验远端当前 main 文件完好（PersonaReview 通过）。

## 6. 附带建议（不阻塞）

- categoryId 一级过滤语义确认后，若需交互提示随另案处理。
- 阶段二（练题/鸡圈/面试、点赞收藏、练习榜启用）按 A8 设计推进。

## 7. 签署意见

✅ **签署通过**。A8-P1（T1-T6）实施与回执满足任务书验收标准（门户壳/路由、userinfo 对齐、基线 46、CI 全绿），同意转协调 PM 验收（阶段一收尾、state 评估、云端验证衔接 A8-P1-BE 已知限制）。

## 8. 版本记录

- 2026-08-27：创建（前端评审签署，转 PM 验收）。