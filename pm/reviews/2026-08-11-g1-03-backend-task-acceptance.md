# G1-03 后端任务 PM 验收

> **验收角色：** PM / 跨项目协调 Codex
>
> **验收日期：** 2026-08-11
>
> **验收结论：** 后端任务通过；G1-03 保持部分通过，尚不关闭

## 验收来源

| 项目 | 值 |
| --- | --- |
| 交接仓库主线 | `origin/main@b3d9fbebb29f8ce79fab44bfcee097a43803239a` |
| 后端实现提交 | `6c1a95bb679b65191488531537b79aa6948a4399` |
| 后端实现父提交 | `7c82cbec5433a2e7aa44582e3c0ddba459c4c886` |
| 后端回执 | `handoff/backend-to-frontend/2026-08-11-g1-03-claude-code-backend-execution-report.md` |
| 批准任务 | `pm/requirements/2026-08-11-g1-03-claude-code-backend-execution-task.md` |

## 后端验收结果

| 验收项 | 结果 | 证据 |
| --- | --- | --- |
| 变更范围 | 通过 | 仅修改批准的两个 Controller、`SubjectContractTest` 和后端运行时 OpenAPI 源 |
| 四个旧 POST | 通过 | 分类/标签更新、删除的旧 POST 映射和两个无参数删除路径均已移除 |
| 四个正式端点 | 通过 | 两个 PUT 更新和两个 DELETE `/{id}` 仍存在，保留登录校验、更新校验、JSON body 与路径参数语义 |
| Controller 契约测试 | 通过 | 指定 Maven 命令本地复验：45 tests，0 failures，0 errors，`BUILD SUCCESS` |
| 运行时 OpenAPI | 通过 | `openapi=3.0.3`，43 paths，43 operations，SHA-256 `cf6998f73480cd27f23fcacbc7b662f49ce33d281da82a855e4d0ea5172852f6` |
| 提交审查 | 通过 | 规范与规格双轴审查均无发现；`git show --check 6c1a95b` 通过 |

旧 POST 断言使用与真实三个 Controller 相同的 MockMvc 配置，并在登录态下要求 4xx；不会因未装配目标 Controller 而产生虚假的通过结果。

## G1-03 关闭条件复核

G1-03 的后端证据已满足，但全量关闭条件尚缺两项：

1. 前端 API 基线仍记录四个旧 POST。直接运行前端 API 检查脚本已检测到四个已移除端点，并以退出码 1 结束；`src/api/subject.ts` 已使用正式 PUT/DELETE，下一步由 Claude Code 前端更新基线并运行 `npm run api:check`、`npm test`。
2. PM 开发快照 `api/coderclub-openapi.json` 仍为 45 paths / 47 operations，且 `status/sync-manifest.json` 仍引用旧后端提交与 SHA-256。待前端回执完成后，PM 才能生成新快照、更新同步清单并进行最终结构化比对。

因此，本次仅关闭 `G1-03-CLAUDE-CODE-IMPLEMENTATION` 后端执行待办，不关闭 G1-03 总项，也不改变 `releaseStatus` 或 `finalReleaseStatus`。
