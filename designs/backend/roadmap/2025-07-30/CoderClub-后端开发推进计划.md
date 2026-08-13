# CoderClub 后端开发推进计划

> **视角**：Project Manager
> **日期**：2025-07-30
> **团队配置**：后端开发 2 人（Dev-A、Dev-B）
> **当前基线**：后端骨架完成 ≈45%，详见《CoderClub-PM-全景分析报告-2025-07-30.md》

---

## 目录

1. [推进策略](#一推进策略)
2. [第一阶段：P0 紧急修复（第 1-2 周）](#二第一阶段p0-紧急修复)
3. [第二阶段：P1 质量加固（第 3 周）](#三第二阶段p1-质量加固)
4. [第三阶段：P2 功能补全（第 4-6 周）](#四第三阶段p2-功能补全)
5. [第四阶段：P3 长期演进（第 7 周起）](#五第四阶段p3-长期演进)
6. [人力分配总览](#六人力分配总览)
7. [里程碑与交付节点](#七里程碑与交付节点)
8. [风险与应对](#八风险与应对)

---

## 一、推进策略

### 核心原则

```
先止血 → 再加固 → 后建设 → 终演进
  P0        P1        P2       P3
```

**为什么按这个顺序？**

1. **P0 先止血**：公共类分叉和鉴权缺失是每天都在产生新债务的问题，越拖修复成本越高
2. **P1 再加固**：在稳定的基础上统一日志、清理冗余，为后续开发扫清障碍
3. **P2 后建设**：基础设施就绪后，再补微信登录、网关、搜索等进阶功能
4. **P3 终演进**：业务闭环（刷题记录、排行榜）和 CI/CD 在功能稳定后推进

### 分工原则

- **Dev-A** 主攻 auth 模块 + 基础设施（公共模块、网关、CI/CD）
- **Dev-B** 主攻 subject 模块 + oss 模块 + 搜索
- 每阶段结束后两人交叉 Code Review，确保风格一致

---

## 二、第一阶段：P0 紧急修复

> **时间**：第 1-2 周（10 个工作日）
> **目标**：消除安全漏洞、统一公共代码、修复架构违规

### 任务总览

```
Week 1 ──────────────────────── Week 2 ────────────────────────
│                                                              │
│  Dev-A: 提取公共模块 (3d)                                     │
│         ├─ 创建 coder-club-common 模块                       │
│         ├─ 迁移 ResponseResult / ResultCodeEnum /             │
│         │  BaseException / PageResult                        │
│         ├─ 统一 API（补齐 error() 等方法）                    │
│         └─ 三模块切换依赖 (2d)                                │
│                                                              │
│  Dev-B: Subject 鉴权 (2d)                                     │
│         ├─ Controller 添加 @SaCheckLogin                     │
│         ├─ 管理端点添加 @SaCheckRole                          │
│         └─ 验证 Feign 拦截器 token 传递                       │
│                                                              │
│  Dev-A: Auth Domain 修复 (1d)                                 │
│         └─ getById/page 返回 BO 而非 Entity                   │
│                                                              │
│  Dev-B: OSS 鉴权 + 异常处理 (2d)                               │
│         ├─ 添加 GlobalExceptionHandler                        │
│         ├─ 添加 BaseException                                 │
│         ├─ Controller 添加 @SaCheckLogin                     │
│         └─ OSS 端口改为 <oss-port>                                  │
│                                                              │
│  Week 1 收尾: 交叉 CR + 联调 (1d)                              │
│                                                              │
│  Week 2 缓冲: 问题修复 + 回归验证 (5d)                         │
│                                                              │
└──────────────────────────────────────────────────────────────┘
```

### 任务 1.1：提取公共模块 `coder-club-common`

**负责人**：Dev-A
**工时**：3 天开发 + 2 天切换
**优先级**：🔴 P0 — 这是所有后续工作的基础

**详细步骤**：

| 步骤 | 内容 | 产出 |
|------|------|------|
| 1.1.1 | 在根目录创建 `coder-club-common` Maven 模块，groupId `com.jackey`，artifactId `coder-club-common` | 模块骨架 |
| 1.1.2 | 以 auth-common 的版本为基准，合并三份代码，统一 API | 最终版公共类 |
| 1.1.3 | 在 `coder-club-dependencies` BOM 中声明该模块 | BOM 更新 |
| 1.1.4 | auth-common 移除重复类，改为依赖 `coder-club-common` | auth 模块切换 |
| 1.1.5 | subject-common 移除重复类，改为依赖 `coder-club-common` | subject 模块切换 |
| 1.1.6 | oss 移除重复类，改为依赖 `coder-club-common` | oss 模块切换 |
| 1.1.7 | 全量编译 `mvn install -DskipTests`，确认无编译错误 | 验证通过 |

**统一 API 要点**：

```java
// ResponseResult 最终统一方法（补齐所有缺失）
public class ResponseResult<T> {
    // 成功
    public static <T> ResponseResult<T> success()
    public static <T> ResponseResult<T> success(T data)
    public static <T> ResponseResult<T> success(int code, String message)
    public static <T> ResponseResult<T> success(int code, String message, T data)

    // 失败
    public static <T> ResponseResult<T> fail()
    public static <T> ResponseResult<T> fail(String message)
    public static <T> ResponseResult<T> fail(int code, String message)
    public static <T> ResponseResult<T> fail(int code, String message, T data)

    // 别名（保持兼容）
    public static <T> ResponseResult<T> error(int code, String message)  // 等同于 fail(code, message)
    public static <T> ResponseResult<T> error(int code, String message, T data)
    public static <T> ResponseResult<T> invalidParams()  // 等同于 fail(400, "参数错误")
}

// BaseException 统一构造器
public class BaseException extends RuntimeException {
    public BaseException(int code, String message)
    public BaseException(ResultCodeEnum resultCodeEnum)
    public BaseException(int code, String message, Throwable cause)
}

// ResultCodeEnum 统一枚举（合并三份，补齐 NOT_ACCEPTABLE）
public enum ResultCodeEnum {
    SUCCESS(200, "操作成功"),
    REQUEST_PARAM_INVALID(400, "请求参数校验失败"),
    UNAUTHORIZED(401, "未登录或登录已过期"),
    FORBIDDEN(403, "无权限"),
    NOT_FOUND(404, "资源不存在"),
    NOT_ACCEPTABLE(406, "请求不可接受"),
    INTERNAL_SERVER_ERROR(500, "服务器内部错误"),
    // ... 其余枚举
}
```

### 任务 1.2：Subject 模块添加鉴权

**负责人**：Dev-B
**工时**：2 天
**优先级**：🔴 P0 — 安全漏洞，所有端点完全开放

**详细步骤**：

| 步骤 | 内容 |
|------|------|
| 1.2.1 | `SubjectCategoryController` — 所有端点添加 `@SaCheckLogin`，add/update/delete 额外添加 `@SaCheckRole("admin_user")` |
| 1.2.2 | `SubjectLabelController` — 同上 |
| 1.2.3 | `SubjectController` — 查询类端点添加 `@SaCheckLogin`，add/update/delete 添加 `@SaCheckRole("admin_user")` |
| 1.2.4 | 验证 Feign 拦截器 `FeignConfig.authRequestInterceptor()` 在鉴权后仍能正确传递 token |
| 1.2.5 | 验证 `GlobalExceptionHandler` 中 `handleNotLogin` / `handleNotPermission` 返回正确的 401/403 |

**鉴权矩阵**：

| 端点 | 鉴权 |
|------|------|
| `/subject/category/queryPrimaryCategory` | `@SaCheckLogin` |
| `/subject/category/queryCategoryByPrimary` | `@SaCheckLogin` |
| `/subject/category/add` | `@SaCheckLogin` + `@SaCheckRole("admin_user")` |
| `/subject/category/update` | `@SaCheckLogin` + `@SaCheckRole("admin_user")` |
| `/subject/category/delete` | `@SaCheckLogin` + `@SaCheckRole("admin_user")` |
| `/subject/label/queryLabelByCategoryId` | `@SaCheckLogin` |
| `/subject/label/add` | `@SaCheckLogin` + `@SaCheckRole("admin_user")` |
| `/subject/label/update` | `@SaCheckLogin` + `@SaCheckRole("admin_user")` |
| `/subject/label/delete` | `@SaCheckLogin` + `@SaCheckRole("admin_user")` |
| `/subject/list` | `@SaCheckLogin` |
| `/subject/querySubjectInfo` | `@SaCheckLogin` |
| `/subject/getSubjectPage` | `@SaCheckLogin` |
| `/subject/add` | `@SaCheckLogin` + `@SaCheckRole("admin_user")` |
| `/subject/update` | `@SaCheckLogin` + `@SaCheckRole("admin_user")` |
| `/subject/remove/{id}` | `@SaCheckLogin` + `@SaCheckRole("admin_user")` |

### 任务 1.3：修复 Auth Domain 层实体泄露

**负责人**：Dev-A
**工时**：1 天
**优先级**：🔴 P0 — 违反 DDD 依赖倒置原则

**详细步骤**：

| 步骤 | 内容 |
|------|------|
| 1.3.1 | 修改 `AuthUserDomainService` 接口，`getById()` 返回 `AuthUserBO`，`page()` 返回 `PageResult<AuthUserBO>` |
| 1.3.2 | 在 `AuthUserDomainServiceImpl` 中使用 MapStruct-Plus Converter 完成 `Entity → BO` 转换 |
| 1.3.3 | 修改 `AuthUserController` 中所有调用点，使用 `AuthUserBO` 而非 `AuthUserEntity` |
| 1.3.4 | 修改 `AuthUserManageController` 中 `getById` 调用点 |
| 1.3.5 | 检查 `AuthUserDomainService` 所有其他方法是否也有泄露，一并修复 |

### 任务 1.4：OSS 模块鉴权 + 异常处理 + 端口修复

**负责人**：Dev-B
**工时**：2 天
**优先级**：🔴 P0 — 安全漏洞 + 无异常处理

**详细步骤**：

| 步骤 | 内容 |
|------|------|
| 1.4.1 | 添加依赖 `coder-club-common`（获取 `BaseException`、`ResultCodeEnum`、`ResponseResult`） |
| 1.4.2 | 添加依赖 `sa-token-spring-boot4-starter`（鉴权） |
| 1.4.3 | 创建 `GlobalExceptionHandler`（参考 subject 模块实现，统一使用 `ResponseResult.fail()`） |
| 1.4.4 | `FileController` 所有端点添加 `@SaCheckLogin` |
| 1.4.5 | `application.yaml` 端口改为 `<oss-port>` |
| 1.4.6 | 更新 `start-oss.ps1` 脚本中的端口说明 |

### 第一阶段收尾

| 步骤 | 负责人 | 工时 | 内容 |
|------|--------|------|------|
| 交叉 CR | 两人 | 0.5 天 | Dev-A 审查 Dev-B 的鉴权代码，Dev-B 审查 Dev-A 的公共模块 |
| 联调验证 | 两人 | 0.5 天 | 三服务启动 + 鉴权场景测试（401/403 返回验证） |
| 缓冲修复 | 两人 | 5 天 | 解决 CR 问题 + 联调发现的 bug |

---

## 三、第二阶段：P1 质量加固

> **时间**：第 3 周（5 个工作日）
> **目标**：统一日志追踪、清理技术债务、消除代码坏味

### 任务 3.1：统一日志追踪 ID

**负责人**：Dev-A
**工时**：1 天

| 步骤 | 内容 |
|------|------|
| 3.1.1 | 三模块 `log4j2-spring.xml` 统一添加 `%X{traceId}` 到日志格式 |
| 3.1.2 | 在 `coder-club-common` 中添加 `TraceIdFilter`（Servlet Filter），从请求头 `X-Trace-Id` 读取或生成 UUID 写入 MDC |
| 3.1.3 | 日志路径统一为 `${sys:LOG_PATH:-../xxx_log}` 模式（auth/oss 当前是硬编码） |
| 3.1.4 | 验证跨服务调用时 traceId 能通过 Feign 拦截器透传 |

### 任务 3.2：清理 BOM 冗余依赖

**负责人**：Dev-A
**工时**：0.5 天

| 步骤 | 内容 |
|------|------|
| 3.2.1 | 删除 `gson`、`easy-es`、`elasticsearch`、`elasticsearch-rest-high-level-client`、`sa-token-reactor`、`spring-cloud-starter-loadbalancer`、`spring-boot-starter-webmvc`、`spring-boot-autoconfigure`、`fastjson2-extension`（非 spring6）声明 |
| 3.2.2 | 删除已注释的 `mapstruct` 原版块 |
| 3.2.3 | `mvn install -DskipTests` 验证编译通过 |

### 任务 3.3：消除代码重复

**负责人**：Dev-B
**工时**：0.5 天

| 步骤 | 内容 |
|------|------|
| 3.3.1 | 提取 `AuthLoginController.login()` 和 `wxLogin()` 中重复的 safeUser Map 构建代码为私有方法 `buildSafeUserMap(AuthUserBO)` |
| 3.3.2 | 全局搜索其他重复代码，一并修复 |

### 任务 3.4：修复 Subject 硬编码错误码

**负责人**：Dev-B
**工时**：0.5 天

| 步骤 | 内容 |
|------|------|
| 3.4.1 | `GlobalExceptionHandler.handleBindException` 中 `400` 改为 `ResultCodeEnum.REQUEST_PARAM_INVALID.getCode()` |
| 3.4.2 | 统一 `handleBaseException` 使用 `ResponseResult.fail()` 而非 `error()` |
| 3.4.3 | 检查全局异常处理器中所有方法调用是否一致 |

### 任务 3.5：日志配置统一

**负责人**：Dev-B
**工时**：0.5 天

| 步骤 | 内容 |
|------|------|
| 3.5.1 | auth 的 `log4j2-spring.xml` 中 FILE_PATH 改为 `${sys:LOG_PATH:-../auth_log}` |
| 3.5.2 | oss 的 `log4j2-spring.xml` 中 FILE_PATH 改为 `${sys:LOG_PATH:-../oss_log}` |
| 3.5.3 | 三模块日志格式统一，确认 `%X{PFTID}` 已替换为 `%X{traceId}` |

### 任务 3.6：补充核心单元测试

**负责人**：Dev-A（auth）+ Dev-B（subject）
**工时**：2 天

| 模块 | 测试对象 | 测试场景 |
|------|----------|----------|
| auth | `AuthUserDomainService.register()` | 正常注册、重复用户名、参数校验失败 |
| auth | `AuthUserDomainService.login()` | 正常登录、密码错误、用户不存在、用户被禁用 |
| auth | `AuthUserDomainService.loadRoleAndPermission()` | 角色权限正确加载到 Session |
| auth | `SaTokenConfigure.getRoleList()` | 返回正确的角色列表 |
| auth | `SaTokenConfigure.getPermissionList()` | 返回正确的权限列表 |
| subject | `SubjectTypeHandlerFactory` | 4 种 Handler 正确注册、根据类型分发 |
| subject | `RadioTypeHandler.add()` | 单选题正常添加、选项数量校验 |
| subject | `SubjectCategoryDomainService` | 一级分类查询、二级分类查询 |
| subject | `SubjectInfoDomainService` | 题目分页查询、按条件查询 |

**测试框架**：JUnit 5 + Mockito + Spring Boot Test（仅加载必要上下文）

---

## 四、第三阶段：P2 功能补全

> **时间**：第 4-6 周（15 个工作日）
> **目标**：补全核心功能、引入基础设施组件

### 任务 4.1：微信登录真实对接

**负责人**：Dev-A（后端部分）
**工时**：3 天

| 步骤 | 内容 |
|------|------|
| 4.1.1 | 申请微信开放平台/公众号 AppID 和 AppSecret |
| 4.1.2 | 实现真实微信 OAuth 2.0 流程：code → access_token → openId → 用户信息 |
| 4.1.3 | 处理微信 access_token 刷新和缓存 |
| 4.1.4 | 保持 mock 模式可通过配置切换（本地开发用 mock，生产用真实） |
| 4.1.5 | 处理微信 UnionID 机制（如果涉及多平台） |

### 任务 4.2：引入 API 网关

**负责人**：Dev-A
**工时**：3 天

| 步骤 | 内容 |
|------|------|
| 4.2.1 | 创建 `coder-club-gateway` 模块，使用 Spring Cloud Gateway |
| 4.2.2 | 配置路由规则：`/auth/**` → auth 服务，`/subject/**` → subject 服务，`/oss/**` → oss 服务 |
| 4.2.3 | 在 Gateway 层统一处理跨域（CORS），移除各服务的 CorsConfig |
| 4.2.4 | Gateway 集成 Sa-Token 全局鉴权（统一校验 token，无需各服务重复配置） |
| 4.2.5 | 配置限流（RequestRateLimiter）保护后端服务 |

### 任务 4.3：引入链路追踪

**负责人**：Dev-A
**工时**：2 天

| 步骤 | 内容 |
|------|------|
| 4.3.1 | 集成 Micrometer Tracing + Brave（Spring Boot 3.x/4.x 原生方案） |
| 4.3.2 | 配置 Zipkin 或 SkyWalking 服务端 |
| 4.3.3 | 验证跨服务调用链路在追踪平台可见 |

### 任务 4.4：题目搜索（Elasticsearch）

**负责人**：Dev-B
**工时**：3 天

| 步骤 | 内容 |
|------|------|
| 4.4.1 | 在 Docker Compose 中添加 Elasticsearch 服务 |
| 4.4.2 | 创建 `SubjectSearchService`，实现题目索引的创建、更新、删除 |
| 4.4.3 | 实现全文搜索 API：`/subject/search?keyword=xxx&categoryId=xxx&page=1&size=20` |
| 4.4.4 | 题目新增/修改/删除时同步更新 ES 索引（通过 AOP 或事件机制） |
| 4.4.5 | 全量同步已有题目到 ES（一次性脚本） |

### 任务 4.5：补充接口测试

**负责人**：Dev-B
**工时**：2 天

| 步骤 | 内容 |
|------|------|
| 4.5.1 | 使用 Spring Boot Test + MockMvc 编写 Controller 层集成测试 |
| 4.5.2 | 覆盖鉴权场景：未登录、无权限、正常访问 |
| 4.5.3 | 覆盖参数校验场景：必填为空、格式错误、边界值 |
| 4.5.4 | 覆盖正常业务流程：完整的 CRUD 链路 |

### 任务 4.6：API 文档完善

**负责人**：Dev-B
**工时**：1 天

| 步骤 | 内容 |
|------|------|
| 4.6.1 | 为所有 Controller 添加 SpringDoc 注解（`@Operation`、`@Parameter`、`@Schema`） |
| 4.6.2 | 为所有 DTO 添加 `@Schema` 注解描述字段含义 |
| 4.6.3 | 配置 SpringDoc 分组（auth / subject / oss） |
| 4.6.4 | 更新 `docs/api/coderclub-openapi.json` |

### 任务 4.7：Docker Compose 完善

**负责人**：Dev-A
**工时**：1 天

| 步骤 | 内容 |
|------|------|
| 4.7.1 | 添加 oss 服务到 docker-compose.yml |
| 4.7.2 | 添加 gateway 服务到 docker-compose.yml |
| 4.7.3 | 添加 MinIO 服务到 docker-compose.yml（本地开发替代外部 OSS） |
| 4.7.4 | 添加 Elasticsearch 服务到 docker-compose.yml |
| 4.7.5 | 编写 `Dockerfile.oss` 和 `Dockerfile.gateway` |

---

## 五、第四阶段：P3 长期演进

> **时间**：第 7 周起（持续）
> **目标**：业务闭环 + CI/CD

### 任务 5.1：刷题记录系统

**负责人**：Dev-B
**工时**：5 天

| 数据库表 | 用途 |
|----------|------|
| `user_answer_record` | 用户答题记录（user_id, subject_id, user_answer, is_correct, spent_time） |
| `user_wrong_book` | 错题本（user_id, subject_id, wrong_count, last_wrong_time） |
| `user_favorite` | 题目收藏（user_id, subject_id） |

### 任务 5.2：排行榜与统计

**负责人**：Dev-B
**工时**：3 天

| 功能 | 说明 |
|------|------|
| 刷题统计 | 每日/每周/总计 刷题数、正确率 |
| 排行榜 | 按刷题数、正确率排序（Redis Sorted Set） |
| 连续打卡 | 连续刷题天数统计 |

### 任务 5.3：CI/CD 流水线

**负责人**：Dev-A
**工时**：3 天

| 步骤 | 内容 |
|------|------|
| 5.3.1 | 编写 GitHub Actions / Jenkins Pipeline |
| 5.3.2 | 阶段 1：编译 + 单元测试 |
| 5.3.3 | 阶段 2：代码质量检查（SonarQube） |
| 5.3.4 | 阶段 3：构建 Docker 镜像并推送 |
| 5.3.5 | 阶段 4：部署到测试环境 |

### 任务 5.4：监控告警

**负责人**：Dev-A
**工时**：2 天

| 步骤 | 内容 |
|------|------|
| 5.4.1 | 集成 Prometheus + Grafana |
| 5.4.2 | 配置 JVM 监控（堆内存、GC、线程） |
| 5.4.3 | 配置业务监控（API 响应时间、错误率） |
| 5.4.4 | 配置告警规则（错误率 > 5%、响应时间 > 3s） |

---

## 六、人力分配总览

```
Week    Dev-A                                    Dev-B
────    ─────                                    ─────
 1      公共模块提取 (3d)                         Subject 鉴权 (2d)
        Auth 切换 (2d)                           OSS 鉴权+异常+端口 (2d)
                                                Week 1 收尾: 交叉 CR (1d)
 2      Auth Domain 修复 (1d)                    缓冲修复 + 联调 (5d)
        缓冲修复 + 联调 (4d)

 3      统一日志追踪 (1d)                         消除代码重复 (0.5d)
        清理 BOM 冗余 (0.5d)                      修复硬编码错误码 (0.5d)
        核心单元测试 auth (2d)                     日志配置统一 (0.5d)
        交叉 CR (0.5d)                            核心单元测试 subject (2d)
                                                   交叉 CR (0.5d)

 4      微信登录 (3d)                             题目搜索 ES (3d)
        API 网关 (2d)                             接口测试 (2d)

 5      API 网关 (1d)                             题目搜索 (续)
        链路追踪 (2d)                              接口测试 (续)
        Docker Compose 完善 (1d)                   API 文档完善 (1d)
        交叉 CR (0.5d)                             交叉 CR (0.5d)

 6      缓冲 + 联调 (5d)                           缓冲 + 联调 (5d)

 7+     CI/CD 流水线 (3d)                          刷题记录系统 (5d)
        监控告警 (2d)                              排行榜与统计 (3d)
```

---

## 七、里程碑与交付节点

| 里程碑 | 时间 | 交付物 | 验收标准 |
|--------|------|--------|----------|
| **M1: P0 完成** | 第 2 周末 | 公共模块 + 鉴权 + 异常处理 | 三服务启动正常，未登录请求返回 401，无权限返回 403 |
| **M2: P1 完成** | 第 3 周末 | 日志统一 + 单元测试 + 代码清洁 | 单元测试覆盖率 > 60%，日志 traceId 可串联 |
| **M3: P2 完成** | 第 6 周末 | 微信登录 + 网关 + 搜索 + 接口测试 | 网关统一入口正常，搜索功能可用，OpenAPI 文档完整 |
| **M4: P3 完成** | 第 10 周 | 刷题记录 + 排行榜 + CI/CD + 监控 | CI/CD 自动构建部署，监控面板可访问 |

---

## 八、风险与应对

| 风险 | 应对 |
|------|------|
| **公共模块提取引发大面积编译错误** | 分步切换，先 auth 再 subject 再 oss，每步独立验证 |
| **鉴权添加后前端联调困难** | 在 Gateway 未就绪前，保留 Swagger UI 测试入口，提供 Postman Collection |
| **Spring Boot 4.0.0 artifact 下载失败** | 提前配置 Maven Central fallback 仓库 |
| **Elasticsearch 集成复杂度超预期** | 降级方案：使用 MySQL FULLTEXT 索引做简单搜索，ES 推迟到 P3 |
| **微信登录对接审批延迟** | 保持 mock 模式可切换，不阻塞前端开发 |
| **人力不足（仅 2 人）** | 严格按优先级推进，P3 可适当压缩或推迟 |
| **Nacos 外部环境不稳定** | 本地 Docker Compose 添加 Nacos 服务，实现完全离线开发环境 |

---

> **文档版本**：v1.0
> **生成时间**：2025-07-30
> **下次评审**：第一阶段（P0）完成后更新进度