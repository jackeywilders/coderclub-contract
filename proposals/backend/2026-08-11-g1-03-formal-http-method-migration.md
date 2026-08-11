# G1-03 后端契约变更提案：分类与标签正式 HTTP 方法迁移

> **提案角色：** Backend Codex
>
> **提案状态：** 待 PM 确认
>
> **提出日期：** 2026-08-11
>
> **关联需求：** `pm/requirements/2026-08-11-g1-03-formal-http-method-migration.md`

## 1. 提案摘要

当前分类和标签的更新、删除能力同时存在历史 POST 兼容端点和正式 PUT/DELETE 端点。建议将 PUT/DELETE 固化为唯一正式契约，前端首轮正式联调只使用正式方法；历史 POST 在完成前端切换和发布确认前继续保留，随后在一个明确的后端版本中移除。

本提案只记录契约变更建议，不修改后端 Java、测试、运行时 OpenAPI 或交接仓库 `api/` 快照。未获得 PM 确认前，Claude Code 后端不得执行实现变更。

## 2. 来源与当前实现

| 项目 | 当前值 |
| --- | --- |
| 后端项目 | `G:/Dev/backend/Club/CoderClub` |
| 后端分支 | `main` |
| 后端当前观察提交 | `7c82cbec5433a2e7aa44582e3c0ddba459c4c886` |
| Maven 项目版本标记 | `1.0` |
| 已批准开发快照 | `api/coderclub-openapi.json`，快照提交 `1a2aff823b3b941b6d9c0ccd8a29f40545d3eb17` |
| 已批准快照 SHA-256 | `87e122b545ed529edc167b80279869205440be84e12c4407850dfa1d4ff2166b` |
| 当前 API 统计 | 45 paths / 47 operations |
| 当前发布状态 | `releaseStatus=not-published`，`finalReleaseStatus=not-published` |

当前运行时证据来自 Backend Codex G1 回执：`handoff/backend-to-frontend/2026-08-10-gate1-backend-receipt.md`。四组端点均使用 `@SaCheckLogin`，当前没有新增角色或细粒度权限要求。

## 3. 旧端点与正式端点映射

### 3.1 分类

| 操作 | 当前旧端点 | 建议正式端点 | 当前 Controller 位置 | 请求形态 |
| --- | --- | --- | --- | --- |
| 更新分类 | `POST /subject/category/update` | `PUT /subject/category/update` | `SubjectCategoryController.java:79`、`:118` | JSON body `SubjectCategoryDTO`，包含分类 `id`，使用 `Groups.Update` 校验 |
| 删除分类 | `POST /subject/category/delete` | `DELETE /subject/category/delete/{id}` | `SubjectCategoryController.java:90`、`:132` | 旧端点为 JSON body `SubjectCategoryDTO` + `Groups.Delete`；正式端点使用路径参数 `Long id` |

### 3.2 标签

| 操作 | 当前旧端点 | 建议正式端点 | 当前 Controller 位置 | 请求形态 |
| --- | --- | --- | --- | --- |
| 更新标签 | `POST /subject/label/update` | `PUT /subject/label/update` | `SubjectLabelController.java:70`、`:108` | JSON body `SubjectLabelDTO`，包含标签 `id`，使用 `Groups.Update` 校验 |
| 删除标签 | `POST /subject/label/delete` | `DELETE /subject/label/delete/{id}` | `SubjectLabelController.java:81`、`:122` | 旧端点为 JSON body `SubjectLabelDTO` + `Groups.Delete`；正式端点使用路径参数 `Long id` |

四个正式端点均保持现有领域服务调用、`ResponseResult<Boolean>` 响应和登录校验语义。删除操作必须继续使用 `/{id}` 路径参数，不得改回 JSON body。

## 4. 建议的目标契约

PM 确认后，后端运行时 Controller 和 OpenAPI 源应达到以下状态：

1. `PUT /subject/category/update` 是分类更新唯一映射。
2. `DELETE /subject/category/delete/{id}` 是分类删除唯一映射。
3. `PUT /subject/label/update` 是标签更新唯一映射。
4. `DELETE /subject/label/delete/{id}` 是标签删除唯一映射。
5. 四个旧 POST 路由不再映射；不新增 410 兼容响应，也不保留无路径参数的 DELETE 变体。
6. 其他合法 POST 接口，包括登录、注册、分类/标签新增和题目分页，不在本提案范围内。
7. 不改变 DTO 字段、响应字段、业务错误码、鉴权语义、领域服务和数据库行为。

移除四个旧操作并删除两个仅承载旧 POST 的无参数路径后，OpenAPI 预期从 `45 paths / 47 operations` 变为 `43 paths / 43 operations`。实际统计以实现后重新解析的后端 API 源为准。

## 5. 兼容期限建议（待 PM 决策）

由于当前项目仍未发布，且前端首轮正式联调尚未完成，建议不要在 PM 确认前直接删除旧 POST。建议采用以下兼容策略：

| 项目 | 建议 |
| --- | --- |
| 兼容端点保留范围 | 继续保留四个旧 POST，仅作为迁移期兼容入口；不再向前端文档和新代码推荐 |
| 前端切换要求 | 前端首轮正式联调只调用四个 PUT/DELETE；前端 API 基线不得继续声明四个旧 POST |
| 建议移除版本 | 后端 `1.1.0` 版本，前提是下列移除条件全部满足 |
| 建议硬截止日期 | 2026-08-31（Asia/Shanghai）；未满足条件时不得自动延长，须由 PM 重新确认延期 |
| 到期行为 | PM 确认后由 Claude Code 后端删除旧 POST Controller 映射，并同步更新后端运行时 OpenAPI 源 |
| 期限内新调用 | 不允许新增对旧 POST 的调用、文档或测试依赖 |

该版本和日期是迁移建议，不是已生效的发布承诺；只有 PM 在提案上确认后，才可作为实施约束。

### 5.1 移除条件

至少满足以下条件后，才允许在 `1.1.0` 中移除旧 POST：

1. Frontend 主线 API 基线已删除四个旧 POST，业务调用已改为正式 PUT/DELETE。
2. Frontend 已完成 `npm run api:check` 和 `npm test`，并向 PM 提供完整提交哈希和结果。
3. 后端 Controller 测试证明四个正式端点可完成请求绑定和成功响应；旧 POST 请求返回 4xx，测试不固定 404 或 405 的具体值。
4. PM 已确认前后端均不再依赖旧 POST，并批准删除窗口。
5. 后端运行时 OpenAPI 源、PM 开发快照和同步清单由各自 Owner 更新完成；Backend Codex 不直接修改 `api/` 或 `sync-manifest.json`。

## 6. 影响分析

### 后端

- 修改范围限定为 `SubjectCategoryController`、`SubjectLabelController`、对应 Controller 契约测试和运行时 OpenAPI 源。
- 更新方法的请求体、校验分组、领域服务和响应体保持不变，仅删除旧 POST 映射。
- 删除方法的请求形态从旧 JSON body 迁移到正式路径参数；调用方必须改为 `/delete/{id}`。
- 不涉及数据库迁移、实体字段、领域服务、鉴权配置或错误码调整。

### 前端

- 分类和标签更新请求方法由 POST 改为 PUT，请求体保持原 DTO 结构并包含 `id`。
- 分类和标签删除请求改为 DELETE，并将 `id` 放入 URL 路径，不再发送旧 JSON body。
- 首轮正式联调不得依赖四个旧 POST；旧 POST 仅作为迁移期后端兼容入口。

### PM 与契约治理

- PM 负责确认兼容版本、硬截止日期和移除条件，并在三方证据齐全后关闭 G1-03。
- Claude Code 后端负责 PM 确认后的 Java、测试和后端运行时 OpenAPI 源实现。
- Claude Code 前端负责前端基线或业务调用调整，Frontend Codex 负责复验。
- PM 负责根据后端源新提交生成新的开发快照并更新同步清单。

## 7. 回滚边界

如果正式 PUT/DELETE 在迁移期发现请求绑定、网关路由或前端联调阻塞，回滚只允许恢复本次实现提交中的 Controller 映射和对应 OpenAPI 源，或回退到本提案实施前的已验证提交；不涉及数据库回滚和数据修复。

回滚前必须由 PM 记录原因、影响范围和新的截止计划。回滚不得通过继续新增旧 POST 调用来掩盖正式端点缺陷；前端基线和交接快照应由对应 Owner 按同一提交链路重新同步。

## 8. 验证方案

PM 确认并由 Claude Code 后端实现后，Backend Codex 复验以下项目：

### 8.1 后端 Controller 契约测试

```powershell
mvn -pl coder-club-subject/coder-club-subject-app/coder-club-subject-app-controller -am '-Dtest=SubjectContractTest' '-Dsurefire.failIfNoSpecifiedTests=false' test
```

验收重点：四个正式 PUT/DELETE 请求完成参数绑定并返回统一成功响应；四个旧 POST 请求返回 4xx，测试不固定为 404 或 405。

### 8.2 OpenAPI JSON 与统计

```powershell
$path = 'G:/Dev/backend/Club/CoderClub/docs/api/coderclub-openapi.json'
$doc = Get-Content -LiteralPath $path -Raw -Encoding UTF8 | ConvertFrom-Json
$paths = @($doc.paths.PSObject.Properties)
$methods = @('get', 'post', 'put', 'delete', 'patch', 'options', 'head', 'trace')
$operations = @($paths | ForEach-Object {
    $_.Value.PSObject.Properties | Where-Object { $methods -contains $_.Name }
})
"openapi=$($doc.openapi); paths=$($paths.Count); operations=$($operations.Count)"
```

预期为 `openapi=3.0.3; paths=43; operations=43`，并逐项确认四个旧 POST 不存在、四个正式 PUT/DELETE 存在。

### 8.3 前端消费校验

```powershell
npm run api:check
npm test
```

Frontend 应提供 API 基线、业务调用检查、测试结果和完整提交哈希。Backend Codex 只复验结果，不修改前端项目。

## 9. PM 待确认项

请 PM 明确确认以下决策后，再移交 Claude Code 后端执行：

1. 是否批准 PUT/DELETE 为唯一正式方法，并删除四个旧 POST 路由。
2. 是否接受兼容端点保留至后端 `1.1.0`，建议硬截止日期为 2026-08-31。
3. 是否接受“前端切换、验证证据、PM 批准删除窗口”作为全部移除条件。
4. 是否接受 OpenAPI 统计预期从 45/47 变为 43/43，并由 PM 在实现完成后重新生成开发快照。

在上述事项确认前，本提案不构成已生效的 API 变更，前端不得将旧 POST 移除视为已完成，后端也不得开始删除映射。
