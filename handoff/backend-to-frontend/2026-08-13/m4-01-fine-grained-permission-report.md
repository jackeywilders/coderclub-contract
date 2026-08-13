# M4-01 后端执行报告：细粒度角色/权限矩阵

> **任务角色：** Claude Code 后端
> **任务来源：** `pm/requirements/2026-08-13/m4-01-fine-grained-permission-task.md`（PM 批准）
> **复核角色：** Backend Codex
> **报告日期：** 2026-08-13
> **契约影响：** 无（未改变 OpenAPI 字段/路径/方法；鉴权行为变更由 M4-01 任务批准实施）

## 1. 来源与提交哈希

| 项目 | 值 |
| --- | --- |
| 来源项目 | `G:/Dev/backend/Club/CoderClub` |
| 来源分支 | `main` |
| 实施提交哈希 | `fbac8a8`（feat(auth/subject): 细粒度角色/权限矩阵鉴权（M4-01）） |
| 回执提交哈希 | （Backend Codex 签署时填写） |

## 2. 权限矩阵文档路径

- **路径**：`docs/backend/2026-08-13-m4-01-permission-matrix.md`（后端项目内，随实施提交落地）
- 覆盖：端点 × 角色 × 行为，逐项明确 匿名/登录/角色/权限 四类结论；权限键定义（9 个写权限键 + admin_user 分配）；Subject 18 端点 + Auth 14 管理端点矩阵；三态行为汇总。

## 3. 实施内容

| 项 | 内容 |
| --- | --- |
| Subject StpInterface | 新增 `SubjectSaTokenConfigure`（subject-app-controller），从 Sa-Token 共享会话读取 `roleKeys`/`permissionKeys` |
| Subject 写端点鉴权 | 9 个写端点加 `@SaCheckPermission`：`subject:add`/`subject:update`/`subject:remove`、`subject:category:add/update/delete`、`subject:label:add/update/delete` |
| Auth 管理端点鉴权 | `AuthRoleController`/`AuthPermissionController` 类级 `@SaCheckLogin` → `@SaCheckRole("admin_user")`（与 `AuthUserManageController` 一致） |
| 会话权限键 | Auth `loadRoleAndPermission` 改为向会话写入权限**键** `permissionKeys`（原 `permissionIds` 无读取方，替换安全） |
| Auth 契约不变 | Auth 自身 `StpInterface.getPermissionList` 仍返回权限**表 ID**，`/auth/user/info` 的 `permissions` 契约未变 |
| 403 响应一致性 | `NotPermissionException`（含 `NotRoleException`）→ HTTP 403 + code 403 + 统一响应体（既有 GlobalExceptionHandler） |
| 数据配置 | `init.sql` 新增 8 个写权限种子（id 2-9）+ admin_user（role_id=1）角色权限分配 9 行；normal_user 不分配写权限。**运行库应用**：需在共享 dev 库执行相同 INSERT（属数据配置，与代码提交区分，未擅自改动运行库） |

## 4. 三态测试命令与结果

### 4.1 Subject 侧（`SubjectContractTest`）

```
mvn -pl coder-club-subject/coder-club-subject-app/coder-club-subject-app-controller -am '-Dtest=SubjectContractTest' '-Dsurefire.failIfNoSpecifiedTests=false' test
```

结果：**49/49 通过，Failures 0，Errors 0**（45 既有 + 4 新增 403 断言）。

- **匿名 → 401**：既有断言（categoryTree/labelList/categoryUpdate/categoryDelete/labelUpdate/labelDelete/querySubjectInfoById/getSubjectPage/categoryAdd/categoryQueryPrimary/categoryQueryByPrimary/labelQueryByCategoryId/labelAdd/subjectAdd/subjectRemove/subjectUpdate/subjectList 等 → HTTP 401 + code 401）。
- **普通用户 → 403**：新增断言（`StpUtil.login(2L)` 无写权限）：
  - `categoryAdd_shouldReturn403_whenLoggedInWithoutPermission` → 403
  - `categoryUpdate_shouldReturn403_whenLoggedInWithoutPermission` → 403
  - `labelAdd_shouldReturn403_whenLoggedInWithoutPermission` → 403
  - `subjectRemove_shouldReturn403_whenLoggedInWithoutPermission` → 403
- **管理员 → 200**：既有写端点 200 断言（`loginAsAdmin()` 注入全部写权限后 add/update/delete/remove 成功）。

### 4.2 Auth 侧（`AuthContractTest`）

```
mvn -pl coder-club-auth/coder-club-auth-app/coder-club-auth-app-controller -am '-Dtest=AuthContractTest' '-Dsurefire.failIfNoSpecifiedTests=false' test
```

结果：**8/8 通过，Failures 0，Errors 0**（5 既有 + 3 新增）。

- **匿名 → 401**：既有断言。
- **普通用户 → 403**：`authRoleList_shouldReturn403_whenLoggedInWithoutAdminRole`、`authPermissionTree_shouldReturn403_whenLoggedInWithoutAdminRole`（均 HTTP 403 + code 403）。
- **管理员 → 200**：`authRoleList_shouldReturnSuccess_whenLoggedInAsAdmin`（StpInterface 返回 admin_user 角色 → 200）。
- 既有 `adminUserPage_shouldReturn403_whenLoggedInWithoutAdminRole` 保持通过。

### 4.3 全量回归

```
mvn -f coder-club-dependencies/pom.xml test
```

结果：**94/94 通过，Failures 0，Errors 0，BUILD SUCCESS**（common 21 + subject 57 + oss 7 + auth 9）。

## 5. OpenAPI 是否变化

**未变化。** `docs/api/coderclub-openapi.json` SHA-256 保持 `7576e28a346dcf60b304bdd405f0bb82b72252df37e96013509ece00c6a14a2e`（43 路径 / 43 操作）。本次仅实施鉴权行为（登录→角色/权限），未改变字段/路径/方法，无需提案。

## 6. 已知限制

1. **运行库数据配置**：新权限与 role_permission 的 INSERT 已写入 `init.sql`（随代码提交），但未擅自改动共享 dev 运行库；需由运维/PM 在运行库执行相同数据配置后方可在真实环境生效。测试为 mock 三态断言，不依赖运行库数据。
2. **权限键粒度**：Subject 写端点按 9 个权限键校验；读端点仍为登录即可（矩阵中读端点无权限要求）。
3. **会话依赖**：Subject 的角色/权限解析依赖 Auth 登录时写入共享会话（`roleKeys`/`permissionKeys`）。若会话数据缺失（如 token 由旧版 Auth 签发），权限列表为空 → 写端点 403（fail-closed，安全侧优先）。
4. **`/auth/role` 与 `/auth/permission` 管理端点**：从 `@SaCheckLogin` 收紧为 `@SaCheckRole("admin_user")`，普通登录用户将 403（行为变更，属 M4-01 目标）。

## 7. 声明

- 未修改交接仓库 `api/coderclub-openapi.json` 快照与 `status/sync-manifest.json`。
- 未修改前端项目；未执行运维侧凭据/数据变更（运行库权限数据未擅自写入）。
- 所有测试命令与输出为真实执行结果，未伪造。
