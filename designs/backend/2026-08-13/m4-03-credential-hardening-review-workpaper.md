# M4-03 Backend Codex 复核工作底稿

> 角色：Backend Codex
> 日期：2026-08-13
> 任务来源：`pm/requirements/2026-08-13/m4-03-credential-hardening-task.md`
> 回执：`handoff/backend-to-frontend/2026-08-13/m4-03-credential-hardening-report.md`

## 1. 代码级复核（提交 `2c95730` / `0fa9f41` / `e6eec67` / `8d596ad` / `d4192cf`）

| 核对项 | 结果 |
| --- | --- |
| 三启动脚本 Nacos 用户名/密码环境变量化（`NACOS_USERNAME`/`NACOS_PASSWORD`）+ 缺失校验阻止启动 | ✅ 独立检查脚本确认 |
| 已知 5 个历史凭据值全库 grep（ps1/yaml/properties/java/md/sql）零命中 | ✅ 独立 grep 复验 |
| 种子数据密码为 BCrypt 哈希（`$2a$10$…`），无明文 | ✅ 独立检查 |
| 配置优先级文档（Nacos → 环境变量 → 本地默认）`m4-03-config-precedence.md` | ✅ 质量良好 |
| 端口策略文档（<subject-port>/<subject-alt-port>、<mysql-probe-port>/<mysql-port> 等）`m4-03-port-policy.md` | ✅ 质量良好 |
| Nacos 敏感配置上收文档 `m4-03-nacos-config-consolidation.md` + 附加提交（actuator/springdoc、gitignore） | ✅ |
| 凭据轮换完成记录（用户 2026-08-13 提供） | ✅ 回执 §4 引用 |

## 2. 独立测试重跑（本底稿复核时执行）

| 命令 | 结果 |
| --- | --- |
| `SubjectContractTest` / `AuthContractTest` / `FileControllerTest` | 49/49 + 8/8 + 11/11，均 BUILD SUCCESS |
| OpenAPI SHA-256 | `7576e28a…` 未变（43/43） |

## 3. 复核结论与备注

- **结论：通过，可签署。**
- [问题] 回执 §3.1 备注「Subject/OSS 在 Nacos 新配置下的启动验证见后端侧未决项」：OSS 已由 M4-02 §8 真实复核覆盖（Auth + OSS 启动验证）；**Subject 在轮换后 Nacos 配置下的独立启动验证未见明确记录**，建议在 M4 后续验证（如 M4-04/05 或 PM 验收）中补记。不阻塞本任务签署（代码侧凭据清理与文档已完成并核验）。
- 已知限制与回执一致：Nacos 配置持有运行凭据（轮换在 Nacos 控制台更新，不在代码提交范围）；启动依赖环境变量。

复核签署：Backend Codex，2026-08-13
