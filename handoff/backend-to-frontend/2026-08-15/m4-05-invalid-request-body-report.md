# M4-05 后端执行报告：非法请求体处理

> **任务角色：** 后端实现（B-Impl，原 Claude Code 后端）
> **任务来源：** `pm/requirements/2026-08-13/m4-05-invalid-request-body-task.md`（协调 PM 批准）
> **复核角色：** 后端评审（B-Review，原 Backend Codex）
> **报告日期：** 2026-08-15
> **契约影响：** 无（未改变 HTTP 契约的字段/路径/方法；非法请求体业务归类 500→400）

## 1. 来源与提交哈希

| 项目 | 值 |
| --- | --- |
| 来源项目 | `G:/Dev/backend/Club/CoderClub` |
| 来源分支 | `main` |
| 实施提交哈希 | `371a3b1`（feat(exception): M4-05 非法请求体统一归类 400） |
| 回执提交哈希 | `a453980`（docs(handoff): M4-05 非法请求体处理回执） |

## 2. 实测请求/响应记录（真实 HTTP，Nacos dev 环境）

> 环境：Auth `http://localhost:3100`、Subject `http://localhost:3000`，均连接 Nacos dev（<nacos-dev-addr>:<nacos-port>）。请求体以 UTF-8 文本文件 / GBK 原始字节文件经 `curl.exe --data-binary @file` 发送（避免命令行码页编码干扰）。

### 2.1 非法 UTF-8（GBK 字节）

- **请求**：`POST /auth/login` 与 `POST /subject/getSubjectPage`，`Content-Type: application/json`；body 为 GBK 编码 JSON（中文"测试用户"以 GBK 字节 0xB2E2 CAD4 D3C3 BBA7 表示；原始 43 字节，hex 前缀 `7b22757365724e616d65223a22b2e2cad4d3c3bb...`）。
- **修改前（旧代码实测）**：
  - HTTP/1.1 500
  - `{"code":500,"data":null,"message":"系统繁忙,请稍候再试","success":false}`
- **修改后（新代码实测）**：
  - HTTP/1.1 400
  - `{"code":400,"data":null,"message":"参数校验失败","success":false}`
  - 原始响应（curl -i，Auth /auth/login）：
    ```
    HTTP/1.1 400
    Content-Type: application/json
    {"code":400,"data":null,"message":"参数校验失败","success":false}
    ```

### 2.2 畸形 JSON（截断/语法错误）

- **请求**：`POST /auth/login`（body `{"userName": "jackey", "password": }`）与 `POST /subject/getSubjectPage`（body `{"pageNo": 1, "pageSize": }`），`Content-Type: application/json`。
- **修改前（旧代码实测）**：HTTP/1.1 500 + `{"code":500,"data":null,"message":"系统繁忙,请稍候再试","success":false}`
- **修改后（新代码实测）**：
  - HTTP/1.1 400
  - `{"code":400,"data":null,"message":"参数校验失败","success":false}`
  - 原始响应（curl -i，Subject /subject/getSubjectPage，携带登录 token）：
    ```
    HTTP/1.1 400
    Content-Type: application/json
    {"code":400,"data":null,"message":"参数校验失败","success":false}
    ```

### 2.3 正常请求对照

- `POST /auth/login`（合法 JSON，错误口令）：HTTP/1.1 200 + `{"code":400,"data":null,"message":"用户名或密码错误","success":false}`（业务 400 走 HTTP 200，既有语义）
- `POST /subject/getSubjectPage`（合法 JSON + token）：HTTP/1.1 200 + 分页数据（total=28），证明鉴权与正常链路未受影响。

## 3. 异常映射测试命令与原始输出

**命令（新增全局异常映射测试）**：

```bash
mvn test -pl coder-club-auth/coder-club-auth-app/coder-club-auth-app-controller,coder-club-subject/coder-club-subject-app/coder-club-subject-app-controller,coder-club-oss -Dtest=GlobalExceptionMappingTest
```

**输出（原始，节选）**：

```
[INFO] Tests run: 2, Failures: 0, Errors: 0, Skipped: 0 -- in com.jackey.subject.app.handler.GlobalExceptionMappingTest
[INFO] Tests run: 2, Failures: 0, Errors: 0, Skipped: 0 -- in com.jackey.oss.handler.GlobalExceptionMappingTest
[INFO] Tests run: 2, Failures: 0, Errors: 0, Skipped: 0 -- in com.jackey.auth.app.handler.GlobalExceptionMappingTest
[INFO] BUILD SUCCESS
```

**全量回归（三模块全部测试，原始输出节选）**：

```
[INFO] Tests run: 53, Failures: 0, Errors: 0, Skipped: 0  (coder-club-subject-app-controller: SubjectContractTest 49 + FeignConfigTest 2 + GlobalExceptionMappingTest 2)
[INFO] Tests run: 13, Failures: 0, Errors: 0, Skipped: 0  (coder-club-oss: FileControllerTest 11 + GlobalExceptionMappingTest 2)
[INFO] Tests run: 11, Failures: 0, Errors: 0, Skipped: 0  (coder-club-auth-app-controller: AuthContractTest 8 + UserInfoVOMappingTest 1 + GlobalExceptionMappingTest 2)
[INFO] BUILD SUCCESS
```

## 4. OpenAPI 变化结论

- **无变化**。`docs/api/coderclub-openapi.json` 未修改（SHA-256 不变，43 路径 / 43 操作）。
- 异常映射为服务端运行时行为，不影响契约结构（无提案编号）。

## 5. 已知限制

1. **OSS 真实 HTTP 无法触发**：OSS 现有端点无 JSON body（`upload` 为 multipart、`getUrl` 为 GET），`HttpMessageNotReadableException` 无法经真实 HTTP 触发，由 standalone 单测（GlobalExceptionMappingTest 2 例）覆盖。
2. **实测环境**：Nacos dev（<nacos-dev-addr>:<nacos-port>，需 `NACOS_USERNAME`/`NACOS_PASSWORD` 环境变量）；本报告不含任何凭据。
3. **未覆盖的非法输入类型**：超大请求体（413）、Content-Type 缺失/不符等由框架默认行为处理，不在本任务范围。
4. **测试数据**：为完成 Subject 鉴权链路实测，在 dev 库注册了测试用户 `<test-account>`（id=6），未清理（dev 环境测试数据，M3 联调同例）。

## 6. 声明

- 未修改交接仓库 `api/coderclub-openapi.json` 快照与 `status/sync-manifest.json`。
- 未改变已批准契约的字段/路径/方法；未写入任何凭据。
- 所有实测请求/响应、测试输出与提交哈希为真实结果，未伪造。

## 7. 后端评审复核签署（2026-08-15）

- [x] 代码级复核：三服务 `GlobalExceptionHandler` 新增 `HttpMessageNotReadableException` → HTTP 400 + 统一响应体（success=false/code=400/message=参数校验失败/data=null），映射优先级与响应结构核对通过 — **通过**
- [x] 独立重跑：`GlobalExceptionMappingTest` 三模块各 2/2；全量回归 subject 53/53、oss 13/13、auth 11/11，BUILD SUCCESS — **通过**
- [x] OpenAPI SHA-256 未变（`7576e28a…`，43 路径 / 43 操作）— **通过**
- [x] 已知限制（OSS 无 JSON body 端点由单测覆盖、dev 测试用户未清理）核验 — **通过**
- [x] M4-05 关闭条件满足；签署本回执

**复核签署**：后端评审（B-Review），2026-08-15（工作底稿：`designs/backend/2026-08-15/m4-05-invalid-request-body-review-workpaper.md`）
