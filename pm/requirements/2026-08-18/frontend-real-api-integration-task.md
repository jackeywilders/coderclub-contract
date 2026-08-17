# 前端解除 Subject Mock 并进入正式联调任务书

> **任务角色：** 前端实现（F-Impl），前端评审（F-Review）验收
> **下发角色：** 协调 PM
> **日期：** 2026-08-18
> **依据：** `pm/roadmap/2026-08-10/pm-coordination-roadmap.md` Gate 3（事项 4：分类/标签/题目分页/详情/四题型/OSS 上传）
> **前置已满足：** M4 全部验收关闭；后端契约固定（43/43，`api/coderclub-openapi.json` 快照 `9a97c055…`）；auth 模块已接真实请求；OSS 已接真实请求

## 0. 背景与联调前置实况（2026-08-18 PM 实测）

- `src/api/subject.ts` 当前 `const USE_MOCK = import.meta.env.DEV`——**dev 模式下 subject 全模块走本地 mock**（`mockCategoryTree`/`mockLabelList`/`mockSubjectPage` 等），不发起真实后端请求。这是联调的直接阻塞项。
- mock 与契约存在结构性差异（非纯开关）：
  - mock 分页返回 `{ list, total }`（无 `data` 壳、无 `pageNo/pageSize` 外壳）；契约分页为 `PageResult<T>`（`data.list/total/pageNo/pageSize`，列表项无装饰分页字段，M4-06 已确认）。
  - mock 分类/标签/题目字段（`name`/`categoryIds`/`labelIds`）需与契约 43 端点逐字段核对（快照 `api/coderclub-openapi.json`）。
- 因此本任务为"切真实 + 响应结构适配 + 端到端验证"，非一行开关。

## 1. 任务切分（前端实现执行 S1-S3；前端评审验收 S4）

| 工作项 | 内容 | 验收标准 |
| --- | --- | --- |
| **S1** | 解除 subject `USE_MOCK`，切真实请求（保留 mock 文件或标记废弃，不删除既有测试依赖） | dev 下 subject 请求经 vite proxy 打到后端（`/subject → localhost:3000`）；`npm run api:check` 通过 |
| **S2** | 前端解析适配契约响应结构：`data` 壳、分页外壳（`list/total/pageNo/pageSize`）、字段名对齐 subject/oss 各端点 | 各端点在真实后端返回下渲染正确；孰异契约疑问一律写入 `proposals/frontend/` |
| **S3** | 切真实后端到端跑通核心链路：登录 → 题目分页/详情/作答 → OSS 上传；含 401/403、loading/空/错误三态 | 端到端可用，无未解释的契约方法/鉴权/分页差异 |
| **S4**（评审验收） | 复核 S1-S3；收集联调证据并回传双轨回执 | 交接仓库落 `handoff/frontend-to-backend/2026-08-18/…`，含 `*-summary.json`（规则 9：服务地址、已验证接口清单、失败请求/响应、复现条件） |

## 2. 边界与流程

- 前端实现只改前端 `src/`、测试与必要基线（`docs/frontend/handoff/api-docs-baseline.json` 如需更新按 G1-03 既有流程）。
- **禁止**：不修改后端项目、交接仓库 `api/` 快照、`status/sync-manifest.json`；不自行裁决契约；契约疑问先写 `proposals/frontend/` 等 PM 协调后端回执。
- 前端 `AGENTS.md`/`CLAUDE.md` 补强已生效：验证被沙箱拦截时如实报告、禁止跳过验证声称完成；运行资源自管理。
- 提交遵循 Conventional Commits；规则 8（PR/提交无真实环境信息）；合入人 = 用户或前端评审（`CLAUDE.md`）。

## 3. 联调完成的信号

- 后端日志可见前端真实请求（非 mock）；分页外壳/字段与契约一致；`npm run api:check` + `npm test` + `npm run lint` + `npm run build` 全绿。
- 前端评审签署回执（双轨），PM 据以验收 Gate 3 事项 4。

## 4. 版本记录

- 2026-08-18：创建（brainstorming 产出；PM 实测 mock↔契约差异；任务书派发前端实现）。

- 下发角色：协调 PM
- 日期：2026-08-18