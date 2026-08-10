# G1-02 前端业务 401/403 处理执行报告

> **执行角色：** Claude Code（前端业务仓库编码）
> **复验角色：** Frontend Codex（前端设计与验收）
> **日期：** 2026-08-11
> **执行方案：** [2026-08-11-g1-02-claude-code-execution-plan.md](../designs/frontend/2026-08-11-g1-02-claude-code-execution-plan.md)
> **适用基线：** PM 验收记录 `pm/reviews/2026-08-10-gate-0-1-pm-acceptance.md`

---

## 1. 实现提交

| 项目 | 值 |
| --- | --- |
| 业务仓库 | `G:/Dev/backend/Club/CoderClubFront` |
| 分支 | `main` |
| **实现提交（完整）** | `f76e6513164345250aca6b8d1e69984c5736059a` |
| 实现提交（短） | `f76e651` |
| 父提交 | `cb62823f5944d4f544a3f11da8685900a5d8cfb4`（前端规则建立基线） |
| 提交信息 | `fix(api): handle business auth error codes` |
| 工作区状态 | 干净，无未提交变更 |

## 2. 修改文件

| 文件 | 操作 | 变更 |
| --- | --- | --- |
| `src/api/response-interceptor.ts` | 新增 | 52 行：导出 `handleResponseSuccess` / `handleResponseError`，副作用与判断逻辑分离，通过 `ResponseInterceptorDeps` 注入 `clearToken` / `redirectToLogin` / `showError` |
| `src/api/index.ts` | 修改 | 32 行：只保留创建 Axios 实例、请求 Token 注入和注册处理函数，注入 `removeToken`、`() => router.push('/login')`、`ElMessage.error` |
| `scripts/response-interceptor.test.mjs` | 新增 | 101 行：8 个运行时回归测试，注入计数假依赖 |
| `package.json` | 修改 | `test` 脚本改为 `node --experimental-strip-types --test scripts/check-api-spec.test.mjs scripts/response-interceptor.test.mjs` |

总计：4 个文件，+167 / −20。未修改 `src/types/api.d.ts`（`API.Response.code` 仍为 `number`），未修改其他源文件。

## 3. 验证结果

执行环境：Node `v22.14.0`，npm `10.9.2`。

| 命令 | 结果 |
| --- | --- |
| `npm test` | ✅ **10/10 通过**（8 个新增拦截器测试 + 2 个既有 API 契约测试），0 失败，0 跳过 |
| `npm run api:check` | ✅ `No API contract changes detected`；OpenAPI 3.0.3，47 个操作，SHA-256 `44cbe709887e840174d1bdd02f32a423561013e0622b81e76c9346d2e87e265a` |
| `npm run lint` | ✅ 0 错误（1 个既有 warning 在 `src/api/subject-mock.ts`，非本次改动；`--fix` 已运行，改动范围仍只含本任务 4 个文件） |
| `npm run build` | ✅ `vue-tsc --noEmit` + `vite build` 均通过（element-plus chunk 大小警告为既有，非本次改动） |

### TDD 过程

1. **先写测试**：创建 `scripts/response-interceptor.test.mjs` 并更新 `package.json` 的 `test` 脚本。
2. **红灯**：实现前运行 `npm test`，测试失败，错误为 `ERR_MODULE_NOT_FOUND`，指向缺少 `src/api/response-interceptor.ts`，失败原因与方案预期一致，未用跳过掩盖。
3. **绿灯**：实现 `src/api/response-interceptor.ts` 并重构 `src/api/index.ts` 后，10/10 通过。

## 4. 行为验证结论

| 场景 | 期望行为 | 测试结果 |
| --- | --- | --- |
| 业务 `code === 401` | 清除 `coderclub_token` → 跳转 `/login` → 提示「登录已过期，请重新登录」→ 拒绝请求 | ✅ 测试「business code 401」通过，断言 `clearToken` 1 次、`redirectToLogin` 1 次、提示文案正确 |
| 业务 `code === 403` | 提示「无权限访问」→ **保持** Token 和当前路由 → 拒绝请求 | ✅ 测试「business code 403」通过，断言 `clearToken` 0 次、`redirectToLogin` 0 次 |
| HTTP 状态 401 | 保留原行为：清除 Token、跳转登录、提示过期 | ✅ 测试「HTTP 401」通过 |
| HTTP 状态 403 | 保留原行为：提示无权限，不清 Token 不跳转 | ✅ 测试「HTTP 403」通过 |
| 普通业务错误 | 通用错误提示 + `Promise.reject(new Error(message))` | ✅ 测试「business error with non-auth code」通过 |
| 普通网络错误 | `error.message` 或「网络错误」提示，不清理不跳转 | ✅ 测试「generic error」× 2 通过 |
| 成功响应 | 返回 `response.data`，调用方数据访问方式不变 | ✅ 测试「success response」通过，返回对象引用相等 |

业务 401 与 HTTP 401 走相同清理和登录跳转流程；业务 403 与 HTTP 403 均只提示不清 Token。响应成功值仍为 `res`（即 `response.data`）。

## 5. 未做事项（边界确认）

- 未修改 OpenAPI 文件、`API.Response` 字段定义。
- 未修改 Store、路由表、页面、后端项目。
- 未修改交接仓库 `api/` 或 `status/sync-manifest.json`。
- 未处理 POST 兼容端点和分页问题（不在 G1-02 范围）。
- 未推送、未合并 Pull Request。

## 6. Frontend Codex 复验指引

1. 在 `G:/Dev/backend/Club/CoderClubFront` 执行 `git show f76e6513164345250aca6b8d1e69984c5736059a` 确认提交存在。
2. 执行 `git diff cb62823f5944d4f544a3f11da8685900a5d8cfb4..f76e6513164345250aca6b8d1e69984c5736059a` 确认修改范围只含本任务 4 个文件。
3. 运行四条验证命令：`npm test`、`npm run api:check`、`npm run lint`、`npm run build`。
4. 重点复验：业务 401 清除 `coderclub_token` 并跳转登录；业务 403 保持 Token 和路由；HTTP 401/403 原有行为未回归；成功/普通失败响应的数据返回方式未改变。
5. 复验通过后，将结果写入 `acceptance/frontend/` 新记录并更新 `status/frontend.json`，标记 G1-02 通过。

## 7. 已知限制

- 运行时测试通过 Node `--experimental-strip-types` 直接导入 `.ts` 模块，该 flag 为实验特性（运行时打印 `ExperimentalWarning`），不影响功能。
- `FRONTEND-NODE-DEFAULT`（`nvm-desktop` 默认 Node 版本未配置）为环境问题，不在本任务范围；本机当前 PATH 中 Node `v22.14.0` 可正常执行全部命令。
- `HANDOFF-HASH-MISMATCH`（交接仓库 `api/` 副本 SHA 与 Backend 回执声明不一致）为 PM 协调项，与本任务无关，未处理。
