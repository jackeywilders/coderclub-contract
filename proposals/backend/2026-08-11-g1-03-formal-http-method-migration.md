# G1-03 后端契约变更提案：分类与标签正式 HTTP 方法迁移

> **提案角色：** Backend Codex
>
> **提案状态：** PM 已确认，待 Claude Code 后端实施
>
> **提出日期：** 2026-08-11
>
> **关联需求：** `pm/requirements/2026-08-11-g1-03-formal-http-method-migration.md`

## 1. 提案摘要

当前分类和标签的更新、删除能力同时存在历史 POST 端点和正式 PUT/DELETE 端点。PM 已确认将 PUT/DELETE 固化为唯一正式契约，并在本次 G1-03 后端实现中立即移除四个旧 POST 映射；该变更必须在正式联调开始前生效。

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

## 5. PM 已确认的迁移策略

PM 于 2026-08-11 明确确认以下策略，覆盖本提案原先提出的兼容保留建议：

| 项目 | 已确认决策 |
| --- | --- |
| 旧 POST 端点 | 本次 G1-03 后端实现中立即移除四个旧 POST Controller 映射 |
| 生效时点 | 正式前后端联调开始前必须完成并验证 |
| 兼容路由 | 不保留旧 POST 兼容路由，不新增 410 响应 |
| 过渡版本/日期 | 不设置后端 `1.1.0` 过渡版本，不设置 `2026-08-31` 延期窗口 |
| 业务能力 | 分类/标签更新和删除能力不删除，分别由正式 PUT/DELETE 承载 |
| 旧 POST 验证 | 旧 POST 请求只要求返回 4xx，不固定 404 或 405 的具体状态 |

本策略不改变 DTO 字段、响应体、鉴权语义、领域服务或数据库行为。前端必须在正式联调前改用四个正式 PUT/DELETE，并从 API 基线移除四个旧 POST 记录。

## 6. 影响分析

### 后端

- 修改范围限定为 `SubjectCategoryController`、`SubjectLabelController`、对应 Controller 契约测试和运行时 OpenAPI 源。
- 更新方法的请求体、校验分组、领域服务和响应体保持不变，仅删除旧 POST 映射。
- 删除方法的请求形态从旧 JSON body 迁移到正式路径参数；调用方必须改为 `/delete/{id}`。
- 不涉及数据库迁移、实体字段、领域服务、鉴权配置或错误码调整。

### 前端

- 分类和标签更新请求方法由 POST 改为 PUT，请求体保持原 DTO 结构并包含 `id`。
- 分类和标签删除请求改为 DELETE，并将 `id` 放入 URL 路径，不再发送旧 JSON body。
- 正式联调开始前不得依赖四个旧 POST；旧 POST 不再作为后端兼容入口。

### PM 与契约治理

- PM 已确认立即移除策略；在 Backend、Frontend 和 PM 三方证据齐全后关闭 G1-03。
- Claude Code 后端负责 PM 确认后的 Java、测试和后端运行时 OpenAPI 源实现。
- Claude Code 前端负责前端基线或业务调用调整，Frontend Codex 负责复验。
- PM 负责根据后端源新提交生成新的开发快照并更新同步清单。

## 7. 回滚边界

如果正式 PUT/DELETE 在正式联调发现请求绑定、网关路由或前端消费阻塞，回滚只允许恢复本次实现提交中的 Controller 映射和对应 OpenAPI 源，或回退到本提案实施前的已验证提交；不涉及数据库回滚和数据修复。

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

## 9. PM 决策记录

PM 于 2026-08-11 已确认以下事项，本提案可进入 Claude Code 后端实施阶段：

1. 批准 PUT/DELETE 为唯一正式方法，并在本次实现中删除四个旧 POST 路由。
2. 拒绝兼容端点保留策略；不设置 `1.1.0` 过渡版本和 `2026-08-31` 延期窗口。
3. 批准正式联调前完成后端路由移除、前端基线切换和对应验证。
4. 接受 OpenAPI 统计预期从 `45 paths / 47 operations` 变为 `43 paths / 43 operations`，由 PM 在实现完成后重新生成开发快照。

本提案已生效，但仅授权 Claude Code 后端按本提案修改后端项目；Backend Codex 负责转交任务、审查提交和复验，不得直接修改 Java、测试或后端运行时 API 源。
