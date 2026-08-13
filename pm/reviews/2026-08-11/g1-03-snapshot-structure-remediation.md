# G1-03 开发契约快照结构复核与修复

> **复核角色：** PM / 跨项目协调 Codex
>
> **日期：** 2026-08-11
>
> **结论：** 前端提案成立，快照已修复；G1-03 仍等待前端消费验证

## 复核范围

- 前端提案：`proposals/frontend/2026-08-11/g1-03-snapshot-parameters-structure-defect.md`（由 Claude Code 前端工作区提出）
- 后端运行时源：`G:/Dev/backend/Club/CoderClub/docs/api/coderclub-openapi.json@87d2b724f7981f4796b3f5ae71470fa18f393661`
- 有缺陷快照：`73cc5b00189ac9fd28d957c19d95c0005425f02d`
- 修复快照：`99367ea81f17a39874f7516ea919298b323c594e`

## 复核结果

提案列出的 8 个单参数操作确实将 OpenAPI `parameters` 数组折叠为对象，导致前端脚本在展开 `operation.parameters` 时失败。进一步以 Node JSON 解析器进行类型感知全量对比后，确认旧快照生成过程将全部单元素数组折叠，造成 104 处结构差异，而非仅限于 `parameters`。

PM 已从后端源完整重建 `api/coderclub-openapi.json`，仅在 14 个已批准密码/Token 示例位置保留脱敏。修复后 Node 比对结果为：

- 总差异：14
- 非脱敏差异：0
- 路径与方法差异：0
- 数组/对象/字段类型差异：0

## 前端消费复验

前端 `scripts/check-api-spec.mjs` 已能读取修复后的 PM 快照，输出 OpenAPI `3.0.3`、43 个端点及新快照 SHA-256。其退出码 1 仅列出四个已批准移除的旧 POST：

- `POST /subject/category/delete`
- `POST /subject/category/update`
- `POST /subject/label/delete`
- `POST /subject/label/update`

因此快照结构阻塞已解除。Claude Code 前端下一步应以修复快照执行 `npm run api:check -- --update-baseline`，再运行 `npm test` 并提供回执；在该消费验证完成前，G1-03 保持 partial。
