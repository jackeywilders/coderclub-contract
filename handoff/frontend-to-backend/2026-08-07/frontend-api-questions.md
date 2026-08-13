# 前端向后端澄清事项

> 提出方：Frontend Codex
> 日期：2026-08-07
> 关联契约声明：`C1 / 3161c41e70fb1d8c1a976ed4fd862fe04ce344a1`

## 1. 必须先确认的契约文件

交接主仓库和前端 Codex worktree 的
`api/coderclub-openapi.json` 实际 SHA-256 都是
`87e122b545ed529edc167b80279869205440be84e12c4407850dfa1d4ff2166b`；后端 Codex worktree 的文件实际
SHA-256 是 `0057e69c4deb3e769e191fb319a16f00d4d0fe3eec0b0fc3c218c8e55e4ae20c`。请 PM/Backend 确认
哪一份是 C1 唯一基线，并在交接仓库记录最终文件、提交和 SHA-256 的对应关系。前端暂不据此生成客户端
或修改业务代码。

## 2. 重复方法与正式端点

当前 OpenAPI 对分类、标签的部分操作同时出现 POST/PUT 或 POST/DELETE 的同路径定义，例如：

- `/subject/category/update`
- `/subject/category/delete`
- `/subject/label/update`
- `/subject/label/delete`

请确认生产环境应使用的 HTTP 方法、是否保留兼容端点，以及每个端点的鉴权角色。前端会严格按方法调用，
不会仅按 URL 判断操作。

## 3. 认证和运行时行为

请确认 `/auth/login` 实际成功响应是否始终同时提供 `data.token` 和 `data.tokenInfo.tokenValue`，以及
未登录/过期时 HTTP 状态码是否一定为 401，还是可能只返回业务 `code: 401`。还请确认 `/auth/user/password`
是否只需要 `newPassword`（当前契约如此），还是服务端要求旧密码。

## 4. 题目分页口径

交接资料已指出 `/subject/getSubjectPage` 在部分过滤条件下可能出现 `total` 与 `list` 不一致。请提供
可复现过滤条件、期望口径和修复计划；在确认前端验收按响应字段展示并保留请求参数和响应记录是否可接受。

## 5. 回执要求

请在回复中给出：确认后的契约提交与 SHA-256、正式 HTTP 方法清单、鉴权矩阵、401 行为、分页问题复现
条件及对应后端提交/计划。不要通过直接改写 `sync-manifest.json` 代替上述确认。
