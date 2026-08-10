# Gate 0/1 契约归一化与消费验收清单

> **维护角色：** PM / 跨项目协调 Codex
>
> **适用基线：** 交接仓库 `main@9cc3e904b90c5e937dafc26b1da86a72ceaec3df`
>
> **当前结论：** `Gate 0` 阻塞；`Gate 1` 等待 Gate 0。前端正式 API 消费保持冻结。

## 已确认的治理决策

1. 后端项目中的 API 定义和实现是运行契约的权威来源。
2. 交接仓库不把 OpenAPI 副本作为权威契约；现有 `api/coderclub-openapi.json` 在对账完成前不得作为发布契约使用。
3. `CoderClub main@e80aaf697fecd350ad478d8fed67eb81fdf45325` 的 `docs/api/coderclub-openapi.json` 是候选权威基线，待 Backend 重新提交来源与哈希回执。
4. 分类、标签更新和删除使用 PUT/DELETE 作为正式方法，POST 仅作为临时兼容端点。
5. 分页 `total`、`list`、`totalPages` 的一致性是 Gate 1 硬性关闭条件。
6. Gate 0/1 关闭后，Frontend 才能按已确认范围分阶段进入正式 API 消费；`finalReleaseStatus` 保持 `not-published`。

## Gate 0：证据与基线归一化

| 编号 | 验收项 | Owner | 必需证据 | 状态 |
| --- | --- | --- | --- | --- |
| G0-01 | 确认候选 API 源文件身份 | Backend | 项目、分支、完整提交哈希、源路径、源 SHA-256 | 待 Backend 回执 |
| G0-02 | 解释源文件与交接声明的转换关系 | Backend | 是否脱敏/生成、转换命令、输入输出哈希、已知差异 | 待 Backend 回执 |
| G0-03 | 确认交接仓库副本治理 | PM | 治理决策、现有副本处置方案、禁止前端直接消费的记录 | 已确认，待落档 |
| G0-04 | 重新核验 Frontend 消费文件 | Frontend | 配置路径、实际 SHA-256、校验命令和结果 | 待 Frontend 回执 |
| G0-05 | 建立唯一契约映射 | PM | `source commit → source SHA → handoff reference → frontend SHA` | 未开始 |
| G0-06 | 对齐三方状态元数据 | PM | `status/pm.json`、Backend、Frontend 回执和同步清单审计记录 | 未开始 |

### Gate 0 关闭条件

- Backend 的候选源文件和来源提交可由 `git show` 复核。
- 源文件、交接声明和 Frontend 实际消费文件的差异有明确解释。
- 任何转换或脱敏都记录输入、输出、命令和哈希。
- Frontend 不再依赖无法证明来源的 `87e122...` 文件。
- `status/sync-manifest.json` 的提交字段可以反映真实映射；`finalReleaseStatus` 仍为 `not-published`。

## Gate 1：契约消费阻塞项

| 编号 | 验收项 | Owner | 必需证据 | 状态 |
| --- | --- | --- | --- | --- |
| G1-01 | 完成 47 个操作的鉴权矩阵 | Backend | 每个操作的 anonymous/login/role-permission 结论和运行时依据 | 待 Backend 回执 |
| G1-02 | 统一 401/403 语义 | Backend + Frontend | HTTP 状态、业务 code、响应结构、前端处理方式和测试 | 未开始 |
| G1-03 | 固化正式 HTTP 方法 | PM + Backend | PUT/DELETE 正式方法、POST 兼容期限、角色和移除条件 | 决策已确认，待证据 |
| G1-04 | 修复分页口径 | Backend | 无结果、单页、多页复现和回归测试 | 待 Backend 修复 |
| G1-05 | 恢复 Frontend 验证门禁 | Frontend | Node/npm 环境、API 哈希校验和 `npm run api:check` 结果 | 待环境恢复 |

### Gate 1 关闭条件

- 47 个操作全部有可审计的鉴权结论。
- 401、业务 `code=401` 和 403 的边界不再依赖前端推断。
- Frontend 首轮联调清单只包含已确认的正式方法。
- `total`、`list` 和 `totalPages` 在无结果、单页、多页场景下保持一致。
- Frontend 的 Node/npm 验证命令可以真实执行并记录结果。

## 统一回执要求

每份回执必须包含：来源项目、分支、完整提交哈希、影响范围、验证命令、验证结果、已知限制、接收方动作和待 PM 决策项。回执只引用权威源文件，不通过复制 OpenAPI 文件绕过来源核验。

## 明确禁止

- Gate 0 关闭前把 `api/coderclub-openapi.json` 视为发布契约。
- Gate 1 关闭前生成正式 API 客户端或开始依赖未确认方法的业务调用。
- 用状态文件替代源文件、运行时证据或测试结果。
- 未经 PM 明确授权把 `finalReleaseStatus` 改为已发布。
