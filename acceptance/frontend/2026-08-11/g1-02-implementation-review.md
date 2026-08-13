# G1-02 前端实现审核报告

> **审核角色：** Frontend Codex
>
> **审核日期：** 2026-08-11
>
> **实现提交：** `f76e6513164345250aca6b8d1e69984c5736059a`
>
> **审核基线：** `cb62823f5944d4f544a3f11da8685900a5d8cfb4`
>
> **交接主线：** `fa2a981`（包含本次执行报告）

## 发现

### [P1] 执行报告中的 lint 通过结论无法复现

执行报告第 3 节声明 `npm run lint` 为 0 错误，但本次以不修改文件的命令 `npm run lint -- --fix=false` 重跑，退出码为 1，发现：

- `env.d.ts:3`：解析错误 `Unexpected token module`。
- `tailwind.config.ts:1`：解析错误 `Unexpected token {`。
- `src/api/subject-mock.ts:62`：既有未使用变量 warning。

这些文件不在 `f76e651` 的修改范围内，不能归因于 G1-02 实现；但 PM 不应直接采信「lint 通过」这一执行报告结论，需另行确认基础 ESLint 配置或记录环境差异。

### [P2] 拦截器测试文件违反前端测试目录约定

`scripts/response-interceptor.test.mjs:4` 将前端业务拦截器测试放在 `scripts/`，而 [AGENTS.md](G:/Dev/backend/Club/CoderClubFront/AGENTS.md) 规定 `scripts/` 用于 API 契约测试，前端测试应放在 `src/__tests__/` 或实现文件旁并使用 `*.test.ts`。当前测试可以运行，但测试边界、TypeScript 检查和后续维护约定不一致。建议后续移至 [src/api/response-interceptor.test.ts](G:/Dev/backend/Club/CoderClubFront/src/api/response-interceptor.test.ts)，同步调整 `package.json` 的测试入口。

### [P3] 业务码与 HTTP 状态的认证分支存在重复

`response-interceptor.ts:16` 和 `response-interceptor.ts:41` 分别处理业务/HTTP 401，403 也有同样重复。当前行为一致，未形成已证实的功能缺陷；后续修改提示或登出策略时可能出现分支漂移，建议提取共享认证错误处理函数。

## 规范

规范轴发现 2 项：1 项执行证据问题（P1），1 项仓库测试布局硬性偏差（P2），以及 1 项可维护性建议（P3）。实现代码的命名、导入、格式和提交信息符合现有约定；没有发现越界修改 API 契约、状态清单或其他项目文件。

## 规格

规格轴未发现缺失需求、范围蔓延或已实现但行为错误的项目。`f76e651` 按 G1-02 方案实现了：

- 业务 `code === 401` 清除 Token、跳转 `/login`、提示登录过期并拒绝请求。
- 业务 `code === 403` 提示无权限，不清除 Token，不跳转并拒绝请求。
- HTTP 401/403 和普通错误保留原有行为。
- 成功响应继续返回 `response.data`，API 契约文件未变化。

## 独立验证

执行环境为 Node `v22.14.0`、npm `10.9.2`。

| 命令 | 结果 |
| --- | --- |
| `npm test` | 通过：10/10，0 失败、0 跳过 |
| `npm run api:check` | 通过：47 个操作，无 API 契约变化；源 SHA-256 为 `44cbe709...e265a` |
| `npm run build` | 通过：`vue-tsc --noEmit` 和 Vite 构建均退出 0；保留既有依赖注释和 chunk 大小 warning |
| `npm run lint -- --fix=false` | 失败：2 个解析错误、1 个既有 warning，详见本报告 P1 |
| `git diff cb62823f...f76e651 --check` | 通过 |

业务仓库 `G:/Dev/backend/Club/CoderClubFront` 在审核后保持干净。交接仓库本地 `main` 和角色 worktree 已同步到 `fa2a981`，角色 worktree 包含 `main`；同步及审核开始前工作区干净，当前仅有本报告尚未提交。本报告未修改 `status/sync-manifest.json`。

## 审核结论

G1-02 的目标行为和回归测试通过，未发现规格实现缺陷。建议 PM 将功能判定为「实现通过、质量门禁待处理」：先澄清 lint 执行报告与当前结果的差异，并安排测试文件按前端仓库约定迁移；完成后再关闭 G1-02 的全部审核遗留项。
