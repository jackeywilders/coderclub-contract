# M4-05 后端评审复核工作底稿

> 角色：后端评审（B-Review，原 Backend Codex）
> 日期：2026-08-15
> 任务来源：`pm/requirements/2026-08-13/m4-05-invalid-request-body-task.md`
> 回执：`handoff/backend-to-frontend/2026-08-15/m4-05-invalid-request-body-report.md`
> 实施提交：`371a3b1`（feat(exception): M4-05 非法请求体统一归类 400，后端项目 `main`）

## 1. 代码级复核（提交 `371a3b1`）

| 核对项 | 结果 |
| --- | --- |
| 三服务（Auth/Subject/OSS）`GlobalExceptionHandler` 均新增 `HttpMessageNotReadableException` → HTTP 400 + `ResponseResult.fail(400, "参数校验失败")` | ✅ 逐文件 diff 确认，三处实现一致 |
| 映射优先级：新 handler 比兜底 `Exception`（500）更具体，Spring 按异常类型精确匹配，不会落到 500 | ✅ 三处 handler 顺序/结构核对 |
| 响应体四字段：`success=false / code=400 / message=参数校验失败 / data=null` | ✅ `ResponseResult.fail(code, message)` data 为 null，且 `@JsonInclude(ALWAYS)` 保证序列化输出 `data: null`（与回执实测一致） |
| 错误码语义：复用既有 `REQUEST_PARAM_INVALID(400, "参数校验失败")`，与既有参数校验 400 结构对齐（G1-02 语义 / M3 联调记录 §10.4 建议） | ✅ `ResultCodeEnum` 核对 |
| 不泄露内部信息：`ex.getMessage()` 仅进日志（WARN），不返回客户端 | ✅ 三处一致 |
| 契约影响：未改动任何路径/方法/字段/鉴权 | ✅ OpenAPI SHA-256 未变（见 §2） |

## 2. 独立测试重跑（本底稿复核时执行，后端项目 `main` = `371a3b1`）

| 命令 | 结果 |
| --- | --- |
| `mvn test -pl … -Dtest=GlobalExceptionMappingTest`（三模块） | Auth 2/2、Subject 2/2、OSS 2/2，BUILD SUCCESS |
| 全量回归（三模块全部测试） | **subject 53/53**（SubjectContractTest 49 + FeignConfigTest 2 + GlobalExceptionMappingTest 2）、**oss 13/13**（FileControllerTest 11 + 2）、**auth 11/11**（AuthContractTest 8 + UserInfoVOMappingTest 1 + 2），BUILD SUCCESS |
| OpenAPI 源 SHA-256 | `7576e28a346dcf60b304bdd405f0bb82b72252df37e96013509ece00c6a14a2e` 未变（43 路径 / 43 操作，openapi 3.0.3） |

## 3. 测试代码审查要点

- 三份 `GlobalExceptionMappingTest` 均覆盖两类非法请求体：畸形 JSON（截断/语法错误）与非法 UTF-8（GBK 字节），断言 HTTP 400 + `success=false` + `code=400` + `message=参数校验失败`，对齐任务书步骤 3 要求。
- 测试风格对齐既有契约测试：standalone MockMvc + 真实 Controller + `setControllerAdvice`，不启动 Spring 上下文（无 Nacos/Redis/MySQL 依赖）。
- Auth/Subject 用真实业务控制器端点（`/auth/login`、`/subject/add`），Subject 还手工装配 `SaInterceptor` + 注入登录态与 `subject:add` 权限，验证鉴权链路上的异常映射（`tearDown` 正确清理 Sa-Token mock 上下文）。
- OSS 无 JSON body 端点，用内部 `EchoController` 测试端点触发解析异常——与回执"已知限制 1"一致，属合理覆盖方式。

## 4. 复核结论与备注

- **结论：通过，可签署。**
- 与回执声明的测试数字、响应体结构、已知限制逐项核对一致；未发现 [必须修复] / [建议修改] 问题。
- [仅供参考] 提交 `371a3b1` 创建于 2026-08-15 21:55，早于全局 `prepare-commit-msg` 钩子生效（22:08），提交消息含 `Co-Authored-By: Claude` 署名行；按 `docs/agents/git-commit-conventions.md`「历史提交保留原样」约定，不改写历史。
- 已知限制与回执一致：OSS 真实 HTTP 无法触发（无 JSON body 端点）、dev 库测试用户 `<test-account>`（id=6）未清理（dev 测试数据，M3 联调同例）。

复核签署：后端评审（B-Review），2026-08-15
