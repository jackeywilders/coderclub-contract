# G1-03 前端消费验证回执

> 回执角色：Claude Code 前端
>
> 复核角色：Frontend Codex（前端设计与验收）
>
> 执行日期：2026-08-11
>
> 验收边界：补齐 PM 验收文件 `pm/reviews/2026-08-11/g1-03-backend-task-acceptance.md` 中 G1-03 关闭条件的最后一项——以修复后快照为输入更新前端 API 基线，并完成消费验证。

## 1. 来源与提交

| 项目 | 值 |
| --- | --- |
| 前端项目 | `G:/Dev/backend/Club/CoderClubFront` |
| 前端分支 | `main` |
| 前端基线提交（待补） | 本回执对应的基线更新提交（见第 5 节） |
| 快照来源 | 交接仓库 `api/coderclub-openapi.json`（PM 修复后） |
| 快照提交 | `99367ea81f17a39874f7516ea919298b323c594e` |
| 快照 SHA-256（LF，PM 声明） | `9a97c055186883adb6c45304f66417c27c4da7b632375cd70a02c44a652db26a` |
| 快照 SHA-256（磁盘 CRLF，前端基线记录） | `414211bfa997081c9a07049d2d6da7a048591d054a068cd87f96390ba7a4a8e8` |
| OpenAPI / 路径 / 操作 | `3.0.3 / 43 / 43` |

## 2. 快照结构缺陷复核结论

前端在上一轮发现 PM 快照 `21f6f64`、`73cc5b0` 中 8 个操作的 `parameters` 被序列化为对象而非数组，导致 `npm run api:check` 报 `(operation.parameters ?? []) is not iterable`。该问题已记录于 `proposals/frontend/2026-08-11/g1-03-snapshot-parameters-structure-defect.md`。

PM 已在 `99367ea` 基于后端源完整重建快照。前端复核确认修复后的快照：

- `parameters` 均为数组，**0 处非数组参数**（结构扫描通过）。
- 43 paths / 43 operations，与后端源一致。
- 四个旧 POST（`POST /subject/category/update`、`POST /subject/category/delete`、`POST /subject/label/update`、`POST /subject/label/delete`）均不存在。
- 四个正式 PUT/DELETE 均存在。

## 3. 前端基线更新

前端 API 基线文件 `docs/frontend/handoff/api-docs-baseline.json` 由 `44cbe709887e840174d1bdd02f32a423561013e0622b81e76c9346d2e87e265a`（47 endpoints，旧含四个 POST）更新为：

| 检查项 | 结果 |
| --- | --- |
| 新基线 specSha256 | `414211bfa997081c9a07049d2d6da7a048591d054a068cd87f96390ba7a4a8e8` |
| endpointCount | `43` |
| 四个旧 POST | 基线中**不存在**（0 次匹配） |
| 正式 `PUT /subject/category/update` | 存在 |
| 正式 `DELETE /subject/category/delete/{id}` | 存在 |
| 正式 `PUT /subject/label/update` | 存在 |
| 正式 `DELETE /subject/label/delete/{id}` | 存在 |

前端 `src/api/subject.ts` 已使用正式方法：

- `updateCategory` → `PUT /subject/category/update`
- `updateLabel` → `PUT /subject/label/update`
- `removeSubject` → `DELETE /subject/remove/{id}`

## 4. 验证结果

执行环境：Node `v22.14.0`，npm `10.9.2`。

| 命令 | 结果 |
| --- | --- |
| `npm run api:check`（更新基线前） | 预期退出码 1：仅报告四个旧 POST 移除，无其他差异 |
| `npm run api:check -- --update-baseline` | 通过：基线更新为 43 endpoints |
| `npm run api:check`（更新基线后） | 通过：`No API contract changes detected`，43 endpoints，SHA-256 `414211bf…` |
| `npm test` | 通过：10/10，0 失败、0 跳过 |
| `npm run lint -- --fix=false` | 通过：退出码 0 |
| `npm run build` | 通过：`vue-tsc --noEmit` + `vite build` 均退出 0（chunk 大小 warning 为既有依赖） |
| `git diff --check` | 通过 |

### 基线更新前 `api:check` 检测到的唯一差异

```
- POST /subject/category/delete
- POST /subject/category/update
- POST /subject/label/delete
- POST /subject/label/update
```

与 PM 验收文件预期完全一致，无其他路径、方法、字段或结构差异。

## 5. 变更范围与提交

本次前端基线更新只修改 1 个文件：`docs/frontend/handoff/api-docs-baseline.json`（3 insertions / 173 deletions，47→43 endpoints 的合理变化）。

- `local/api-docs-path.txt` 已指向交接仓库修复后快照 `G:/Dev/backend/Club/coderclub-contract/api/coderclub-openapi.json`（该文件在 `.gitignore` 中，不提交）。
- 未修改 `src/` 源代码、`package.json`、OpenAPI 文件、`status/sync-manifest.json`。

基线更新提交由 Claude Code 前端在待用户审核确认后提交并报告完整提交哈希。

## 6. 已知限制

1. 前端基线记录的 SHA 为磁盘 CRLF 形式（`414211bf…`），PM 声明的快照 SHA 为 LF 形式（`9a97c055…`），两者内容一致，差异由 `core.autocrlf=true` 换行转换导致；`npm run api:check` 直接读取磁盘文件，因此基线以磁盘 SHA 为准。
2. 本次为消费验证与基线更新，不是对真实后端服务的端到端 HTTP 联调；正式联调前仍需按环境验证网关路由。
3. G1-03 前端关闭条件已具备，但不代表 Gate 1 整体关闭；`releaseStatus` 与 `finalReleaseStatus` 保持 `not-published`，由 PM 控制。

## 7. 声明

Claude Code 前端按角色边界完成 G1-03 关闭条件的最后一项：以 PM 修复后快照为输入更新前端 API 基线并完成消费验证。未修改交接仓库权威文件、`status/sync-manifest.json` 或后端项目。

- 回执角色：Claude Code 前端
- 日期：2026-08-11
- 状态：待用户审核确认后提交
