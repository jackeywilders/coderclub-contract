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
| 凭据外部化提交 | `2c95730`（fix(scripts): 启动脚本 Nacos 密码改环境变量读取） |
| 凭据外部化提交 | `0fa9f41`（fix(scripts): 启动脚本 Nacos 用户名也改环境变量读取） |
| 文档提交 | `e6eec67`（docs(backend): M4-03 配置优先级与端口策略文档） |
| 文档提交 | `8d596ad`（docs(backend): M4-03 三服务 Nacos 配置上收参考文档） |
| 文档提交 | `d4192cf`（docs(backend): M4-03 文档聚焦敏感配置上收 Nacos） |
| 回执提交哈希 | `5b89a2450cf956c02dbef36fcce72ef59c659f7a`（Backend Codex 签署提交） |

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
- **Nacos 敏感配置上收文档**：`docs/backend/2026-08-13-m4-03-nacos-config-consolidation.md`（三服务 `*-dev.properties` 模板与敏感项清单，凭据以占位符呈现）

## 3.1 Nacos 敏感配置上收验证（本报告追加，2026-08-13）

用户已在 Nacos（dev 命名空间）发布三个 `*-dev.properties`，后端侧完成静态与运行时双重复核：

**静态复核（Nacos 拉取内容核对）**：
- `coder-club-auth-dev.properties` / `coder-club-subject-dev.properties` / `coder-club-oss-dev.properties` 均已上收 Nacos 客户端凭据、MySQL/Redis/MinIO 凭据、Druid、sa-token、Jackson、multipart、mybatis-flex、actuator/springdoc、端口等全部敏感与共享配置。
- Subject 补全了此前缺失的 `spring.data.redis` 段与 sa-token 段；OSS 含 MinIO AK/SK 与 `oss.debug.enabled` 调试开关。
- 三服务凭据值一致（Nacos 用户、MySQL、Redis、MinIO 均使用轮换后新值）。

**运行时冒烟验证（Auth 全链路）**：
- 以轮换后 Nacos 凭据（`NACOS_USERNAME`/`NACOS_PASSWORD` 环境变量注入）启动 Auth，`Started AuthApplication in 19.549s`，Nacos 配置拉取、MySQL 连接、Redis 连接全部正常。
- 登录接口返回 `code=200`，验证了 Nacos 配置 → Druid 数据源 → Redis 会话链路的端到端可用性。

> 备注：Subject/OSS 在 Nacos 新配置下的启动验证见后端侧未决项（M4 验证步骤），Auth 已覆盖最完整依赖链路。

## 4. 凭据轮换完成记录（运维侧，用户提供）

用户于 **2026-08-13** 完成历史暴露凭据轮换（Nacos/Redis/MySQL/MinIO 密码与密钥）。代码侧已配合：
- 启动脚本不再硬编码 Nacos 密码与用户名（提交 `2c95730` + `0fa9f41`），轮换后仅需设置环境变量 `NACOS_USERNAME`/`NACOS_PASSWORD`（Subject 另需 `REDIS_PASSWORD`）。
- 轮换后 Nacos 配置已同步新值：`spring.cloud.nacos.password`、`spring.datasource.password`、`spring.data.redis.password`、`minio.accessKey/secretKey`（已在 Nacos 发布并经静态+运行时双重复核，见 §3.1）。

## 5. 已知限制

1. **Nacos 配置持有运行凭据**：MySQL/Redis/MinIO/Nacos 自身密码在 Nacos 配置文件中，凭据轮换需在 Nacos 控制台同步更新（不在仓库代码提交范围）。
2. **启动依赖环境变量**：`start-*.ps1` 现要求 `NACOS_USERNAME`/`NACOS_PASSWORD` 环境变量（Subject 另需 `REDIS_PASSWORD`）；未设置会阻止启动并提示。
3. **API 快照脱敏**：`docs/api/coderclub-openapi.json` 示例密码/Token 已用占位符（既有状态，未改）。
4. **历史暴露面**：本任务清理了仓库内明文凭据；历史交接文档/日志中若曾有暴露，由轮换动作兜底（已完成）。

## 6. 声明

- 未修改交接仓库 `api/coderclub-openapi.json` 快照与 `status/sync-manifest.json`。
- 未修改前端项目；未代为执行或伪造凭据轮换（轮换由用户执行并提供完成记录）。
- 所有 grep 核验输出与提交为真实结果，未伪造。

## 7. Backend Codex 复核签署（2026-08-13）

- [x] 代码级复核：三启动脚本 Nacos 用户名/密码环境变量化 + 缺失校验、已知 5 个历史凭据全库 grep 零命中（独立复验）、种子密码为 BCrypt 哈希、配置优先级/端口策略/Nacos 上收文档齐全 — **通过**
- [x] 独立重跑：`SubjectContractTest` 49/49 + `AuthContractTest` 8/8 + `FileControllerTest` 11/11，BUILD SUCCESS — **通过**
- [x] OpenAPI SHA-256 未变（`7576e28a…`，43/43）— **通过**
- [x] 凭据轮换完成记录（用户 2026-08-13 提供）引用核验 — **通过**
- [x] M4-03 关闭条件 1-4 满足；签署本回执
- [问题] 回执 §3.1 备注「Subject/OSS 在 Nacos 新配置下的启动验证见后端侧未决项」：OSS 已由 M4-02 §8 真实复核覆盖；**Subject 在轮换后 Nacos 配置下的独立启动验证未见明确记录**，建议在 M4 后续验证中补记（不阻塞本任务签署）

**复核签署**：Backend Codex，2026-08-13（工作底稿：`designs/backend/2026-08-13/m4-03-credential-hardening-review-workpaper.md`）
