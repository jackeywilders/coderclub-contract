# G1-03 开发契约快照 `parameters` 结构缺陷结论

> **提案角色：** Claude Code 前端
> **日期：** 2026-08-11
> **复核角色：** PM / 跨项目协调 Codex
> **影响事项：** 前端 API 基线更新（G1-03 关闭条件之一）被阻塞
> **相关提交：** `21f6f64`（refresh g1-03 api snapshot）、`73cc5b0`（sync api description correction）

---

## 一、问题摘要

PM 开发契约快照 `api/coderclub-openapi.json`（提交 `73cc5b0`，SHA-256 `5a8919e7...`，43 paths / 43 operations）中，**8 个操作的 `parameters` 字段被序列化为单个对象，而非 OpenAPI 规范要求的数组**。

该结构导致前端 `check-api-spec.mjs` 的 `summarizeParameters` 在执行 `[...(operation.parameters ?? [])]` 展开时抛出 `(operation.parameters ?? []) is not iterable`，前端 `npm run api:check` 无法消费该快照，进而**无法完成 G1-03 关闭条件所要求的"以本快照为输入更新前端 API 基线"**。

## 二、证据

### 1. 复现命令

```powershell
cd G:\Dev\backend\Club\CoderClubFront
$env:CODERCLUB_API_SPEC_PATH = 'G:\Dev\backend\Club\coderclub-contract\api\coderclub-openapi.json'
npm run api:check
```

实际输出：

```
API spec check failed: (operation.parameters ?? []) is not iterable
```

### 2. 结构对比（同一路径，快照 vs 后端权威源）

以 `GET /auth/admin/user/{id}` 为例：

- **PM 快照**（`parameters` 为对象）：
  ```json
  "parameters": {
    "name": "id",
    "in": "path",
    "required": true,
    "description": "用户 ID",
    "schema": { "type": "integer", "format": "int64" }
  }
  ```
- **后端权威源**（`parameters` 为数组）：
  ```json
  "parameters": [
    { "name": "id", "in": "path", "required": true, "description": "用户 ID", "schema": { "type": "integer", "format": "int64" } }
  ]
  ```

### 3. 受影响的 8 个操作

| # | 方法 | 路径 |
|---|------|------|
| 1 | GET | `/auth/admin/user/{id}` |
| 2 | DELETE | `/auth/role/delete/{id}` |
| 3 | DELETE | `/auth/permission/delete/{id}` |
| 4 | DELETE | `/subject/category/delete/{id}` |
| 5 | GET | `/subject/label/list` |
| 6 | DELETE | `/subject/label/delete/{id}` |
| 7 | DELETE | `/subject/remove/{id}` |
| 8 | GET | `/subject/querySubjectInfo/{id}` |

共同特征：均为**单路径参数**操作。疑似快照生成环节在单参数场景将数组折叠为对象；该问题已存在于源头提交 `21f6f64`，并在 `73cc5b0` 保留。

### 4. 对照验证

- 初始契约基线提交 `1a2aff8`（45 paths）中，`parameters` 均为数组，无此问题 → 该缺陷非历史遗留，而是 G1-03 快照刷新环节引入。
- 后端权威源 `G:/Dev/backend/Club/CoderClub/docs/api/coderclub-openapi.json` 中，同一 8 个操作的 `parameters` 均为数组 → 缺陷来源在快照生成，不在后端源。
- 只读实验：将快照中 8 处对象包回数组后，`api:check` 可正常解析，并检测到预期差异（4 个旧 POST 移除、正式端点变化）。

## 三、与 sync-manifest 声明的矛盾

`status/sync-manifest.json` 的 `contractSnapshot.semanticDifferenceSummary` 声明：

> "Only password and Token example values are redacted; no path, method, field, schema, or security structure differences."

实际快照存在上述 **8 处 `parameters` 数组→对象的结构差异**，与声明"无 Schema 结构差异"不符。此矛盾也需 PM 在复核时确认快照 SHA 与内容的一致性。

## 四、建议处理

1. **PM 复核确认**后，由 PM 或其授权方重新生成快照，确保所有 `operation.parameters` 保持为数组（OpenAPI 3.0.3 规范要求），重新计算 SHA-256 并更新 `status/sync-manifest.json` 的 `snapshotSha256`。
2. 快照修复提交后，Claude Code 前端以修复后的快照为输入，运行 `npm run api:check -- --update-baseline` 更新前端基线，再运行 `npm test`，补齐 G1-03 关闭条件。

## 五、前端声明

Claude Code 前端按角色边界**未修改**交接仓库 `api/coderclub-openapi.json`、`status/sync-manifest.json` 及任何权威文件；仅提出本提案，等待 PM 复核与处理。

- 提案角色：Claude Code 前端
- 日期：2026-08-11
- 状态：待 PM 复核
