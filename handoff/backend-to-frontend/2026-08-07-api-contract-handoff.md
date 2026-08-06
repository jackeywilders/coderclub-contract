# 后端 API 契约交接

## 1. 交接结论

CoderClub 后端已提供可供前端消费的 OpenAPI 3.0.3 契约副本。请使用交接仓库中的 `api/coderclub-openapi.json` 导入或生成客户端；该文件对应后端源码提交 `085fe08dd74481415a9b0e4abe97aeb3c672353b`，交接仓库 C0 基线为 `7e3f77b49627dab501c45c0548f08d5334f3ed48`。

## 2. 文件与版本

| 项目 | 值 |
| --- | --- |
| OpenAPI 文件 | `api/coderclub-openapi.json` |
| OpenAPI 版本 | `3.0.3` |
| 文档版本 | `1.0.0` |
| 路径 / 操作 | 45 / 47 |
| 后端源文件 SHA-256 | `44cbe709887e840174d1bdd02f32a423561013e0622b81e76c9346d2e87e265a` |
| 交接副本 SHA-256 | `0057e69c4deb3e769e191fb319a16f00d4d0fe3eec0b0fc3c218c8e55e4ae20c` |

交接副本保留完整接口结构，但已将 OpenAPI 示例中的密码替换为 `<password>` / `<new-password>`，Token 替换为 `<token>`。联调时必须使用实际登录接口返回的 Token，不要把占位符作为凭据发送。

## 3. 前端联调前置条件

1. 启动 Nacos、Redis、MySQL，并准备后端服务所需的有效配置。
2. 启动 Auth、Subject、OSS 服务，默认地址分别为 `http://localhost:3100`、`http://localhost:3000`、`http://localhost:3200`。
3. 前端按服务地址或项目现有代理规则设置 API base URL；不要把一个服务的 base URL 套用于其他服务。
4. 先调用 `POST /auth/login` 或 `POST /auth/wx-login` 获取 Token，再调用需要鉴权的接口。
5. 文件上传使用 `multipart/form-data`；文件 URL 查询和上传接口位于 OSS 服务。

## 4. 前端必须遵守的接口行为

- 所有响应按 `success`、`code`、`message`、`data` 四字段解析。
- `data: null` 表示本次操作没有业务载荷；数组接口无数据时使用空数组。
- 分页数据从 `data.list` 读取，分页元数据读取 `data.pageNo`、`data.pageSize`、`data.total`、`data.totalPages`。
- `Authorization` 头直接发送原始 Token，不加 `Bearer ` 前缀。
- 分类树和权限树按递归 `children` 渲染。
- `roles` 为角色编码；聚合用户信息中的 `permissions` 为权限表 ID 字符串，若需要权限标识应结合权限树按节点 ID 查找。
- OpenAPI 中同一路径可能声明多个 HTTP 方法；请求方法必须与具体操作一致，不能只按路径判断。

## 5. 前端首轮联调顺序

1. 认证：注册、登录、当前用户信息、登出。
2. 权限：角色列表、权限树及聚合用户权限信息。
3. 题库基础数据：分类树、分类查询、标签查询。
4. 题目：题目列表、分页、详情、新增、更新、删除。
5. 文件：上传和 URL 获取。

## 6. 已知事项与回传要求

`/subject/getSubjectPage` 在部分过滤条件下可能出现 `total` 与当前 `list` 口径不一致，前端暂按响应字段展示并记录实际请求参数、响应和复现条件，移交 M4 继续处理。接口字段差异按当前 OpenAPI 适配，除非后端另行发布已确认契约变更，不要求前端反向修改后端代码。

前端完成导入和首轮联调后，请回传：使用的契约 SHA-256、实际服务地址、已验证接口清单、失败接口的请求参数/响应 `code`/`message` 和可复现条件。
