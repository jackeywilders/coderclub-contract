# G1-03 后端任务 PM 验收

> **验收角色：** PM / 跨项目协调 Codex
>
> **验收日期：** 2026-08-11
>
> **验收结论：** 后端任务通过，PM 开发契约快照已同步；G1-03 保持部分通过，尚不关闭

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

## PM 契约快照同步

PM 已从后端运行时源 `87d2b724f7981f4796b3f5ae71470fa18f393661` 生成并提交开发契约快照：

| 检查项 | 结果 |
| --- | --- |
| 快照提交 | `73cc5b00189ac9fd28d957c19d95c0005425f02d` |
| 源 SHA-256 | `7576e28a346dcf60b304bdd405f0bb82b72252df37e96013509ece00c6a14a2e` |
| 快照 SHA-256 | `5a8919e790cbaf02170cc5c3d93194925e92f9ab5641ea6efdb47ed6e6b3c1b4` |
| OpenAPI 结构 | `3.0.3`，43 paths，43 operations |
| 路径和方法集合 | 与后端源一致，无缺失或额外操作 |
| 结构化差异 | 恰 14 处，均为 password/Token 示例值脱敏；无路径、方法、字段、Schema 或安全结构差异 |

后端已在提交 `87d2b72` 中将 `info.description` 的统计修正为“43 个路径 43 个操作”。快照已同步该文本；PM 未引入额外语义差异。

## G1-03 关闭条件复核

G1-03 的后端证据和 PM 开发契约快照均已满足，但全量关闭条件尚缺一项：

1. 前端 API 基线仍记录四个旧 POST。直接运行前端 API 检查脚本已检测到四个已移除端点，并以退出码 1 结束；`src/api/subject.ts` 已使用正式 PUT/DELETE，下一步由 Claude Code 前端以本快照为输入更新基线并运行 `npm run api:check`、`npm test`。

因此，`G1-03-CLAUDE-CODE-IMPLEMENTATION` 与 `G1-03-PM-SNAPSHOT-SYNC` 已完成；在前端基线回执和消费验证完成前，不关闭 G1-03 总项，也不改变 `releaseStatus` 或 `finalReleaseStatus`。
