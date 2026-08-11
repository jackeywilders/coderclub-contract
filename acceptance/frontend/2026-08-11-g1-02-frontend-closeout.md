# G1-02 前端收口验收记录

> **验收角色：** Frontend Codex
> **验收日期：** 2026-08-11
> **任务来源：** `pm/requirements/2026-08-11/g1-02-frontend-closeout.md`
> **交接仓库基线：** `origin/main@d627c3e`

## 1. 验收结论

**G1-02 前端实现、整改和远程发布证据已完成核验，前端状态回写为 `accepted`。** 本次只补充交接证据和状态，不修改前端业务代码、后端项目、API 快照或 `status/sync-manifest.json`。

## 2. 提交链核对

| 用途 | 完整提交哈希 | 父提交 |
| --- | --- | --- |
| G1-02 原始实现 | `f76e6513164345250aca6b8d1e69984c5736059a` | `cb62823f5944d4f544a3f11da8685900a5d8cfb4` |
| G1-02 整改 | `386dd53b936cd3b06ec8a3e29a13989ff15a6463` | `f76e6513164345250aca6b8d1e69984c5736059a` |
| 原始执行报告对应的 `fa2a981` | `9fa3223fedbae32bc87958d94ff408f193c73244` | 以交接仓库提交记录为准 |

任务单要求的只读命令已核对：

```powershell
git show 386dd53b936cd3b06ec8a3e29a13989ff15a6463
git diff cb62823f5944d4f544a3f11da8685900a5d8cfb4..386dd53b936cd3b06ec8a3e29a13989ff15a6463 --name-status
```

整改提交变更 8 个前端文件：`env.d.ts`、`eslint.config.js`、`package-lock.json`、`package.json`、`src/api/index.ts`、`src/api/response-interceptor.test.ts`、`src/api/response-interceptor.ts` 和 `src/api/subject-mock.ts`。测试文件由 `scripts/response-interceptor.test.mjs` 迁移至 `src/api/response-interceptor.test.ts`。未出现 OpenAPI、交接仓库 `api/` 或 `status/sync-manifest.json`。

## 3. Claude Code 远程发布核验

前端业务仓库远程为 `git@github.com:jackeywilders/CoderClubFront.git`。刷新远程引用后确认：

- 本地 `main` 保留整改提交 `386dd53b936cd3b06ec8a3e29a13989ff15a6463`。
- Claude Code 远程分支为 `origin/feat/frontend-history@85320f1cb371e2f13b4c7fadb4c96f75820920c3`。
- GitHub `origin/main@470da04f6b62acc5002ef16eb8f9348eb9589bed` 已包含 `85320f1`，对应 PR 合入结果。
- `386dd53` 与 `85320f1` 的内容树完全一致，但提交对象不同；因此记录为「远程同树提交已合入」，不把远程主线写成包含本地 `386dd53` 对象。
- 前端工作区 `feat/frontend-history` 与 `origin/feat/frontend-history` 同步且干净。

该远程发布由 Claude Code 前端角色完成。Frontend Codex 未推送前端 `main`，也未修改前端业务仓库。

## 4. 验证证据与边界

既有整改复核报告 `acceptance/frontend/2026-08-11-g1-02-remediation-review.md` 记录：

- 等价 Node 验证下 `npm test` 为 10/10 通过，0 失败、0 跳过。
- 等价 API 检查通过，47 个操作，无 API 契约变化，源 SHA-256 为 `44cbe709887e840174d1bdd02f32a423561013e0622b81e76c9346d2e87e265a`。
- 等价 ESLint、类型检查和 Vite 构建通过；既有依赖注释和 chunk 大小 warning 不阻断本次整改。
- `src/api/index.ts` 的 Axios 返回类型双重断言为 P3 后续技术债，不阻断 G1-02。

本次收口不重新声明未实际取得的日志或版本：

- G1-02 整改复核中的测试、API 检查、lint 和构建结果来自既有复核报告。
- G1-05 的临时 PATH 验证结果来自 Frontend Codex 报告；用户随后在本机 CMD 确认默认 `node` 和 `npm` 入口，PM 已在 `pm/reviews/2026-08-11-g1-05-pm-closure.md` 正式关闭该门禁。
- 用户本机 CMD 的确认未由本次受限 Codex 终端重新取得，因此本记录不补写用户未提供的具体版本、输出或日志。

## 5. 工作树与写入边界

收口编辑前，交接角色 worktree 工作树干净，`git diff --check` 通过。收口编辑后再次核对：`status/frontend.json` 可解析为有效 JSON，`git diff --check` 通过，`git status --short` 仅显示 `M status/frontend.json` 和新增的本记录文件。收口变更只包含本记录和 `status/frontend.json`。

本次明确未修改：

- `G:/Dev/backend/Club/CoderClubFront/src/` 及前端业务代码仓库其他文件；
- 后端项目；
- 交接仓库 `api/coderclub-openapi.json`；
- `status/sync-manifest.json`；
- 发布状态或前端 `main`。
