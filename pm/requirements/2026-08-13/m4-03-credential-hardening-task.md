# M4-03 后端执行任务：凭据与环境收口

> **任务角色：** 后端实现
>
> **批准角色：** 协调 PM
>
> **任务日期：** 2026-08-13
>
> **任务状态：** 待执行

> **任务依据：** `pm/requirements/2026-08-13/m4-task-design.md` §3 M4-03（设计已获用户批准，2026-08-13 分节确认）；执行与验收流程见该设计 §4（沿用 G1-04 模型）。

## 1. 任务摘要

清理后端项目（CoderClub）代码与脚本侧的明文凭据（密码/密钥/Token），统一配置读取优先级（Nacos → 环境变量 → 本地默认）并文档化，输出端口标准策略文档（<subject-port>/<subject-alt-port>、<mysql-probe-port>/<mysql-port>）；运维侧历史暴露凭据的轮换由用户/运维执行，任务书仅记录完成结果，不要求后端执行。

## 2. 前置事实（PM 已核验）

### 2.1 任务来源

`pm/requirements/2026-08-13/m4-task-design.md` §3 M4-03（M4 六项任务之一，无依赖，可与 M4-01/02 并行）：

- 背景：「历史文档与脚本可能存在明文凭据；启动脚本已由 `7c3ac66` 改为先安装再运行；Nacos/环境变量优先级与端口策略需统一记录。」
- 范围：
  - 代码侧（后端实现职责）：启动脚本/配置文件明文密码清理、统一 Nacos/环境变量优先级、<subject-port>/<subject-alt-port> 与 <mysql-probe-port>/<mysql-port> 端口策略文档
  - 运维侧（用户/运维职责，交接仓库只记录结果）：历史暴露凭据的轮换操作

### 2.2 启动脚本已修复（不重复执行）

后端提交 `7c3ac66`（fix(scripts): 启动脚本先安装再运行，避免引用过期 m2 jar）：`start-subject.ps1`/`start-auth.ps1`/`start-oss.ps1` 各增加 `mvn install -DskipTests -q -pl <starter> -am` 前置。见 `handoff/backend-to-frontend/2026-08-12/g1-04-claude-code-backend-execution-report.md` 与 `pm/reviews/2026-08-13/g1-04-close-acceptance.md`。

### 2.3 API 源凭据状态（快照侧已脱敏）

`status/backend.json` 已核验：

- `apiSourceJwtOrAbsolutePathValues=false`：API 源（`docs/api/coderclub-openapi.json`）不含 JWT/绝对路径值。
- `credentialsRemoved=true`、`localAbsolutePathsRemoved=true`、`sanitizedExamples=true`：快照侧凭据清理与脱敏已完成。

因此本任务 grep 核验对象为后端项目内脚本与配置文件（及文档中的可执行示例），快照不在清理范围（见禁止事项）。

## 3. 执行步骤（按顺序执行）

### 步骤 1：grep 全模块明文凭据并清理（代码侧）

- 在后端项目全模块执行 grep 核验，覆盖启动脚本（`start-subject.ps1`/`start-auth.ps1`/`start-oss.ps1` 等）、配置文件（`application*.yml`、`*.properties`、`bootstrap*.yml` 等）与文档中的可执行示例。
- 核验关键字：密码（password/pwd/passwd）、密钥（secret/key）、Token（token）类明文凭据值。
- 清理发现的明文凭据：改为环境变量引用或占位符，明文值移至本机环境变量/未入库配置；清理单独提交。
- 保留清理前/后的 grep 原始输出作为回执证据，并记录清理提交哈希。

### 步骤 2：统一配置读取优先级并文档化（代码侧）

- 统一配置读取优先级：**Nacos → 环境变量 → 本地默认配置**，并文档化各来源的职责边界。
- 输出配置优先级文档（置于后端项目内，后端实现可写区域），路径与提交哈希在回执中声明。

### 步骤 3：输出端口策略文档（代码侧）

- 输出端口标准策略文档：逐项明确 <subject-port>/<subject-alt-port> 与 <mysql-probe-port>/<mysql-port> 的标准用途（端口 × 用途/服务），作为后续启动与排障的统一依据。
- 文档置于后端项目内（后端实现可写区域），路径与提交哈希在回执中声明。

### 步骤 4：记录凭据轮换结果（运维侧，由用户/运维提供）

- 历史暴露凭据的轮换属**运维动作**，由用户/运维执行并提供完成记录；本任务书不要求 后端实现执行轮换。
- 轮换完成记录由用户提供，后端评审 复核回执时引用该记录；如轮换不可行，须 PM 书面例外（例外仅限执行方式而非完成，见设计 §7 风险 2）。

### 步骤 5：提交回执（执行后由 后端评审 复核签署）

回执文件：`handoff/backend-to-frontend/<执行日期>/m4-03-credential-hardening-report.md`（回执目录按回执实际创建日期落位，即执行者写回执当天，AGENTS.md 第 6 条），必须包含：

1. 来源项目、分支、实施提交哈希与回执提交哈希。
2. grep 核验命令与原始输出（清理前/后，含无明文凭据结论）。
3. 配置优先级文档与端口策略文档路径。
4. 凭据轮换完成记录引用（用户/运维提供；如为 PM 书面例外，记录例外编号/日期）。
5. 已知限制（环境变量配置方式、服务地址、遗留项等）。
6. 声明：未修改交接仓库 `api/` 快照、`status/sync-manifest.json`；未伪造验证输出。

## 4. 验收边界与关闭条件

- 本任务代码侧仅覆盖后端项目内启动脚本/配置文件的明文凭据清理、配置读取优先级统一与端口策略文档；凭据轮换属运维侧动作（用户/运维职责），交接仓库只记录结果，不要求后端执行。
- 关闭条件（全部满足后 PM 复核关闭 M4-03）：
  1. grep 核验无明文凭据（核验命令与输出 + 清理提交哈希）。
  2. 配置优先级文档（Nacos → 环境变量 → 本地默认）与端口策略文档（<subject-port>/<subject-alt-port>、<mysql-probe-port>/<mysql-port> 标准用途）存在。
  3. 回执含凭据轮换完成记录引用（用户/运维提供；如轮换不可行，须 PM 书面例外）。
  4. 回执含原始命令输出与提交哈希，后端评审 复核签署。
- 若 grep 核验仍发现明文凭据，或配置优先级/端口策略与运行行为不一致：**M4-03 不关闭**，继续清理与修正直至核验通过。

## 5. 禁止事项

- 不得修改交接仓库 `api/coderclub-openapi.json` 快照与 `status/sync-manifest.json`（快照已脱敏，不属本任务清理对象）。
- 凭据轮换属运维侧动作（用户/运维职责），本任务书不要求后端执行轮换，后端不得代为执行，也不得伪造轮换完成记录。
- 不得在回执中伪造 grep 核验输出、提交哈希或轮换记录。

- 批准角色：协调 PM
- 日期：2026-08-13
