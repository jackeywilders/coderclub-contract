# CoderClub 前端 API 契约影响分析

> 角色：Frontend Codex（设计、API 影响分析、前端验收）
> 日期：2026-08-07
> 范围：只记录设计和验收约束，不修改前端业务代码。

## 1. 契约基线核对

本轮声明的契约为 `C1 / 3161c41e70fb1d8c1a976ed4fd862fe04ce344a1`，预期 SHA-256 为
`0057e69c4deb3e769e191fb319a16f00d4d0fe3eec0b0fc3c218c8e55e4ae20c`。前端检查实际读取：

`G:\Dev\backend\Club\coderclub-contract\api\coderclub-openapi.json`

该文件实际 SHA-256 为 `87e122b545ed529edc167b80279869205440be84e12c4407850dfa1d4ff2166b`，因此
哈希核对未通过。后端 Codex worktree 中另有文件实际为预期的 `0057e69...`；两份文件需要由 PM
确认后再作为唯一基线。当前文件仍可解析为 OpenAPI 3.0.3，包含 45 个路径、47 个操作。

`npm run api:check` 和 `npm test` 首次执行均因本机 `nvm-desktop` 未设置默认 Node 版本退出（exit 1）。
使用桌面运行时 Node 24.14.0 直接执行等价脚本后，API 检查显示 `No API contract changes detected`，
契约测试 2/2 通过；这只能证明结构快照一致，不能消除 SHA-256 不一致。

## 2. 受影响的 API 模块与类型

| 模块 | API 层 | 类型与状态 | 主要页面/路由 |
| --- | --- | --- | --- |
| 认证与用户 | `src/api/auth.ts` | `ResponseResult<T>`、`LoginDTO`、`LoginResponse`、`UserInfoVO`、`PasswordUpdateDTO` | `/login`、`/register`、`/wx-login`、`/user/profile` |
| 角色与权限 | `src/api/auth.ts` 或独立 `permission.ts` | `AuthRoleBO`、`AuthPermissionTreeItem`、角色/权限分配 DTO | `/role`、`/permission`、动态菜单 |
| 题库分类与标签 | `src/api/subject.ts` | `SubjectCategoryDTO`、`SubjectLabelDTO`，树节点递归 `children` | `/subject/category`、`/subject/label` |
| 题目 | `src/api/subject.ts` | `SubjectInfoDTO`、`SubjectAnswerDTO`、`SubjectPageQueryDTO`、`PageResultSubjectInfo` | `/subject/list`、`/subject/edit/:id`、`/subject/browse`、`/subject/answer/:id` |
| 文件 | `src/api/oss.ts` | `ResponseResultString`、上传文件响应 | 头像/题目资源上传 |

通用适配规则：所有响应读取 `success/code/message/data`；分页读取 `data.list`、`pageNo`、`pageSize`、
`total`、`totalPages`；`data: null` 表示无业务载荷。登录请求字段是 `userName`，登录响应优先读取
`data.token`，并将原始 Token 直接放入 `Authorization`，不添加 `Bearer `。用户信息中的 `roles` 是角色
编码，`permissions` 是权限表 ID 字符串，权限标识必须通过权限树按 ID 解析。

题目页面必须保留 `subjectType` 1/2/3/4 的四种题型分支，使用 `optionList` 和 `subjectAnswer` 映射
答案；分类树和权限树均按 `children` 递归渲染。所有 ID 在 TypeScript 中统一按 `number` 处理，展示层
再格式化为字符串。

## 3. Store、路由和页面设计

- `user` store 管理 Token、当前用户、角色、权限；登录后立即调用 `/auth/user/info`，登出时无论后端
  请求是否成功都清理本地状态。
- `permission` store 保存角色和权限树，负责动态路由、侧边菜单及按钮级权限；`admin_user` 才能进入
  用户、角色、权限和题库管理写操作页面。
- `subject` 相关状态按页面查询条件、分页结果和详情拆分，避免把管理列表筛选条件复用到用户浏览页。
- 静态公开路由为 `/login`、`/register`、`/wx-login`；其余路由由登录守卫保护。失去权限时回到
  `/dashboard`，Token 失效时清理状态并回到 `/login`。
- 页面实现顺序：认证与用户信息 → 角色/权限 → 分类/标签 → 题目列表与详情 → 上传 → 浏览和答题。

## 4. 加载、空、错误和提交状态

每个列表页必须有独立 loading 状态、空列表提示和可重试的局部错误状态；详情页使用 skeleton 或
明确的加载占位。提交按钮在请求期间禁用并显示 loading，成功后刷新对应列表，失败保留表单输入。
HTTP 401 与业务 `code === 401` 都要触发登出流程；403 显示无权限但不清除登录态；网络错误显示
可理解的错误信息。分页结果以服务端 `total` 为准，同时记录 `/subject/getSubjectPage` 已知的
`total` 与当前 `list` 可能不一致问题。

## 5. 验收条件

1. API 文件可解析，C1 提交哈希和 SHA-256 经 PM 确认一致后，`npm run api:check` 无未审查差异。
2. 登录、注册、登出、当前用户、修改资料和修改密码的请求方法、字段名、Token 注入和错误处理正确。
3. 管理员和普通用户的动态路由、菜单、按钮权限分别符合角色；权限 ID 不被误当作权限 key。
4. 分类树、标签筛选、题目分页、详情、四种题型答案渲染和 OSS 上传覆盖成功、空、加载、401、403、
   网络错误及重复提交场景。
5. 前端实现完成后运行 `npm test`、`npm run api:check`、`npm run lint`、`npm run build`，并记录实际
   服务地址、接口清单、失败响应和复现条件。

## 6. 当前实现边界

本轮不修改 `src/`、构建配置或权威 API 文件。契约哈希、重复 HTTP 方法定义以及题目分页口径确认后，
再由 Claude Code 按本设计实施；任何契约变更先进入 `proposals/frontend/` 或 `proposals/backend/`。

## 7. 2026-08-10 Gate 0/1 补充

Backend 已确认后端项目 `main@e80aaf697fecd350ad478d8fed67eb81fdf45325` 的
`docs/api/coderclub-openapi.json` 是权威源，SHA-256 为
`44cbe709887e840174d1bdd02f32a423561013e0622b81e76c9346d2e87e265a`。前端的被忽略路径配置已指向
该源文件；此前交接副本 `87e122...` 不再作为消费输入。Backend 回执声明的脱敏副本 `0057e69...`
与当前主线可观察文件仍不一致，需由 PM 完成唯一映射后才能关闭 Gate 0。

Backend 已提供 47 个操作的运行时矩阵、401/403 语义、正式 PUT/DELETE 方法和分页修复证据。前端
验收确认分类/标签更新和删除已使用正式 PUT/DELETE；但当前 `src/api/index.ts` 只按 HTTP 状态处理
401/403，没有处理成功 HTTP 响应中的业务 `code=401/403`，且缺少拦截器测试，因此 G1-02 前端部分
保持阻塞。Node 22.14.0/npm 10.9.2 下，使用临时 PATH 覆盖执行的 `npm run api:check` 和 `npm test`
均通过；默认 `nvm-desktop` 入口仍未配置，不视为永久环境恢复。
