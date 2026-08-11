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

PM 已从后端运行时源 `6c1a95bb679b65191488531537b79aa6948a4399` 生成并提交开发契约快照：

| 检查项 | 结果 |
| --- | --- |
| 快照提交 | `21f6f64a87d2899c84385fe26e9bd93a72a958e0` |
| 源 SHA-256 | `cf6998f73480cd27f23fcacbc7b662f49ce33d281da82a855e4d0ea5172852f6` |
| 快照 SHA-256 | `007ca1ad399dd787572d60413f3a68f907b40afc9320c6564fbde1e27641aa46` |
| OpenAPI 结构 | `3.0.3`，43 paths，43 operations |
| 路径和方法集合 | 与后端源一致，无缺失或额外操作 |
| 结构化差异 | 恰 14 处，均为 password/Token 示例值脱敏；无路径、方法、字段、Schema 或安全结构差异 |

后端源的 `info.description` 仍描述为“45 个路径 47 个操作”，与文件实际结构的 43/43 不一致。该文本已按源文件原样保留在快照中；PM 未修改运行时源或引入额外语义差异。该后端文档元数据问题应在后续后端文档任务中修正。

## G1-03 关闭条件复核

G1-03 的后端证据和 PM 开发契约快照均已满足，但全量关闭条件尚缺一项：

1. 前端 API 基线仍记录四个旧 POST。直接运行前端 API 检查脚本已检测到四个已移除端点，并以退出码 1 结束；`src/api/subject.ts` 已使用正式 PUT/DELETE，下一步由 Claude Code 前端以本快照为输入更新基线并运行 `npm run api:check`、`npm test`。

因此，`G1-03-CLAUDE-CODE-IMPLEMENTATION` 与 `G1-03-PM-SNAPSHOT-SYNC` 已完成；在前端基线回执和消费验证完成前，不关闭 G1-03 总项，也不改变 `releaseStatus` 或 `finalReleaseStatus`。
