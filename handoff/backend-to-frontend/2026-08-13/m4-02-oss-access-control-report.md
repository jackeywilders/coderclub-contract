# M4-02 后端执行报告：OSS 访问控制

> **任务角色：** Claude Code 后端
> **任务来源：** `pm/requirements/2026-08-13/m4-02-oss-access-control-task.md`（PM 批准）
> **复核角色：** Backend Codex
> **报告日期：** 2026-08-13
> **契约影响：** 无（未改变 OpenAPI 字段/路径/方法；OSS 端点鉴权策略由 M4-02 任务批准实施）

## 1. 来源与提交哈希

| 项目 | 值 |
| --- | --- |
| 来源项目 | `G:/Dev/backend/Club/CoderClub` |
| 来源分支 | `main` |
| 实施提交哈希 | `baa0975`（feat(oss): OSS 端点访问控制与调试开关（M4-02）） |
| 回执提交哈希 | （Backend Codex 签署时填写） |

## 2. OSS 端点策略文档与端点清单

- **策略文档**：`docs/backend/2026-08-13-m4-02-oss-access-policy.md`（后端项目内，随实施提交落地）
- **端点清单（3 个）**：

| 端点 | 方法 | 策略 | 说明 |
| --- | --- | --- | --- |
| `/oss/upload` | POST | 登录（@SaCheckLogin） | 写操作，登录用户可上传 |
| `/oss/getUrl` | GET | 匿名 | 公开读文件 URL（头像/内容图） |
| `/oss/testGetAllBuckets` | GET/POST | 调试开关 + `admin_user` | `oss.debug.enabled`（默认 false） |

## 3. 实施内容

| 项 | 内容 |
| --- | --- |
| OSS 鉴权基建 | pom 加 `sa-token-spring-boot4-starter` + `sa-token-redis-jackson`；yaml 加 sa-token 配置 + 共享 Redis（含 `REDIS_PASSWORD`）+ `oss.debug.enabled` |
| OSS StpInterface | 新增 `OssSaTokenConfigure`（读共享会话 `roleKeys`/`permissionKeys`）+ `SaTokenWebConfig`（注册 SaInterceptor） |
| upload | `@SaCheckLogin` → 匿名 401、登录 200 |
| getUrl | 保持匿名 → 200 |
| 调试端点 | `oss.debug.enabled=false`（默认）→ 业务 404「调试端点已关闭」；`true` 时 `StpUtil.checkRole("admin_user")` → 匿名 401 / 非管理员 403 / 管理员 200 |
| 401/403 一致性 | `GlobalExceptionHandler` 补 `NotLoginException`→401、`NotPermissionException`→403、`NotRoleException`→403（Sa-Token 1.45 中 NotRoleException 与 NotPermissionException 为兄弟类，需分别声明） |
| 编译修复 | OSS pom 显式声明 `maven-compiler-plugin`（release 21）——默认链解析 source 为 1.8，无法编译 |

## 4. 测试命令与结果

### 4.1 OSS（`FileControllerTest`）

```
mvn -pl coder-club-oss -am '-Dtest=FileControllerTest' '-Dsurefire.failIfNoSpecifiedTests=false' test
```

结果：**11/11 通过，Failures 0，Errors 0**（5 既有 + 新增 6 个鉴权/调试用例）。

- 匿名 upload → **401**（`upload_shouldReturn401_whenNotLoggedIn`）
- 登录 upload → 200（既有用例加登录）
- 调试端点四态：
  - 开关关 → 业务 404「调试端点已关闭」
  - 开关开 + 匿名 → **401**
  - 开关开 + 普通用户 → **403**（NotRoleException → handler）
  - 开关开 + 管理员 → 200 返回 bucket

### 4.2 全量回归

```
mvn -f coder-club-dependencies/pom.xml test
```

结果：**101/101 通过，Failures 0，Errors 0，BUILD SUCCESS**（common 21 + subject 51 + oss 11 + auth 18）。

## 5. OpenAPI 是否变化

**未变化。** `docs/api/coderclub-openapi.json` SHA-256 保持 `7576e28a346dcf60b304bdd405f0bb82b72252df37e96013509ece00c6a14a2e`（43 路径 / 43 操作）。OSS 端点鉴权行为变更由 M4-02 任务批准，无需提案。

## 6. 已知限制

1. **调试端点默认关闭**：`oss.debug.enabled=false`（环境变量 `OSS_DEBUG_ENABLED` 可覆盖）。如需开启需显式配置。
2. **共享会话依赖**：OSS 角色/权限解析依赖 Auth 登录时写入共享会话（`roleKeys`）。旧 token（无会话角色数据）访问调试端点 → 403（fail-closed）。
3. **OSS 编译源级别修复**：OSS pom 原 `maven.compiler.source=21` 未生效（effective 为 1.8），已显式声明 `maven-compiler-plugin` release 21 解决；其余服务不受影响。
4. **NotRoleException 单独声明**：Sa-Token 1.45 中 NotRoleException 与 NotPermissionException 为兄弟类；OSS handler 已分别声明 403 处理（Auth 已有 NotRoleException 处理，Subject 仅用 @SaCheckPermission 不受影响）。

## 7. 声明

- 未修改交接仓库 `api/coderclub-openapi.json` 快照与 `status/sync-manifest.json`。
- 未修改前端项目。
- 所有测试命令与输出为真实执行结果，未伪造。

## 8. 真实复核与补充提交（2026-08-13）

Nacos `coder-club-oss-dev.properties` 已补充共享 Redis（`spring.data.redis.*`）与 sa-token 配置（与 Auth 一致）。据此启动 Auth + OSS 服务做真实复核：

| 场景 | 端点 | 结果 |
| --- | --- | --- |
| 匿名 | `POST /oss/upload` | HTTP 401 `未登录或Token已过期` ✅ |
| 登录用户（user） | `POST /oss/upload` | HTTP 200，MinIO 真实上传成功 ✅ |
| 管理员（admin） | `POST /oss/upload` | HTTP 200 ✅ |
| 匿名 | `GET /oss/getUrl` | HTTP 200 ✅ |
| 匿名 | `GET /oss/testGetAllBuckets` | HTTP 200 + `code:404` `调试端点已关闭`（开关默认关）✅ |

**补充提交 `5045953`**（fix(oss): 声明 spring-boot-maven-plugin 使 spring-boot:run 可解析）：复核启动时发现 OSS pom 未声明 `spring-boot-maven-plugin`，`mvn spring-boot:run -pl coder-club-oss` 前缀解析失败无法启动；与 auth/subject starter 对齐声明 4.0.0 插件（含 repackage）。

**结论**：OSS 端点鉴权策略（上传需登录、getUrl 匿名、调试端点开关+角色）在真实运行环境生效；Nacos 配置正确。

## 9. Backend Codex 复核签署（2026-08-13）

- [x] 代码级复核：`/oss/upload` `@SaCheckLogin`、`/oss/getUrl` 匿名、调试端点开关+`admin_user` 角色（开关先于鉴权判断，关闭时信息不泄露）、OSS handler 401/403 齐全、sa-token 共享会话配置、pom 修复合理 — **通过**
- [x] 独立重跑：`FileControllerTest` 11/11，BUILD SUCCESS — **通过**
- [x] OpenAPI SHA-256 未变（`7576e28a…`，43/43）— **通过**
- [x] 策略文档、已知限制核验 — **通过**
- [x] M4-02 关闭条件 1、2 满足；签署本回执（关闭条件 3）

**复核签署**：Backend Codex，2026-08-13（工作底稿：`designs/backend/2026-08-13/m4-02-oss-access-control-review-workpaper.md`）
