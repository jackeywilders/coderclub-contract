# G1-03 Claude Code 后端最终执行任务

> **任务状态：** PM 已确认，可执行
>
> **发布角色：** PM / 跨项目协调 Codex
>
> **转交角色：** Backend Codex
>
> **实际代码 Owner：** Claude Code 后端
>
> **批准提案：** `proposals/backend/2026-08-11/g1-03-formal-http-method-migration.md`
>
> **批准依据：** PM 于 2026-08-11 明确确认旧 POST 不保留兼容路由，并在正式联调前立即移除

## 1. 执行目标

在后端正式联调开始前，将分类和标签的更新、删除操作固定为唯一正式 HTTP 方法：

- `PUT /subject/category/update`
- `DELETE /subject/category/delete/{id}`
- `PUT /subject/label/update`
- `DELETE /subject/label/delete/{id}`

四个旧 POST 映射必须在本次实现中移除。旧 POST 不保留兼容路由，不新增 410 响应，不设置 `1.1.0` 过渡版本或 `2026-08-31` 延期窗口。

## 2. Backend Codex 转交约束

Backend Codex 必须将本任务转交 Claude Code 后端执行，不得自行修改后端 Java、测试或运行时 OpenAPI 源。

Backend Codex 的职责仅包括：

1. 向 Claude Code 后端传递本任务和批准提案。
2. 审查 Claude Code 后端提交的差异，确认没有超出范围的业务变更。
3. 复验测试、OpenAPI 统计和旧 POST 不再映射的证据。
4. 提交完整后端回执，包含来源项目、分支、完整提交哈希、影响文件、验证命令、结果和已知限制。

## 3. Claude Code 后端允许修改的文件

仅允许修改后端项目中的以下文件范围：

- `G:/Dev/backend/Club/CoderClub/coder-club-subject/coder-club-subject-app/coder-club-subject-app-controller/src/main/java/com/jackey/subject/app/controller/SubjectCategoryController.java`
- `G:/Dev/backend/Club/CoderClub/coder-club-subject/coder-club-subject-app/coder-club-subject-app-controller/src/main/java/com/jackey/subject/app/controller/SubjectLabelController.java`
- `G:/Dev/backend/Club/CoderClub/coder-club-subject/coder-club-subject-app/coder-club-subject-app-controller/src/test/java/com/jackey/subject/app/controller/SubjectContractTest.java`
- `G:/Dev/backend/Club/CoderClub/docs/api/coderclub-openapi.json`

不得修改交接仓库 `api/coderclub-openapi.json`、`status/sync-manifest.json`、PM 状态文件、前端项目或其他无关业务文件。

## 4. 实现要求

1. 删除 `SubjectCategoryController` 中旧的 `@PostMapping("/update")` 和 `@PostMapping("/delete")`。
2. 删除 `SubjectLabelController` 中旧的 `@PostMapping("/update")` 和 `@PostMapping("/delete")`。
3. 保留正式 PUT 更新方法及 JSON body、`Groups.Update` 校验和 `id` 字段。
4. 保留正式 DELETE `/{id}` 方法及路径参数绑定；不得改回 JSON body。
5. 保留现有 `@SaCheckLogin`、领域服务、响应体、DTO 字段、业务错误码和数据库行为。
6. 不修改其他合法 POST 接口，包括登录、注册、分类/标签新增和题目分页。
7. 旧 POST 请求必须不再成功映射；测试只断言 4xx，不固定 404 或 405。
8. 同一后端实现提交中同步更新运行时 OpenAPI 源，移除四个旧 POST 操作和两个只承载旧 POST 的无参数删除路径。

## 5. 必须执行的验证

运行后端 Controller 契约测试：

```powershell
mvn -pl coder-club-subject/coder-club-subject-app/coder-club-subject-app-controller -am '-Dtest=SubjectContractTest' '-Dsurefire.failIfNoSpecifiedTests=false' test
```

解析并统计运行时 OpenAPI：

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

预期结果为 `openapi=3.0.3; paths=43; operations=43`，并逐项确认：

- 四个旧 POST 不存在。
- 两个正式 PUT 存在。
- 两个正式 DELETE `/{id}` 存在。
- 其他 API 路径、方法、字段、响应和鉴权结构没有非目标变化。

## 6. 完成标准与回执

Claude Code 后端完成后，Backend Codex 必须提供：

1. 后端项目分支和完整实现提交哈希。
2. 实际修改文件清单和相对批准提案的差异摘要。
3. Controller 契约测试完整命令和结果。
4. OpenAPI 新 SHA-256、路径/操作统计及四个旧 POST 移除证据。
5. 已知限制、回滚边界和前端下一步动作。

未同时具备上述证据前，G1-03 不得关闭，PM 不得生成新的交接契约快照，也不得更新 `finalReleaseStatus`。
