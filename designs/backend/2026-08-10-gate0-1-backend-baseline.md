# Gate 0/1 后端设计与验证基线

## 1. 基线定位

本基线用于回应 PM 的 Gate 0/1 契约归一化清单，范围限定为后端：权威 OpenAPI 来源核验、运行时鉴权矩阵、正式 HTTP 方法说明、分页统计修复和回归验证。

| 项目 | 值 |
| --- | --- |
| 后端项目 | `G:/Dev/backend/Club/CoderClub` |
| 后端分支 | `main` |
| API 来源提交 | `e80aaf697fecd350ad478d8fed67eb81fdf45325` |
| Gate 0 C0 | `7e3f77b49627dab501c45c0548f08d5334f3ed48`（交接仓库基线） |
| 实现修复提交 | `06397f444f094a577cfde3f8684ae4f60622e871d`、`08cd88c8935371e0bfd07689ed6a9c0ae549a2a1` |
| OpenAPI | `3.0.3` |
| 文档版本 | `1.0.0` |
| 路径 / 操作 | `45 / 47` |

## 2. 后端运行契约

- 匿名操作仅限 Auth 注册/登录/微信登录/账号绑定和 OSS 当前三个接口，共 7 个。
- 普通登录操作要求有效 Token，共 36 个。
- Auth 管理用户的 4 个操作要求 `admin_user` 角色；无登录返回 401，已登录但无该角色返回 403。
- Auth 和 Subject 的 `GlobalExceptionHandler` 将 `NotLoginException` 映射为 HTTP 401、业务 `code=401`；Auth 的 `NotRoleException`/`NotPermissionException` 以及 Subject 的 `NotPermissionException` 映射为 HTTP 403、业务 `code=403`。
- 分类、标签的 PUT/DELETE 是正式方法，历史 POST 端点仍保留兼容；兼容期和移除版本由 PM 最终决定。
- 题目分页的 count 查询必须与 `SubjectInfoMapper.xml` 的列表过滤条件保持同一连接和 WHERE 口径。

## 3. 验证边界

本次已完成单元、MockMvc 和 JSON 静态验证；未在本回执中启动外部 Nacos、Redis、MySQL 或三服务真实环境。真实环境复测仍属于 PM/Frontend 联调阶段的接收动作。
