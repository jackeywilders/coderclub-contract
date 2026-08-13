# G1-02 前端业务 401/403 处理执行方案

> **执行角色：** Claude Code（前端业务仓库编码）
>
> **复验角色：** Frontend Codex（前端设计与验收）
>
> **适用基线：** PM 验收记录 `pm/reviews/2026-08-10/gate-0-1-pm-acceptance.md`

## 1. 目标与边界

在 `G:\Dev\backend\Club\CoderClubFront` 中修复 Axios 响应拦截器对业务响应体 `code=401/403` 的处理，并补充可重复运行的拦截器运行时测试。

必须实现以下行为：

- 业务 `code === 401`：调用 `removeToken()` 清除 `coderclub_token`，跳转 `/login`，提示「登录已过期，请重新登录」，并拒绝当前请求。
- 业务 `code === 403`：提示「无权限访问」，保持 Token 和当前路由不变，并拒绝当前请求。
- HTTP 状态 401/403：保留当前已有行为；普通网络错误和其他业务错误继续走原有通用提示。
- 成功响应仍返回 `response.data`，不得改变现有 API 调用方的数据访问方式。

本任务不修改 OpenAPI 文件、Store、路由表、页面、后端项目、交接仓库 `api/` 或 `status/sync-manifest.json`，也不处理 POST 兼容端点和分页问题。

## 2. 实现方案

将副作用与判断逻辑分离，便于 Node 内置测试直接验证：

1. 新建 `src/api/response-interceptor.ts`，导出响应成功处理函数和响应失败处理函数。函数接收 `clearToken`、`redirectToLogin`、`showError` 等依赖，业务代码通过 `removeToken`、`router.push('/login')` 和 `ElMessage.error` 注入实际实现。
2. 在业务 `code` 判断中先处理 401/403，再处理 `!success` 的通用错误；业务错误统一返回 `Promise.reject(new Error(message))`。
3. `src/api/index.ts` 只负责创建 Axios 实例、注入请求 Token，并注册上述处理函数，不在拦截器中复制认证错误分支。
4. 不修改 `API.Response` 的字段定义；`code` 按现有 `src/types/api.d.ts` 的 `number` 类型比较。

## 3. Claude Code 执行步骤

### 任务 1：先写运行时回归测试

**文件：**

- 创建：`scripts/response-interceptor.test.mjs`
- 修改：`package.json` 的 `test` 脚本

在测试中用 `node:assert/strict` 和 `node:test` 导入 `src/api/response-interceptor.ts`，为每个测试注入记录调用次数的假依赖。至少覆盖：成功响应返回体、业务 401 清 Token 并跳转、业务 403 不清 Token 不跳转、HTTP 401、HTTP 403、普通错误。对错误分支使用 `assert.rejects`，断言提示内容、清理次数和跳转次数。

将 `test` 脚本改为：

```json
"test": "node --experimental-strip-types --test scripts/check-api-spec.test.mjs scripts/response-interceptor.test.mjs"
```

运行：

```powershell
cd G:\Dev\backend\Club\CoderClubFront
npm test
```

预期：新测试在实现前失败，失败原因必须指向缺少 `src/api/response-interceptor.ts` 或对应行为；不得用跳过测试掩盖失败。

### 任务 2：实现最小修复

**文件：**

- 创建：`src/api/response-interceptor.ts`
- 修改：`src/api/index.ts`

让 `index.ts` 注入以下真实依赖：`removeToken`、`() => void router.push('/login')`、`ElMessage.error`。业务 401 必须走与 HTTP 401 相同的清理和登录跳转流程；业务 403 只能提示，不能调用清理或跳转。保留所有非目标行为，并确保响应 Promise 的成功值仍是 `res`。

运行：

```powershell
npm test
npm run api:check
npm run lint
npm run build
```

预期：测试 0 失败；API 检查显示 `No API contract changes detected`；Lint 和构建退出码为 0。Lint 若自动格式化文件，必须检查格式化后的差异仍只属于本任务。

### 任务 3：提交与交接

执行：

```powershell
git diff --check
git status --short
git add src/api/index.ts src/api/response-interceptor.ts scripts/response-interceptor.test.mjs package.json package-lock.json
git commit -m "fix(api): handle business auth error codes"
```

提交说明必须包含：实现提交完整哈希、修改文件、`npm test`、`npm run api:check`、`npm run lint`、`npm run build` 的实际结果，以及业务 401/403 的复现与验证结论。不要推送，不要合并 Pull Request。

## 4. Frontend Codex 复验清单

收到 Claude Code 提交后，Frontend Codex 在前端业务仓库执行 `git show <commit>` 和 `git diff <parent>..<commit>`，确认没有越界修改，然后运行四条验证命令。重点复验：业务 401 清除 `coderclub_token` 并跳转登录；业务 403 保持 Token 和路由；HTTP 401/403 的原有行为未回归；普通成功响应和普通失败响应的数据返回方式未改变。复验结果写入新的 `acceptance/frontend/` 记录，只有四项命令和上述行为均有证据后才可将 G1-02 标记为通过。

## 5. 完成条件

Claude Code 的实现提交可被独立检出，运行时测试覆盖业务和 HTTP 两类 401/403，四条验证命令均成功，且没有修改 API 契约、发布状态或其他项目文件。任何测试失败、路由跳转失败或 Token 未清理，都保持 G1-02 未通过并在交接回执中记录实际错误。
