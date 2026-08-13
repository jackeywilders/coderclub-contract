# G1-02 Review 整改实施计划

> **面向 AI 代理的工作者：** 必须按任务顺序执行，并在提交前运行全部验证命令。不得修改后端项目、OpenAPI 文件、交接仓库 `api/` 或 `status/sync-manifest.json`。

**目标：** 解决 G1-02 审核发现的 lint 门禁失败、测试文件位置不符合约定和 401/403 分支重复问题，保持已通过的认证错误行为不变。

**架构：** 保留 `src/api/index.ts` 的 Axios 实例职责，将认证错误副作用集中到 `response-interceptor.ts` 的共享函数。测试放在实现旁的 `src/api/response-interceptor.test.ts`，使用现有 Node 内置测试运行器和 TypeScript 类型剥离。

**技术栈：** Vue 3、TypeScript、Axios、Node `node:test`、ESLint、Vite。

---

## 审核依据与范围

- 实现提交：`f76e6513164345250aca6b8d1e69984c5736059a`
- 审核基线：`cb62823f5944d4f544a3f11da8685900a5d8cfb4`
- 审核报告：[acceptance/frontend/2026-08-11/g1-02-implementation-review.md](../acceptance/frontend/2026-08-11/g1-02-implementation-review.md)
- 只处理审核报告中的 P1、P2、P3；不重新设计 API 错误语义。

## 文件变更清单

**前端业务仓库 `G:\Dev\backend\Club\CoderClubFront`：**

- 修改：`eslint.config.js`，让 ESLint 用 TypeScript parser 解析根目录 `.ts` 配置文件和 `env.d.ts`。
- 修改：`src/api/subject-mock.ts`，删除没有任何读取点的 `nextLabelId` 变量。
- 修改：`src/api/response-interceptor.ts`，提取共享认证错误处理函数并补充明确返回类型。
- 创建：`src/api/response-interceptor.test.ts`，承接现有 8 个运行时回归测试。
- 删除：`scripts/response-interceptor.test.mjs`，避免同一测试保留两份。
- 修改：`package.json`、`package-lock.json`，加入 Node 类型声明并更新测试入口。

**前端交接 worktree：**

- 创建：`handoff/frontend-to-backend/2026-08-11/g1-02-review-remediation-report.md`，记录整改提交、实际命令输出和剩余问题。

不要修改当前 Frontend Codex 的审核报告；该报告仍由 Frontend Codex 保留并由用户决定是否提交。

## 任务 1：修复 ESLint 基线

### 步骤 1：复现失败

- [ ] 在前端业务仓库运行：

```powershell
cd G:\Dev\backend\Club\CoderClubFront
npm run lint -- --fix=false
```

- [ ] 记录当前错误：`env.d.ts:3` 和 `tailwind.config.ts:1` 的 TypeScript 解析错误，以及 `src/api/subject-mock.ts:62` 的 `nextLabelId` 未使用 warning。

### 步骤 2：扩大 TypeScript lint 匹配范围

- [ ] 修改 `eslint.config.js` 中 TypeScript 配置的 `files`，从只匹配 `src/**/*.ts` 改为匹配仓库内 TypeScript 文件：

```js
files: ['**/*.ts', '**/*.tsx'],
```

保持现有 `tsParser`、`tsPlugin`、Prettier 配置和 `dist/**`、`node_modules/**` 忽略规则不变。这样 `env.d.ts`、`tailwind.config.ts` 和 `vite.config.ts` 使用同一 TypeScript parser；不要把它们加入忽略列表来隐藏解析错误。

### 步骤 3：删除已确认无用的变量

- [ ] 删除 `src/api/subject-mock.ts` 中的 `let nextLabelId = 100`。先用 `rg -n "nextLabelId" src` 确认只有声明、没有调用方；不要改动 mock 数据和 `nextSubjectId`。

### 步骤 4：验证 lint

- [ ] 运行 `npm run lint -- --fix=false`，预期退出码为 0 且没有 error 或 warning。
- [ ] 再运行 `npm run lint`，检查自动格式化后的 `git diff` 只包含本整改允许的文件。

## 任务 2：迁移前端拦截器测试

### 步骤 1：迁移测试文件

- [ ] 将 `scripts/response-interceptor.test.mjs` 内容迁移为 `src/api/response-interceptor.test.ts`，保留 8 个测试和原有断言，不降低业务/HTTP 401/403 覆盖范围。
- [ ] 将 `package.json` 的 `test` 脚本改为：

```json
"test": "node --experimental-strip-types --test scripts/check-api-spec.test.mjs src/api/response-interceptor.test.ts"
```

- [ ] 执行 `npm install --save-dev @types/node`，让 TypeScript 测试文件可以类型检查 `node:assert/strict` 和 `node:test`；提交 `package-lock.json` 的必需变化。
- [ ] 删除旧的 `scripts/response-interceptor.test.mjs`，确保测试只存在于 `src/api/` 一份。

### 步骤 2：运行测试确认迁移没有回归

- [ ] 运行：

```powershell
npm test
```

- [ ] 预期仍为 10/10 通过，包含 2 个 API 契约测试和 8 个拦截器测试；不能通过跳过或缩减测试数量得到通过结果。

## 任务 3：合并认证错误处理分支

### 步骤 1：提取共享函数

- [ ] 在 `src/api/response-interceptor.ts` 中增加一个只负责认证错误副作用的函数，使用以下接口语义：

```ts
function applyAuthError(
  code: number | undefined,
  deps: ResponseInterceptorDeps,
): string | undefined {
  if (code !== 401 && code !== 403) return undefined

  const message = code === 401 ? AUTH_EXPIRED_MESSAGE : NO_PERMISSION_MESSAGE
  if (code === 401) {
    deps.clearToken()
    deps.redirectToLogin()
  }
  deps.showError(message)
  return message
}
```

- [ ] `handleResponseSuccess` 先调用 `applyAuthError(res.code, deps)`；返回消息时拒绝请求，否则继续处理 `!res.success` 和成功返回。返回类型写为 `API.Response | Promise<never>`，不要使用新的 `any`。
- [ ] `handleResponseError` 先调用 `applyAuthError(error.response?.status, deps)`；认证错误直接拒绝原始 Axios 错误，其他错误继续提示 `error.message || '网络错误'` 并拒绝原始错误。
- [ ] `src/api/index.ts` 继续只负责 Axios 实例和依赖注入；保留 `removeToken`、`router.push('/login')`、`ElMessage.error` 的现有注入方式。

### 步骤 2：验证行为不变

- [ ] 运行 `npm test`，确认业务 401 仍清 Token 并跳转，业务 403 仍不清 Token、不跳转，HTTP 401/403 和普通错误行为不变。
- [ ] 运行 `npm run api:check`，预期输出 `No API contract changes detected`。

## 任务 4：完整验证与交接

- [ ] 在前端业务仓库运行：

```powershell
git diff --check
npm test
npm run api:check
npm run lint -- --fix=false
npm run build
```

- [ ] 预期全部退出码为 0；构建允许保留既有依赖 chunk 大小 warning，但不允许有 TypeScript 或 ESLint error。
- [ ] 用 `git diff --name-status cb62823f5944d4f544a3f11da8685900a5d8cfb4..HEAD` 核对修改范围只包含本方案列出的业务文件。
- [ ] 更新或创建 `handoff/frontend-to-backend/2026-08-11/g1-02-review-remediation-report.md`，记录完整实现提交哈希、测试数量、每条命令的真实退出结果、lint 基线修复内容和已知 warning；禁止沿用之前无法复现的「lint 通过」表述。
- [ ] 提交信息使用：

```powershell
git add eslint.config.js src/api/subject-mock.ts src/api/response-interceptor.ts src/api/response-interceptor.test.ts package.json package-lock.json
git commit -m "fix(api): remediate G1-02 review findings"
```

- [ ] 不直接推送 `main`，不修改 API 契约和发布状态；提交哈希交给 Frontend Codex 复验，远程推送按用户单独授权执行。

## 完成判定

整改只有在 ESLint 无 error/warning、10 个测试全部通过、API 检查无差异、构建成功、测试文件已迁移、认证分支已合并且交接报告记录真实结果后，才可申请 Frontend Codex 复验并关闭 G1-02 的质量门禁。
