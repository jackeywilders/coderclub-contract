# CoderClub 后端 API 契约基线

## 1. 基线信息

| 项目 | 值 |
| --- | --- |
| 后端项目 | `G:/Dev/backend/Club/CoderClub` |
| 后端分支 | `main` |
| 后端源码提交 | `085fe08dd74481415a9b0e4abe97aeb3c672353b` |
| 交接仓库 C0 基线 | `7e3f77b49627dab501c45c0548f08d5334f3ed48` |
| 权威 API 文件 | `docs/api/coderclub-openapi.json` |
| OpenAPI 版本 | `3.0.3` |
| 文档版本 | `1.0.0` |
| 路径数量 | 45 |
| 操作数量 | 47 |
| 源文件 SHA-256 | `44cbe709887e840174d1bdd02f32a423561013e0622b81e76c9346d2e87e265a` |
| 交接 API 文件 | `api/coderclub-openapi.json` |
| 交接文件 SHA-256 | `0057e69c4deb3e769e191fb319a16f00d4d0fe3eec0b0fc3c218c8e55e4ae20c` |

交接仓库中的 API 文件是本次确认的消费副本。为避免把示例凭据传播给前端，副本中的示例密码替换为 `<password>` 或 `<new-password>`，示例 Token 替换为 `<token>`；字段名、Schema、接口路径和鉴权说明均保持不变。后端项目中的 `docs/api/coderclub-openapi.json` 仍是权威来源。

## 2. 服务边界

| 服务 | OpenAPI Server | 主要路径 |
| --- | --- | --- |
| Auth 认证服务 | `http://localhost:3100` | `/auth/**` |
| Subject 题目服务 | `http://localhost:3000` | `/subject/**` |
| OSS 文件服务 | `http://localhost:3200` | `/oss/**` |

契约覆盖认证、用户、角色、权限、分类、标签、题目和文件存储接口，共 45 个路径、47 个 HTTP 操作。路径相同但 HTTP 方法不同的操作必须按 OpenAPI 中声明的方法调用；当前文档同时保留了部分历史兼容的 `POST`/`PUT` 或 `POST`/`DELETE` 操作。

## 3. 运行时约定

### 3.1 统一响应

成功和失败响应均使用四个字段：

```json
{
  "success": true,
  "code": 200,
  "message": "操作成功",
  "data": null
}
```

- 无业务载荷时，`data` 为 `null`。
- 列表无结果时，`data` 为 `[]`。
- 分页无结果时，`data.list` 为 `[]`，同时保留 `pageNo`、`pageSize`、`total`、`totalPages`。
- 参数校验失败时，错误响应的 `data` 可能是字符串数组；其他业务异常通常为 `null`。

### 3.2 鉴权

- 登录接口：`POST /auth/login`、`POST /auth/wx-login` 返回登录 Token。
- 需要鉴权的请求在 `Authorization` 请求头中直接携带原始 Token。
- 不添加 `Bearer ` 前缀：`Authorization: <token>`。
- 前端应在登出、Token 过期或鉴权失败后清理本地凭据并重新登录。

### 3.3 分页与树形数据

- 分页请求使用 `pageNo`、`pageSize` 及接口定义的过滤字段。
- 分页响应字段为 `pageNo`、`pageSize`、`total`、`totalPages`、`list`。
- 权限树和分类树使用递归 `children` 字段；前端应按树节点结构消费，不应假设只有两级。
- 聚合用户信息中的 `roles` 是角色编码列表；`permissions` 当前是权限表主键 ID 字符串列表，不是权限标识字符串。

## 4. 实施与验证约束

发布前必须同时记录后端源码提交、OpenAPI 版本、文档版本、接口数量和 SHA-256。修改路径、方法、请求字段、响应字段、鉴权方式或错误码时，必须先在交接仓库的 `proposals/backend/` 建立提案并完成协调确认，不应直接把未确认变更作为前端契约。

本次基线已完成以下静态校验：交接 API 文件可被 JSON 解析，`openapi` 等于 `3.0.3`，示例密码和 Token 已脱敏，未发现本机绝对路径。`status/sync-manifest.json` 未修改。

## 5. 已知风险

`/subject/getSubjectPage` 在部分过滤条件下存在 `total` 与 `list` 口径可能不一致的历史风险，暂不阻塞本次契约基线发布，移交 M4 继续核验并决定是否提出契约或实现修复。
