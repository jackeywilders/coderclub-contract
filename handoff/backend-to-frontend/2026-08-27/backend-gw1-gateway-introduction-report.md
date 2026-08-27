# 后端回执：网关（coder-club-gateway）引入（GW-1）

> **任务 ID：** GW-1
> **实施角色：** 后端实现（B-Impl）
> **日期：** 2026-08-27（Asia/Shanghai）
> **任务书：** `pm/requirements/2026-08-27/gateway-introduction-task.md`（PR #80）
> **架构依据：** `docs/superpowers/specs/2026-08-27-a8-backend-architecture-direction.md` §5（PR #79）
> **后端仓库 PR：** jackeywilders/coderclub#13（base=main，CI 全绿）
> **契约快照：** `contractSnapshotSha256=4bfb3c72`（零变更）

---

## 1. 任务概览

引入统一网关 `coder-club-gateway`（Spring Cloud Gateway WebFlux + sa-token-reactor + 共享 Redis token 存储 + Nacos Discovery）：登录校验级（未登录 401 语义统一）、匿名白名单（按契约 46 端点逐项核对）、loginId header 透传 + 覆写防伪造、权限留在服务内；6 前缀路由（含 practice/circle/interview 3 预留域）；CORS 统一配置化；docker-compose / start-gateway.ps1 / 前端入口切换说明齐备。业务服务代码零迁移（`@SaCheckLogin` 保留双保险），契约零变更，前后端既有入口经网关链路验证通过。

## 2. 模块结构

新模块 `coder-club-gateway/`（starter 形态单模块，parent = coder-club-dependencies）：

```
coder-club-gateway/
  pom.xml                              # spring-cloud-starter-gateway-server-webflux（SCG 5.0.0）
                                       # + sa-token-reactor-spring-boot4-starter + sa-token-redis-jackson
                                       # + spring-cloud-starter-alibaba-nacos-discovery/config
                                       # + spring-cloud-starter-loadbalancer + spring-boot-starter-data-redis
                                       # + spring-boot-starter-actuator + log4j2（无 servlet 栈、不依赖 coder-club-common）
  src/main/java/com/jackey/gateway/
    GatewayApplication.java
    config/GatewayAuthProperties.java    # gateway.auth.whitelist（@ConfigurationProperties）
    config/SaTokenConfigure.java         # SaReactorFilter bean（登录校验 + 401 语义 + OPTIONS 放行）
    filter/LoginIdTransferGlobalFilter.java  # loginId 剥除 + 透传覆写（SaReactorSyncHolder 上下文窗口）
  src/main/resources/application.yaml    # 端口 ${SERVER_PORT:5000}；6 路由 server.webflux.routes；
                                       # globalcors（GATEWAY_CORS_ALLOWED_ORIGINS）；Optional:nacos 导入
  src/test/java/com/jackey/gateway/     # 69 用例
```

- **SCG 5.0.0 配置命名空间**：`spring.cloud.gateway.server.webflux.*`（5.0.0 收敛，旧键 `spring.cloud.gateway.routes` 不绑定——任务 4 实证并迁移，路由完备性断言防回归）。
- **测试**：白名单分类 49（46 端点 + 2 actuator + 护栏）+ 鉴权/CORS/loginId 集成 14 + context 冒烟 2 + 路由定义 4；全量 `mvn test` 20 模块 BUILD SUCCESS（auth 45 / subject 85 / oss 61 / gateway 69）。

## 3. 鉴权模型（登录校验级）

- **SaReactorFilter**（WebFilter @Order(-100)，先于网关 GlobalFilter 链）：拦截全部请求，未登录（无有效 token）→ **HTTP 401** + `{"success":false,"code":401,"message":"未登录或Token已过期","data":null}`（与 auth GlobalExceptionHandler 语义一致，error 回调显式 setStatus(401) + JSON Content-Type）；白名单路径直接放行；`OPTIONS` 预检放行（CORS 由网关处理）。
- **token 体系**：`token-name: Authorization`（与业务服务逐字一致）；网关经 `sa-token-redis-template` 自动配置 + `SaBeanInject` 装配 `SaTokenDaoForRedisTemplate`（同一 Redis 存储校验 auth 签发 token；装配守卫测试固化）。
- **loginId 透传**：GlobalFilter 对**所有**请求先剥除客户端同名头（防伪造），非白名单路径在登录态写入真实 loginId（`StpUtil.getLoginIdDefaultNull()` + `String.valueOf`），白名单路径剥除且不写（即使已登录）。上下文窗口用 `SaReactorSyncHolder.setContext/clearContext`（SaReactorFilter 的 finally 会先清上下文——上游 #968 同类问题的规避，1.45/1.46 源码相同）。
- **权限留在服务内**：服务内 `@SaCheckLogin`/`@SaCheckRole`/`@SaCheckPermission` 全部保留（双保险），未迁移权限逻辑。

## 4. 匿名白名单逐项核对表（契约 46 端点，漏配 0）

白名单最终配置 = **7 项**：`/auth/login`、`/auth/register`、`/auth/wx-login`、`/oss/upload`、`/oss/getUrl` + 网关自身 `/actuator/health`、`/actuator/info`。按契约 46 端点逐项核对（数据源 `docs/api/coderclub-openapi.json`；网关判定：白名单或需登录）：

| # | 端点 | 方法 | 服务 | 服务内现状 | 网关判定 |
|---|---|---|---|---|---|
| 1 | /auth/register | POST | auth | 匿名 | **白名单** |
| 2 | /auth/login | POST | auth | 匿名 | **白名单** |
| 3 | /auth/wx-login | POST | auth | 匿名 | **白名单** |
| 4 | /auth/bind-account | POST | auth | 匿名（wx-login 后必有 token） | 需登录 |
| 5 | /auth/logout | POST | auth | StpUtil.logout() | 需登录 |
| 6 | /auth/user/info | GET | auth | StpUtil.getLoginIdAsLong→401 | 需登录 |
| 7 | /auth/user/update | PUT | auth | 同上 | 需登录 |
| 8 | /auth/user/password | PUT | auth | 同上 | 需登录 |
| 9 | /auth/admin/user/page | POST | auth | 类级 @SaCheckRole("admin_user") | 需登录 |
| 10 | /auth/admin/user/{id} | GET | auth | 同上 | 需登录 |
| 11 | /auth/admin/user/status | PUT | auth | 同上 | 需登录 |
| 12 | /auth/admin/user/assign-role | POST | auth | 同上 | 需登录 |
| 13 | /auth/role/add | POST | auth | @SaCheckRole("admin_user") | 需登录 |
| 14 | /auth/role/delete/{id} | DELETE | auth | 同上 | 需登录 |
| 15 | /auth/role/update | PUT | auth | 同上 | 需登录 |
| 16 | /auth/role/list | GET | auth | 同上 | 需登录 |
| 17 | /auth/role/assign-permission | POST | auth | 同上 | 需登录 |
| 18 | /auth/permission/add | POST | auth | @SaCheckRole("admin_user") | 需登录 |
| 19 | /auth/permission/delete/{id} | DELETE | auth | 同上 | 需登录 |
| 20 | /auth/permission/update | PUT | auth | 同上 | 需登录 |
| 21 | /auth/permission/tree | GET | auth | 同上 | 需登录 |
| 22 | /auth/permission/assign-role | POST | auth | 同上 | 需登录 |
| 23 | /subject/category/add | POST | subject | @SaCheckLogin+Permission | 需登录 |
| 24 | /subject/category/tree | GET | subject | @SaCheckLogin | 需登录 |
| 25 | /subject/category/queryPrimaryCategory | POST | subject | @SaCheckLogin | 需登录 |
| 26 | /subject/category/queryCategoryByPrimary | POST | subject | @SaCheckLogin | 需登录 |
| 27 | /subject/category/update | PUT | subject | @SaCheckLogin+Permission | 需登录 |
| 28 | /subject/category/delete/{id} | DELETE | subject | @SaCheckLogin+Permission | 需登录 |
| 29 | /subject/label/queryLabelByCategoryId | POST | subject | @SaCheckLogin | 需登录 |
| 30 | /subject/label/add | POST | subject | @SaCheckLogin+Permission | 需登录 |
| 31 | /subject/label/list | GET | subject | @SaCheckLogin | 需登录 |
| 32 | /subject/label/update | PUT | subject | @SaCheckLogin+Permission | 需登录 |
| 33 | /subject/label/delete/{id} | DELETE | subject | @SaCheckLogin+Permission | 需登录 |
| 34 | /subject/add | POST | subject | @SaCheckLogin+Permission | 需登录 |
| 35 | /subject/remove/{id} | DELETE | subject | @SaCheckLogin+Permission | 需登录 |
| 36 | /subject/update | PUT | subject | @SaCheckLogin+Permission | 需登录 |
| 37 | /subject/list | GET | subject | @SaCheckLogin | 需登录 |
| 38 | /subject/querySubjectInfo | POST | subject | @SaCheckLogin | 需登录 |
| 39 | /subject/querySubjectInfo/{id} | GET | subject | @SaCheckLogin | 需登录 |
| 40 | /subject/getSubjectPage | POST | subject | @SaCheckLogin | 需登录 |
| 41 | /oss/getUrl | GET | oss | 匿名（注释明确） | **白名单** |
| 42 | /oss/upload | POST | oss | @SaCheckLogin（双保险） | **白名单** |
| 43 | /oss/testGetAllBuckets | GET | oss | 代码内 checkRole（默认 debug 关） | 需登录 |
| 44 | /subject/getSubjectPageBySearch | POST | subject | @SaCheckLogin | 需登录 |
| 45 | /subject/getContributeList | POST | subject | @SaCheckLogin | 需登录 |
| 46 | /auth/user/list-by-identifiers | POST | auth | @SaCheckLogin | 需登录 |

**结论：白名单 5 端点（+2 项网关自身 actuator）；需登录 41 端点；逐项核对无漏配（漏配 = 必须匿名却未列白名单——本表匿名集合 = 白名单 5 项，另 upload 因服务内 @SaCheckLogin 双保险，网关白名单放行不构成安全回退）。**

## 5. 路由表（6 前缀，StripPrefix=0 直通）

| 前缀 | 目标（Nacos lb://） | 状态 |
|---|---|---|
| /auth/** | coder-club-auth | 已注册可用 |
| /subject/** | coder-club-subject | 已注册可用 |
| /oss/** | coder-club-oss | 已注册可用 |
| /practice/** | coder-club-practice | 预留：未注册实例 → 网关 503 |
| /circle/** | coder-club-circle | 预留：未注册实例 → 503 |
| /interview/** | coder-club-interview | 预留：未注册实例 → 503 |

路由 uri 支持 `GATEWAY_URI_*` 环境变量覆盖（默认 lb://，与本地一致；docker-compose 内可改服务名直连）。预留域 503 已在集成测试（已登录实测 503）与云端联调实证。

## 6. CORS

`spring.cloud.gateway.server.webflux.globalcors.cors-configurations["/**"]`：`allowed-origin-patterns: ${GATEWAY_CORS_ALLOWED_ORIGINS:http://localhost:5173}`、methods GET,POST,PUT,DELETE,OPTIONS、allow-credentials true、max-age 3600。SCG 5.0.0 走 handler-mapping CORS（无 CorsWebFilter bean）。**语义说明**：非白名单源的预检由网关按配置处理（未配置源返回 403）；未登录跨域实际请求 401 且无 ACAO 头（浏览器视为网络错误）——**前端需自行处理 401 分支**（不依赖 CORS 错误体）。

## 7. 部署与运行

- **Dockerfile.gateway**：两阶段构建（完整 pom 树 20 条 COPY → `mvn dependency:go-offline -pl coder-club-gateway -am` + `mvn package`，解决 BOM 聚合 "Child module does not exist"）+ jre-alpine run（EXPOSE 5000）。
- **docker-compose.yml**：新增 `coder-club-gateway` 段（ports 5000:5000，env：SPRING_DATA_REDIS_HOST=redis、NACOS_* 变量插值，depends_on redis）；auth/subject 段补 NACOS_* 注入（**最终审查 IMP-1/IMP-2 修复**：Dockerfile.auth/subject 同步完整 pom 树；compose 全栈可拉起）。
- **start-gateway.ps1**：与 start-auth.ps1 同构（NACOS_USERNAME/PASSWORD 用户级环境变量读取、未设置阻止启动、NACOS_ADDR 优先环境变量、真实地址不落盘——CI 敏感扫描 IPv4 模式合规）。
- **Nacos 配置**：`coder-club-gateway-dev.properties`（namespace=dev，配置中心）——已由用户在 Nacos 创建（含共享 Redis 段与 auth 一致、server.port=5000、sa-token.token-name=Authorization）；网关以 `optional:nacos:` 导入，缺失不阻断启动。
- **前端入口切换（配置项说明，前端代码未改）**：vite proxy 单入口指向网关，如 `'/api': { target: 'http://localhost:5000', changeOrigin: true, rewrite: p => p.replace(/^\/api/, '') }`（或直连 target=http://localhost:5000，随前端现状微调），由前端/运维随验收切换。
- **云端切换步骤**：网关部署 → 预检（health / 白名单登录 / 401 / CORS）→ 域名/负载入口指向网关 5000 → 前端 env 指向网关 → 收敛各服务直连端口。
- **网关单点**：发布前评估冗余（既有风险项）。

## 8. sa-token 全盘升级 1.45.0 → 1.46.0 与上游 issue 影响

- **升级**（BOM 单点 `${satoken.version}`，全盘单版本）：修复 Boot4 WebFlux/Gateway `SaHolder.getResponse().setStatus` NoSuchMethodError（上游 #916/#IIAW1A——网关 401 语义依赖，任务 2 实锤命中并已按 1.46.0 还原官方 API）；Jackson 多态反序列化加固（类型白名单，本项目会话仅存 `Set<String>`，JDK 类型默认白名单内）；SSO/OAuth2 redirect 漏洞修复；`sa-token-dependencies` 不再锁 Reactor 版本（避免与 SCG 5.0.0 冲突）。兼容核验：`StpInterface.isDisabled` 无覆写、loginId 无冒号、无 JWT/SSO/OAuth2 使用，业务代码零改动；20 模块全量回归绿。
- **上游 #968（reactor starter + 虚拟线程 注解路径 SaTokenContext 未初始化）**：我们网关不走 WebFlux 注解路径且未启用虚拟线程；loginId 过滤器按"自建上下文窗口"模式实现（规避同类问题），集成测试实证。**与本项目无影响。**
- **上游 #970（Redisson `PX -2000` `ERR invalid expire time`）**：项目全用 **Lettuce** 连接（KEEPTTL 原生支持，`SET key val KEEPTTL XX`），无 Redisson 桥接；云端 Redis 8.8.1 实测登录会话正常。**与本项目无影响。**
- **虚拟线程决策**（用户 2026-08-27 确认）：auth/subject 开启（既有）、oss 开启（本任务授权补齐，`spring.threads.virtual.enabled: true`，仅 1 键零业务逻辑）、gateway 关闭（reactive 栈无收益 + 规避 #968 组合面）；README §9 附连接池重标定与上线前并发压测建议。

## 9. 本地验证证据

- 网关 69 用例全绿（白名单分类 49 / 集成 14 / 冒烟 2 / 路由 4）；全量 `mvn test` 20 模块 BUILD SUCCESS；`mvn install -DskipTests -q` exit 0。
- 关键机制实证：sa-token-reactor 无默认 SaReactorFilter 自动注册（无双过滤）；网关上下文装配 `SaTokenDaoForRedisTemplate`（装配守卫测试）；SCG 5.0.0 新配置命名空间绑定（路由完备性断言防旧键回归）；预留域 503（use404 默认 false）。
- 契约测试不受影响（standalone MockMvc 不经网关）：auth 45 / subject 85 全绿。
- 最终整分支审查：FIX-THEN-MERGE → 修复轮 2 项（Dockerfile.auth/subject 完整 pom 树、compose NACOS_* 注入）→ 定向复审 2/2 ADDRESSED、无新破坏；PR #13 CI：build-and-test ✅ + sensitive-scan ✅。

## 10. 云端联调证据（与 A8-P1-BE 验证衔接，经网关链路）

云端环境：Nacos（dev）/ MySQL / **Redis 8.8.1**（用户提供版本）；四服务本地启动连云端中间件，全部请求经网关 `http://localhost:5000`：

| # | 检查项 | 结果 |
|---|---|---|
| 1 | 网关 401 语义（无 token 访问受保护端点） | HTTP 401 + `{"success":false,"code":401,"message":"未登录或Token已过期","data":null}` ✅ |
| 2 | 白名单登录 P(OST /auth/login 经网关) | 200 获 token ✅ |
| 3 | 受保护端点带 token 经网关（/auth/user/info） | 200（admin, admin_user）✅ |
| 4 | A8 search ：P(OST /subject/getSubjectPageBySearch（云 SQL 执行） | 200 total=0（空串早退符合设计）✅ |
| 5 | A8 contribute ：P(OST /subject/getContributeList（**Feign 跨服务**昵称链路经网关） | 200 listCount=1 ✅ |
| 6 | topN 上界（99 → ≤20） | listCount=1 ≤20 ✅ |
| 7 | 预留域 /practice/health（带 token） | 503 ✅ |
| 8 | CORS 预检 OPTIONS /auth/user/info | 200 + Access-Control-Allow-Origin ✅ |
| 9 | oss 白名单 /oss/getUrl（无 token） | 200（非 401，参数校验属业务层）✅ |

**loginId 透传/覆写**：云端无下游消费方回显该头（业务服务用 Sa-Token 上下文），语义由 11 个集成测试实证（透传=42 / 覆写 999→42 / 白名单剥除 / 已登录白名单不写）；云端行为性验证 = 全链路登录/访问畅通（过滤器链正常）。A8-P1-BE 四项待办（search SQL、Feign 联调、401 e2e、topN 边界）已全部经网关链路完成。

## 11. 兼容性与已知边界

- **业务服务代码零改动**（auth/subject/oss 的 main/test 源未触碰；`@SaCheckLogin`/`@SaCheckRole`/`@SaCheckPermission` 全部保留）；唯一业务配置改动 = oss yaml 虚拟线程 1 键（用户授权例外，随本任务提交并记录）。
- **契约零变更**：`docs/api/coderclub-openapi.json` 46 端点快照不变；`contractSnapshotSha256=4bfb3c72`。
- 观察（非本任务引入）：auth 服务未注册 SaInterceptor → 类级 `@SaCheckRole("admin_user")` 注解在当前运行时实际不生效（既有权检查缺口）；网关登录校验级使 admin 类端点至少要求有效 token，权限级收敛仍待服务内处理（任务书声明权限不迁移）。
- 已知边界：Swagger/Druid 等调试入口不经网关（保持服务直连）；WebSocket 不经网关（后置项）；网关单点待冗余评估；docker 容器级构建/冒烟本机未执行（本机无 docker），建议合入后在有 docker 环境按 `docs/gateway/README.md` §7 执行 `docker compose up --build` 全栈冒烟作为验收补充。
- 分布式/多实例：token 经共享 Redis 校验（Lettuce），多网关实例语义一致；auth/subject/oss/网关同 sa-token 1.46.0 单版本。

## 12. 规则 8 声明

本任务全部提交/文档/回执不含真实凭据（密码/token/密钥字面量）；真实环境值（Nacos 云端地址等）经用户级环境变量/`.env` 注入，新文件零真实 IP 字面量（CI sensitive-scan IPv4 模式 0 命中）；联调账号凭据经 `CODER_CLUB_TEST_*` 用户级环境变量在内存使用，未落盘/未提交/未入回执。更早脚本中出现的云端 Nacos 地址在本任务新文件中已全部迁往 `NACOS_ADDR` 环境变量驱动。