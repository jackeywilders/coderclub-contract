# M4-03 后端执行报告：凭据与环境收口

> **任务角色：** Claude Code 后端
> **任务来源：** `pm/requirements/2026-08-13/m4-03-credential-hardening-task.md`（PM 批准）
> **复核角色：** Backend Codex
> **报告日期：** 2026-08-13
> **契约影响：** 无（未改变 HTTP 契约）

## 1. 来源与提交哈希

| 项目 | 值 |
| --- | --- |
| 来源项目 | `G:/Dev/backend/Club/CoderClub` |
| 来源分支 | `main` |
| 清理提交 | `2c95730`（fix(scripts): 启动脚本 Nacos 密码改环境变量读取） |
| 文档提交 | `e6eec67`（docs(backend): M4-03 配置优先级与端口策略文档） |
| 回执提交哈希 | （Backend Codex 签署时填写） |

## 2. grep 核验命令与原始输出

**核验范围**：后端项目启动脚本（`start-*.ps1`）、配置文件（`application*.yaml`/`*.properties`）、文档（`*.md`）、SQL、Java 源码。

**核验关键字**：Nacos/Redis/MySQL/MinIO 已知凭据值（`<redacted-credential>`、`<redacted-credential>`、`<redacted-credential>`、`<redacted-credential>`、`<redacted-credential>`）。

**清理前**：命中 4 处——
- `start-auth.ps1:3`、`start-subject.ps1:3`、`start-oss.ps1:3`：`$NACOS_PASSWORD = "<redacted-credential>"`（明文硬编码）
- `.superpowers/sdd/progress.md`：遗留旧 Redis 密码引用（该文件已被 gitignore，非仓库内容，已就地脱敏）

**清理后**：grep 无任何命中（项目内脚本/配置/文档/代码无真实凭据残留）。

**清理动作**：
1. 三启动脚本 Nacos 密码改为从环境变量 `NACOS_PASSWORD` 读取，未设置时阻止启动（同 `REDIS_PASSWORD` 校验模式）。
2. 本地 sdd 台账旧密码值替换为占位描述。

## 3. 文档路径

- **配置优先级文档**：`docs/backend/2026-08-13-m4-03-config-precedence.md`（Nacos → 环境变量 → 本地默认；凭据不入库、启动脚本环境变量校验）
- **端口策略文档**：`docs/backend/2026-08-13-m4-03-port-policy.md`（服务端口 <auth-port>/<subject-port>/<subject-alt-port> 备用/<oss-port>；中间件 <mysql-probe-port>/<mysql-port>、<redis-port>、<nacos-port>、<minio-port>）

## 4. 凭据轮换完成记录（运维侧，用户提供）

用户于 **2026-08-13** 完成历史暴露凭据轮换（Nacos/Redis/MySQL/MinIO 密码与密钥）。代码侧已配合：
- 启动脚本不再硬编码 Nacos 密码（提交 `2c95730`），轮换后仅需设置环境变量 `NACOS_PASSWORD`。
- 轮换后需在 Nacos 配置同步新值：`spring.cloud.nacos.password`、`spring.datasource.password`、`spring.data.redis.password`、`minio.accessKey/secretKey`。

## 5. 已知限制

1. **Nacos 配置持有运行凭据**：MySQL/Redis/MinIO/Nacos 自身密码在 Nacos 配置文件中，凭据轮换需在 Nacos 控制台同步更新（不在仓库代码提交范围）。
2. **启动依赖环境变量**：`start-*.ps1` 现要求 `NACOS_PASSWORD` 环境变量（Subject 另需 `REDIS_PASSWORD`）；未设置会阻止启动并提示。
3. **API 快照脱敏**：`docs/api/coderclub-openapi.json` 示例密码/Token 已用占位符（既有状态，未改）。
4. **历史暴露面**：本任务清理了仓库内明文凭据；历史交接文档/日志中若曾有暴露，由轮换动作兜底（已完成）。

## 6. 声明

- 未修改交接仓库 `api/coderclub-openapi.json` 快照与 `status/sync-manifest.json`。
- 未修改前端项目；未代为执行或伪造凭据轮换（轮换由用户执行并提供完成记录）。
- 所有 grep 核验输出与提交为真实结果，未伪造。
