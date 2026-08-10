# G1-02 Review 整改报告

> **执行角色：** Claude Code（前端业务仓库编码）
> **复验角色：** Frontend Codex（前端设计与验收）
> **日期：** 2026-08-11
> **整改方案：** [2026-08-11-g1-02-review-remediation-plan.md](../designs/frontend/2026-08-11-g1-02-review-remediation-plan.md)
> **审核报告：** [2026-08-11-g1-02-implementation-review.md](../acceptance/frontend/2026-08-11-g1-02-implementation-review.md)

---

## 1. 整改提交

| 项目 | 值 |
| --- | --- |
| 业务仓库 | `G:/Dev/backend/Club/CoderClubFront` |
| 分支 | `main` |
| **整改提交（完整）** | `386dd53b936cd3b06ec8a3e29a13989ff15a6463` |
| 整改提交（短） | `386dd53` |
| 父提交 | `f76e6513164345250aca6b8d1e69984c5736059a`（G1-02 原始实现） |
| 审核基线 | `cb62823f5944d4f544a3f11da8685900a5d8cfb4` |
| 提交信息 | `fix(api): remediate G1-02 review findings` |
| 工作区状态 | 干净，无未提交变更 |

## 2. 修改文件

| 文件 | 操作 | 变更 |
| --- | --- | --- |
| `eslint.config.js` | 修改 | TS `files` 从 `src/**/*.ts` 扩为 `**/*.ts`、`**/*.tsx`，根目录 `.ts` 配置文件使用同一 TS parser |
| `env.d.ts` | 修改 | `DefineComponent<{}, {}, any>` → `DefineComponent<object, object, any>`，消除 `no-empty-object-type` 错误 |
| `src/api/subject-mock.ts` | 修改 | 删除无调用方的 `let nextLabelId = 100` |
| `src/api/response-interceptor.ts` | 修改 | 提取共享 `applyAuthError(code, deps)`，两个 handler 先调用它；`handleResponseSuccess` 返回类型改为 `API.Response \| Promise<never>`（不再用 `any`） |
| `src/api/response-interceptor.test.ts` | 新增（从 `scripts/response-interceptor.test.mjs` 迁移） | 保留 8 个测试与断言 |
| `scripts/response-interceptor.test.mjs` | 删除 | 测试唯一保留在 `src/api/` |
| `src/api/index.ts` | 修改 | 响应拦截器注册处加类型断言 `as unknown as AxiosResponse`（axios 拦截器回调类型约束，不改逻辑） |
| `package.json`、`package-lock.json` | 修改 | 新增 `@types/node`；`test` 脚本测试入口指向 `src/api/response-interceptor.test.ts` |

总计：8 个文件，+83 / −52（git 将删除+新增识别为 rename：`.mjs` → `.ts`）。

### 与方案文件清单的差异说明

方案清单未列出 `env.d.ts` 与 `src/api/index.ts`，实际均需修改：

- **`env.d.ts`**：扩大 lint 匹配范围后，`DefineComponent<{}, {}, any>` 触发 `no-empty-object-type` 推荐规则（2 处 error）。方案完成判定要求「ESLint 无 error/warning」且「不加入忽略列表隐藏」，因此按 ESLint 建议将空对象类型替换为 `object`（Vue shim 类型语义等价）。
- **`src/api/index.ts`**：方案任务 3 要求 `handleResponseSuccess` 返回 `API.Response | Promise<never>`（不用 `any`），而 axios 响应拦截器 `onFulfilled` 类型固定为 `AxiosResponse | Promise<AxiosResponse>` 且该版本 `use()` 不接受泛型参数，因此注册处需加 `as unknown as AxiosResponse` 断言；依赖注入方式未变。

## 3. 验证结果（整改提交后，全部真实执行）

执行环境：Node `v22.14.0`，npm `10.9.2`。

| 命令 | 结果 |
| --- | --- |
| `git diff --check` | ✅ 无空白错误 |
| `npm test` | ✅ 10/10 通过（2 个 API 契约测试 + 8 个拦截器测试），0 失败、0 跳过 |
| `npm run api:check` | ✅ `No API contract changes detected`；OpenAPI 3.0.3，47 个操作，SHA-256 `44cbe709887e840174d1bdd02f32a423561013e0622b81e76c9346d2e87e265a` |
| `npm run lint -- --fix=false` | ✅ 退出码 0，`No issues found`（无 error、无 warning） |
| `npm run build` | ✅ `vue-tsc --noEmit` + `vite build` 均退出 0（element-plus chunk 大小 warning 为既有依赖，非本次引入） |

### lint 基线修复内容

1. **解析错误根因**：`eslint.config.js` 的 TS `files` 仅匹配 `src/**/*.ts`，而 `package.json` 的 lint 脚本用 `--ext .ts` 枚举根目录 `.ts` 文件（`env.d.ts`、`tailwind.config.ts`、`vite.config.ts`），未匹配到 TS parser 的文件被默认 espree 解析，产生 `Unexpected token` 解析错误。
2. **修复**：`files` 扩为 `**/*.ts`、`**/*.tsx`，三个根目录文件均改用 `@typescript-eslint/parser`；`tailwind.config.ts`、`vite.config.ts` 解析通过（0 messages），`env.d.ts` 暴露并修复 2 处 `no-empty-object-type`。
3. **既有 warning**：删除 `subject-mock.ts` 中无读取点的 `nextLabelId`（先用 `rg -n "nextLabelId" src` 确认只有声明、无调用方；`nextSubjectId` 有使用，未动）。

### 任务 3 行为验证

`applyAuthError` 提取后行为未变（由 8 个测试覆盖）：

| 场景 | 断言 |
| --- | --- |
| 业务 `code === 401` | 清 Token 1 次、跳登录 1 次、提示「登录已过期，请重新登录」、拒绝 ✅ |
| 业务 `code === 403` | 清 Token 0 次、跳登录 0 次、提示「无权限访问」、拒绝 ✅ |
| HTTP 401 | 清 Token 1 次、跳登录 1 次、拒绝 ✅ |
| HTTP 403 | 清 Token 0 次、跳登录 0 次、拒绝 ✅ |
| 普通业务错误 / 网络错误 | 通用提示、不清理不跳转、拒绝 ✅ |
| 成功响应 | 返回 `response.data`，无副作用 ✅ |

## 4. 未做事项

- 未修改 OpenAPI 文件、`API.Response` 字段定义、Store、路由表、页面、后端项目。
- 未修改交接仓库 `api/` 或 `status/sync-manifest.json`。
- 未直接推送 `main`（当前提交保留在业务仓库本地，远程推送按用户单独授权执行）。

## 5. Frontend Codex 复验指引

1. 执行 `git show 386dd53b936cd3b06ec8a3e29a13989ff15a6463` 确认整改提交存在。
2. 执行 `git diff cb62823f5944d4f544a3f11da8685900a5d8cfb4..386dd53b936cd3b06ec8a3e29a13989ff15a6463` 核对修改范围（含原始实现与整改）。
3. 运行四条验证命令：`npm test`、`npm run api:check`、`npm run lint -- --fix=false`、`npm run build`。
4. 重点复验：lint 基线已无 error/warning；测试文件已迁移到 `src/api/` 实现旁；`applyAuthError` 合并后业务/HTTP 401/403 行为与 `f76e651` 一致；`handleResponseSuccess` 返回类型为 `API.Response | Promise<never>`。
5. 复验通过后，将结果写入 `acceptance/frontend/` 新记录并更新 `status/frontend.json`，关闭 G1-02 质量门禁。

## 6. 已知限制

- `@types/node` 安装使 `package.json` 的 dependencies/devDependencies 按 npm 自动排序（仅顺序变化 + 新增 `@types/node`），不改变任何已声明依赖版本。
- 运行时测试通过 Node `--experimental-strip-types` 直接导入 `.ts` 模块，该 flag 为实验特性（运行时打印 `ExperimentalWarning`），不影响功能。
- `FRONTEND-NODE-DEFAULT`（`nvm-desktop` 默认 Node 版本未配置）为环境问题，不在本任务范围。
