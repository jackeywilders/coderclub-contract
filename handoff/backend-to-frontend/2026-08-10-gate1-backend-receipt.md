# Gate 1 后端回执：鉴权、方法与分页

> 回执角色：Backend Codex
> 回执目标：G1-01、G1-02 后端部分、G1-03 后端证据、G1-04
> 后端验证提交：`06397f444f094a577cfde3f8684ae4f60622e871d`、`08cd88c8935371e0bfd07689ed6a9c0ae549a2a1`

## 1. 47 个操作鉴权矩阵（G1-01）

`anonymous` 表示无需登录；`login` 表示有效 Token；`role/permission` 表示除登录外还要求角色或权限。OpenAPI 的“未声明”只代表文档当前没有逐操作声明，运行时结论以控制器注解和异常链路为准。

| # | 操作 | OpenAPI | 运行时结论 | 运行时依据 |
| ---: | --- | --- | --- | --- |
| 1 | `POST /auth/register` | 未声明 | anonymous | AuthLoginController 无鉴权注解 |
| 2 | `POST /auth/login` | 未声明 | anonymous | AuthLoginController 无鉴权注解 |
| 3 | `POST /auth/wx-login` | 未声明 | anonymous | AuthLoginController 无鉴权注解 |
| 4 | `POST /auth/bind-account` | 未声明 | anonymous | AuthLoginController 无鉴权注解 |
| 5 | `POST /auth/logout` | Authorization | login | `@SaCheckLogin` |
| 6 | `GET /auth/user/info` | Authorization | login | `@SaCheckLogin` |
| 7 | `PUT /auth/user/update` | Authorization | login | `@SaCheckLogin` |
| 8 | `PUT /auth/user/password` | Authorization | login | `@SaCheckLogin` |
| 9 | `POST /auth/admin/user/page` | Authorization | role/permission | `@SaCheckRole("admin_user")` |
| 10 | `GET /auth/admin/user/{id}` | Authorization | role/permission | `@SaCheckRole("admin_user")` |
| 11 | `PUT /auth/admin/user/status` | Authorization | role/permission | `@SaCheckRole("admin_user")` |
| 12 | `POST /auth/admin/user/assign-role` | Authorization | role/permission | `@SaCheckRole("admin_user")` |
| 13 | `POST /auth/role/add` | Authorization | login | AuthRoleController `@SaCheckLogin` |
| 14 | `DELETE /auth/role/delete/{id}` | Authorization | login | AuthRoleController `@SaCheckLogin` |
| 15 | `PUT /auth/role/update` | Authorization | login | AuthRoleController `@SaCheckLogin` |
| 16 | `GET /auth/role/list` | Authorization | login | AuthRoleController `@SaCheckLogin` |
| 17 | `POST /auth/role/assign-permission` | Authorization | login | AuthRoleController `@SaCheckLogin` |
| 18 | `POST /auth/permission/add` | Authorization | login | AuthPermissionController `@SaCheckLogin` |
| 19 | `DELETE /auth/permission/delete/{id}` | Authorization | login | AuthPermissionController `@SaCheckLogin` |
| 20 | `PUT /auth/permission/update` | Authorization | login | AuthPermissionController `@SaCheckLogin` |
| 21 | `GET /auth/permission/tree` | Authorization | login | AuthPermissionController `@SaCheckLogin` |
| 22 | `POST /auth/permission/assign-role` | Authorization | login | AuthPermissionController `@SaCheckLogin` |
| 23 | `POST /subject/category/add` | 未声明 | login | `@SaCheckLogin` |
| 24 | `GET /subject/category/tree` | Authorization | login | `@SaCheckLogin` |
| 25 | `POST /subject/category/queryPrimaryCategory` | 未声明 | login | `@SaCheckLogin` |
| 26 | `POST /subject/category/queryCategoryByPrimary` | 未声明 | login | `@SaCheckLogin` |
| 27 | `POST /subject/category/update` | 未声明 | login | `@SaCheckLogin`（兼容） |
| 28 | `PUT /subject/category/update` | Authorization | login | `@SaCheckLogin`（正式） |
| 29 | `POST /subject/category/delete` | 未声明 | login | `@SaCheckLogin`（兼容） |
| 30 | `DELETE /subject/category/delete/{id}` | Authorization | login | `@SaCheckLogin`（正式） |
| 31 | `POST /subject/label/queryLabelByCategoryId` | 未声明 | login | `@SaCheckLogin` |
| 32 | `POST /subject/label/add` | 未声明 | login | `@SaCheckLogin` |
| 33 | `GET /subject/label/list` | Authorization | login | `@SaCheckLogin` |
| 34 | `POST /subject/label/update` | 未声明 | login | `@SaCheckLogin`（兼容） |
| 35 | `PUT /subject/label/update` | Authorization | login | `@SaCheckLogin`（正式） |
| 36 | `POST /subject/label/delete` | 未声明 | login | `@SaCheckLogin`（兼容） |
| 37 | `DELETE /subject/label/delete/{id}` | Authorization | login | `@SaCheckLogin`（正式） |
| 38 | `POST /subject/add` | 未声明 | login | `@SaCheckLogin` |
| 39 | `DELETE /subject/remove/{id}` | 未声明 | login | `@SaCheckLogin` |
| 40 | `PUT /subject/update` | 未声明 | login | `@SaCheckLogin` |
| 41 | `GET /subject/list` | 未声明 | login | `@SaCheckLogin` |
| 42 | `POST /subject/querySubjectInfo` | 未声明 | login | `@SaCheckLogin`（兼容） |
| 43 | `GET /subject/querySubjectInfo/{id}` | Authorization | login | `@SaCheckLogin`（正式） |
| 44 | `POST /subject/getSubjectPage` | Authorization | login | `@SaCheckLogin` |
| 45 | `GET /oss/getUrl` | 未声明 | anonymous | FileController 无鉴权注解 |
| 46 | `POST /oss/upload` | 未声明 | anonymous | FileController 无鉴权注解 |
| 47 | `GET /oss/testGetAllBuckets` | 未声明 | anonymous | FileController 无鉴权注解 |

汇总：`anonymous=7`、`login=36`、`role/permission=4`。当前 Auth Role/Permission 管理接口只有登录门禁，没有进一步的 `@SaCheckRole` 或 `@SaCheckPermission`；这不是前端可自行推断的管理员权限。

## 2. 401/403 语义与证据（G1-02 后端部分）

| 场景 | HTTP 状态 | 业务 code | 响应结构 | 后端依据 |
| --- | ---: | ---: | --- | --- |
| 未登录或 Token 过期 | 401 | 401 | `success=false, code=401, message=未登录或Token已过期, data=null` | Auth/Subject GlobalExceptionHandler 的 `NotLoginException` |
| 已登录但缺少角色/权限 | 403 | 403 | `success=false, code=403, message` 按角色/权限异常区分, `data=null` | Auth GlobalExceptionHandler 的 `NotRoleException`/`NotPermissionException` |

已补充并通过的运行时回归：

- Auth `POST /auth/admin/user/page`：登录但无 `admin_user` 角色，MockMvc 断言 HTTP 403、`success=false`、`code=403`。
- Subject 原有 `SubjectContractTest`：41 项通过，其中无登录端点断言覆盖 HTTP 401 与 `code=401`；当前 Subject 控制器没有角色/权限注解，因此没有可用于业务角色矩阵的 Subject 403 场景。
- Auth `AuthContractTest`：5 项通过，新增 403 回归已包含在内。

验证命令：

```powershell
mvn -pl coder-club-auth/coder-club-auth-app/coder-club-auth-app-controller -am '-Dtest=AuthContractTest' '-Dsurefire.failIfNoSpecifiedTests=false' test
mvn -pl coder-club-subject/coder-club-subject-app/coder-club-subject-app-controller -am '-Dtest=SubjectContractTest' '-Dsurefire.failIfNoSpecifiedTests=false' test
```

结果：Auth `5/5`、Subject `41/41` 通过。Frontend 仍需补充其 401/403 请求拦截和页面处理证据；M4 仍需决定 Subject、Auth Role/Permission 管理接口的细粒度权限范围。

## 3. 正式 HTTP 方法与兼容端点（G1-03 后端证据）

| 资源 | 正式方法 | 当前兼容方法 | 鉴权 | 移除条件 |
| --- | --- | --- | --- | --- |
| 分类更新 | `PUT /subject/category/update` | `POST /subject/category/update` | login | PM 确认前端已切换并发布兼容截止版本后移除 |
| 分类删除 | `DELETE /subject/category/delete/{id}` | `POST /subject/category/delete` | login | PM 确认前端已切换并发布兼容截止版本后移除 |
| 标签更新 | `PUT /subject/label/update` | `POST /subject/label/update` | login | PM 确认前端已切换并发布兼容截止版本后移除 |
| 标签删除 | `DELETE /subject/label/delete/{id}` | `POST /subject/label/delete` | login | PM 确认前端已切换并发布兼容截止版本后移除 |

本回执不删除兼容端点，也不替 PM 决定具体日期或版本。PM 仍需补充“保留截止版本/日期”，Frontend 首轮联调只应使用正式 PUT/DELETE 方法。

## 4. 分页修复与回归（G1-04）

问题根因：`SubjectInfoServiceImpl.countByCondition()` 原先使用 `LEFT JOIN`，并把 `subjectType`、`subjectDifficult` 放在 JOIN 条件中；它还以固定 `info.id` 作为关联条件，导致 count 与 `SubjectInfoMapper.xml` 的分页列表查询口径不一致。

修复内容：

- count 改为与列表查询一致的 `subject_info` 与 `subject_mapping` 内连接；
- 关联条件改为 `subject_mapping.subject_id = subject_info.id`；
- 分类、标签、难度、题型、逻辑删除条件统一进入 WHERE；
- 增加 count SQL 过滤回归，以及领域层无结果/单页/多页响应回归。

复现与验收场景：

| 场景 | pageSize | total | list | totalPages |
| --- | ---: | ---: | ---: | ---: |
| `subjectType=99` 无结果 | 5 | 0 | `[]` | 0 |
| 单页 | 5 | 2 | 2 条 | 1 |
| 多页 | 5 | 6 | 当前页 5 条 | 2 |

验证命令：

```powershell
mvn -pl coder-club-subject/coder-club-subject-domain -am '-Dtest=SubjectInfoDomainServiceImplTest,SubjectInfoServiceImplTest' '-Dsurefire.failIfNoSpecifiedTests=false' test
```

结果：infra `3/3`、domain `3/3`，共 `6/6` 通过；Subject Controller 契约测试另以 `41/41` 通过。修复提交为 `06397f444f094a577cfde3f8684ae4f60622e871d`。

## 5. Gate1 接收方动作与未关闭事项

- Frontend：按本回执的运行时矩阵实现 401/403 处理，并只调用正式 PUT/DELETE；完成消费文件 SHA-256 和 `npm run api:check` 回执。
- PM：将 G0-01/G0-02、G1-01/G1-04 纳入汇总；为兼容 POST 补充截止版本/日期；决定细粒度角色/权限矩阵是否进入 M4。
- 本回执不宣称 Gate 1 整体关闭：Frontend 证据、PM 方法兼容决策和跨项目发布状态仍待完成。
