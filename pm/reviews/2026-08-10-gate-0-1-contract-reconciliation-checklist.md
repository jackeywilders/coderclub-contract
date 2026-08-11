# Gate 0/1 契约归一化与消费验收清单

> **维护角色：** PM / 跨项目协调 Codex
>
> **适用基线：** 交接仓库 `main@9cc3e904b90c5e937dafc26b1da86a72ceaec3df`
>
> **当前结论：** `Gate 0` 的开发契约快照已通过并关闭；`Gate 1` 部分通过但未关闭。发布和未确认方法的正式联调仍受阻。

## 已确认的治理决策

1. 后端项目中的 API 定义和实现是运行契约的权威来源。
2. 经 PM 批准，交接仓库 `api/coderclub-openapi.json` 是后续开发的权威契约快照；后端项目的 API 定义和实现仍是运行时权威来源，快照不等于发布契约。
3. `CoderClub main@e80aaf697fecd350ad478d8fed67eb81fdf45325` 的 `docs/api/coderclub-openapi.json` 已与快照完成结构化对账；快照提交为 `1a2aff823b3b941b6d9c0ccd8a29f40545d3eb17`，快照 SHA-256 为 `87e122b545ed529edc167b80279869205440be84e12c4407850dfa1d4ff2166b`。
4. 分类、标签更新和删除使用 PUT/DELETE 作为正式方法，POST 仅作为临时兼容端点。
5. 分页 `total`、`list`、`totalPages` 的一致性是 Gate 1 硬性关闭条件。
6. Gate 0 的开发快照验收完成后，Frontend 可按已确认范围分阶段推进开发；Gate 1 未关闭前不得依赖未确认的方法、鉴权语义或分页行为进行正式联调；`finalReleaseStatus` 保持 `not-published`。

## Gate 0：证据与基线归一化

| 编号 | 验收项 | Owner | 必需证据 | 状态 |
| --- | --- | --- | --- | --- |
| G0-01 | 确认候选 API 源文件身份 | Backend | 项目、分支、完整提交哈希、源路径、源 SHA-256 | PM 已验收 |
| G0-02 | 解释源文件与交接声明的转换关系 | Backend | 是否脱敏/生成、转换命令、输入输出哈希、已知差异 | PM 已验收 |
| G0-03 | 确认交接仓库副本治理 | PM | 治理决策、现有副本处置方案、开发/发布边界记录 | 已通过：ADR-0001 批准为开发契约快照，发布仍未放行 |
| G0-04 | 重新核验 Frontend 消费文件 | Frontend | 配置路径、实际 SHA-256、校验命令和结果 | PM 已验收 |
| G0-05 | 建立唯一契约映射 | PM | `source commit → source SHA → handoff commit/path → snapshot SHA` | 已通过：当前快照映射已固定，历史 `0057e69...` 声明已标记 |
| G0-06 | 对齐三方状态元数据 | PM | `status/pm.json`、Backend、Frontend 回执和同步清单审计记录 | 已通过（开发范围）：同步清单已记录完整映射，发布字段仍未发布 |

### Gate 0 关闭条件

- Backend 的候选源文件和来源提交可由 `git show` 复核。
- 源文件、交接声明和 Frontend 实际消费文件的差异有明确解释。
- 任何转换或脱敏都记录输入、输出、命令和哈希。
- `87e122...` 快照的来源、提交和 14 处示例值脱敏差异均已记录；Frontend 后续消费必须固定到该提交和哈希。
- `status/sync-manifest.json` 的提交字段可以反映真实映射；`finalReleaseStatus` 仍为 `not-published`。

**本次 PM 判定：** G0-01 至 G0-06 均已通过开发范围验收；Gate 0 关闭仅表示开发契约快照可消费，不表示 `releaseStatus` 或 `finalReleaseStatus` 已发布。

## Gate 1：契约消费阻塞项

**状态：部分通过，Gate 0 开发快照依赖已解除。**

| 编号 | 验收项 | Owner | 必需证据 | 状态 |
| --- | --- | --- | --- | --- |
| G1-01 | 完成 47 个操作的鉴权矩阵 | Backend | 每个操作的 anonymous/login/role-permission 结论和运行时依据 | PM 已验收 |
| G1-02 | 统一 401/403 语义 | Backend + Frontend | HTTP 状态、业务 code、响应结构、前端处理方式和测试 | 已通过：后端与前端证据均完成，PM 已正式关闭；细粒度权限矩阵另列 M4 |
| G1-03 | 固化正式 HTTP 方法 | PM + Backend | PUT/DELETE 正式方法、POST 兼容期限、角色和移除条件 | 部分通过：正式方法通过，兼容期限待定 |
| G1-04 | 修复分页口径 | Backend | 无结果、单页、多页复现和回归测试 | PM 已验收代码级证据，真实 DB 待复核 |
| G1-05 | 恢复 Frontend 验证门禁 | Frontend | Node/npm 环境、API 哈希校验和 `npm run api:check` 结果 | 已通过：用户确认默认 Node/npm 入口，前端验证证据完整 |

### Gate 1 关闭条件

- 47 个操作全部有可审计的鉴权结论。
- 401、业务 `code=401` 和 403 的边界不再依赖前端推断。
- Frontend 首轮联调清单只包含已确认的正式方法。
- `total`、`list` 和 `totalPages` 在无结果、单页、多页场景下保持一致。
- Frontend 的 Node/npm 验证命令可以真实执行并记录结果。

**本次 PM 判定：** G1-01、G1-02、G1-04 的代码级证据和 G1-05 已通过；仅 G1-03 与 G1-04 真实数据库复核仍有未关闭项，因此 Gate 1 不关闭。

## 统一回执要求

每份回执必须包含：来源项目、分支、完整提交哈希、影响范围、验证命令、验证结果、已知限制、接收方动作和待 PM 决策项。涉及开发契约快照时，还必须引用源提交、快照提交、源/快照 SHA-256 和语义差异。

## 明确禁止

- 把 `api/coderclub-openapi.json` 的开发批准误认为发布批准。
- 在 Gate 1 关闭前依赖未确认的方法、鉴权语义或分页行为进行正式联调。
- 用状态文件替代源文件、运行时证据或测试结果。
- 未经 PM 明确授权把 `finalReleaseStatus` 改为已发布。
