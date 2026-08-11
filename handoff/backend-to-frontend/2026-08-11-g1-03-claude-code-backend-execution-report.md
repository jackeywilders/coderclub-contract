# G1-03 后端执行回执

> 回执角色：Backend Codex
>
> 实际执行角色：Claude Code 后端
>
> 执行日期：2026-08-11
>
> 验收边界：按 PM 已确认的 G1-03 方案，立即移除四个旧 POST，不保留兼容路由、不新增 410、不设置过渡版本或延期窗口。

## 1. 来源与提交

| 项目 | 值 |
| --- | --- |
| 来源项目 | `G:/Dev/backend/Club/CoderClub` |
| 来源分支 | `main` |
| 实现提交 | `6c1a95bb679b65191488531537b79aa6948a4399` |
| 实现提交父提交 | `7c82cbec5433a2e7aa44582e3c0ddba459c4c886` |
| 批准提案 | `proposals/backend/2026-08-11-g1-03-formal-http-method-migration.md` |
| 执行任务 | `pm/requirements/2026-08-11-g1-03-claude-code-backend-execution-task.md` |
| 后端工作区状态 | `main`，干净；实现提交尚未推送 |

Claude Code 后端只修改了批准任务列出的四个文件。未修改交接仓库 `api/coderclub-openapi.json`、`status/sync-manifest.json`、前端项目或其他后端业务文件。

## 2. 实际修改文件

- `coder-club-subject/coder-club-subject-app/coder-club-subject-app-controller/src/main/java/com/jackey/subject/app/controller/SubjectCategoryController.java`
  - 删除 `POST /subject/category/update`。
  - 删除 `POST /subject/category/delete`。
- `coder-club-subject/coder-club-subject-app/coder-club-subject-app-controller/src/main/java/com/jackey/subject/app/controller/SubjectLabelController.java`
  - 删除 `POST /subject/label/update`。
  - 删除 `POST /subject/label/delete`。
- `coder-club-subject/coder-club-subject-app/coder-club-subject-app-controller/src/test/java/com/jackey/subject/app/controller/SubjectContractTest.java`
  - 增加四个正式 PUT/DELETE 的请求绑定和成功响应测试。
  - 将四个旧 POST 测试改为登录状态下断言未映射请求返回 4xx。
- `docs/api/coderclub-openapi.json`
  - 删除四个旧 POST 操作及两个仅承载旧 POST 的无参数删除路径。
  - 清理两个正式 PUT 的兼容入口描述。

未发现批准范围外的 Controller、领域服务、DTO、鉴权、数据库或错误码变更。

## 3. 当前正式接口

| 操作 | 状态 |
| --- | --- |
| `PUT /subject/category/update` | 存在，JSON body 保持 `SubjectCategoryDTO`，继续使用 `Groups.Update` 和登录校验 |
| `DELETE /subject/category/delete/{id}` | 存在，继续使用路径参数 `id`、领域服务和登录校验 |
| `PUT /subject/label/update` | 存在，JSON body 保持 `SubjectLabelDTO`，继续使用 `Groups.Update` 和登录校验 |
| `DELETE /subject/label/delete/{id}` | 存在，继续使用路径参数 `id`、领域服务和登录校验 |

四个旧 POST 路径已不再映射；按 PM 要求不固定 404/405，只要求客户端收到 4xx。

## 4. 独立复验结果

### 4.1 Controller 契约测试

执行命令：

```powershell
mvn -pl coder-club-subject/coder-club-subject-app/coder-club-subject-app-controller -am '-Dtest=SubjectContractTest' '-Dsurefire.failIfNoSpecifiedTests=false' test
```

实际结果：

- `Tests run: 45`
- `Failures: 0`
- `Errors: 0`
- `Skipped: 0`
- `BUILD SUCCESS`

### 4.2 运行时 OpenAPI 源

文件：`G:/Dev/backend/Club/CoderClub/docs/api/coderclub-openapi.json`

| 检查项 | 结果 |
| --- | --- |
| JSON 可解析 | 通过 |
| `openapi` | `3.0.3` |
| 文档版本 | `1.0.0` |
| 路径数量 | `43` |
| 操作数量 | `43` |
| SHA-256 | `cf6998f73480cd27f23fcacbc7b662f49ce33d281da82a855e4d0ea5172852f6` |
| `POST /subject/category/update` | 不存在 |
| `POST /subject/category/delete` | 不存在 |
| `POST /subject/label/update` | 不存在 |
| `POST /subject/label/delete` | 不存在 |
| 四个正式 PUT/DELETE | 均存在 |

### 4.3 提交范围与结构差异

- `git diff --check 7c82cbec5433a2e7aa44582e3c0ddba459c4c886 6c1a95bb679b65191488531537b79aa6948a4399`：通过。
- 提交文件数为 4，均在 PM 批准的文件清单内。
- OpenAPI 差异仅包含四个旧 POST 操作的删除、两个旧无参数删除路径的删除，以及两个正式 PUT 描述中“兼容入口”等文字的清理。
- 其他路径、HTTP 方法、请求字段、响应结构、鉴权结构和组件未发现非目标变更。

## 5. 已知限制与后续动作

1. 本次验证是 Controller MockMvc 契约测试，不是部署到网关或真实服务实例后的端到端 HTTP 验证；正式联调前仍需按环境验证网关路由和前端请求。
2. 交接仓库 `api/coderclub-openapi.json` 和 `status/sync-manifest.json` 按任务边界保持不变。PM 需要基于后端提交重新生成并审核新的开发契约快照，前端在快照更新后改用四个正式 PUT/DELETE。
3. 运行时 OpenAPI 中仍存在本次任务之前已有的示例密码/Token 字段和值；本次没有新增真实凭据或本机绝对路径，且该清理不在 G1-03 批准范围内。如发布政策禁止任何凭据样例，应另行提出并批准文档脱敏任务。
4. G1-03 后端证据已具备，但不代表 Gate 1 整体关闭；前端消费验证、PM 契约快照更新及其他未关闭事项仍由对应角色处理。

## 6. 前端联调要求

- 更新和删除只调用上表四个正式接口。
- 更新请求继续发送原 DTO body，并包含 `id`。
- 删除请求将 `id` 放入 URL：`/subject/category/delete/{id}` 或 `/subject/label/delete/{id}`，不再发送旧 JSON body。
- 不再依赖四个旧 POST；旧 POST 预期返回 4xx。
