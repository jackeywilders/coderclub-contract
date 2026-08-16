# M4-05 关闭验收

> **验收角色：** 协调 PM
> **验收日期：** 2026-08-16
> **任务：** M4-05 非法请求体处理
> **任务书：** `pm/requirements/2026-08-13/m4-05-invalid-request-body-task.md`
> **执行回执：** `handoff/backend-to-frontend/2026-08-15/m4-05-invalid-request-body-report.md`
> **复核签署：** 后端评审（B-Review），2026-08-15
> **验收结论：** ✅ **通过，M4-05 关闭**

## 关闭条件逐项核验

| 条件 | 要求 | 证据 | 结论 |
| --- | --- | --- | --- |
| 1 | 非法 UTF-8 与畸形 JSON 请求实测返回 400（原始请求与响应记录） | 回执 §2：非法 UTF-8（GBK）与畸形 JSON 修改前 500 → 修改后 HTTP 400 + `{"code":400,"message":"参数校验失败"}`；含 curl -i 原始响应 | ✅ |
| 2 | 全局异常映射测试通过（覆盖非法请求体） | GlobalExceptionMappingTest 三模块各 2/2；`HttpMessageNotReadableException` → HTTP 400 + 统一响应体 | ✅ |
| 3 | 既有测试全绿 | 全量回归 subject 53/53、oss 13/13、auth 11/11，BUILD SUCCESS | ✅ |
| 4 | 回执含原始请求/响应、测试输出与提交哈希，后端评审复核签署 | 实施提交 `371a3b1`、回执 `a453980`；签署 2026-08-15（工作底稿 `designs/backend/2026-08-15/m4-05-invalid-request-body-review-workpaper.md`） | ✅ |

## 关键核验

- **归类 400**：三服务 `GlobalExceptionHandler` 新增 `HttpMessageNotReadableException` → HTTP 400 + `参数校验失败`，业务 400 仍走 HTTP 200（既有语义不受影响，正常链路实测对照通过）。
- **真实 HTTP 实测**：Nacos dev 环境真实 curl 验证（非法 UTF-8 GBK 字节、畸形 JSON），修改前后对比记录完整。
- **契约影响**：OpenAPI SHA-256 未变（`7576e28a…`，43/43）——异常映射为运行时行为，不影响契约结构。

## 已知限制（验收知悉，不阻塞关闭）

1. OSS 端点无 JSON body，`HttpMessageNotReadableException` 无法真实 HTTP 触发，由 standalone 单测覆盖（2 例）。
2. 超大请求体（413）、Content-Type 缺失等由框架默认行为处理，不在本任务范围。
3. dev 库注册测试用户 `<test-account>`（id=6）未清理（dev 环境测试数据，M3 联调同例）。

## 备注

- 无阻塞项；任务书 §4 关闭条件 1-4 全部满足。
- 验收结论写入 `status/pm.json`（M4-05 验收通过）。
