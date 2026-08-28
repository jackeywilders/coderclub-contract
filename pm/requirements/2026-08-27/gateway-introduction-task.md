# 任务书：网关（coder-club-gateway）引入实施（A8 后端架构方向 Q2/Q3，与阶段二并行）

> **派发角色：** 协调 PM
> **派发日期：** 2026-08-27
> **执行角色：** 后端实现（B-Impl）
> **复核角色：** 后端评审（B-Review）
> **架构依据：** `docs/superpowers/specs/2026-08-27-a8-backend-architecture-direction.md`（PR #79）§5（网关专项）
> **状态：** 独立任务线，与阶段二 practice proposal/实现并行；网关就绪后 practice/circle/interview 新域从第一天挂网关

## 1. 目标

引入统一网关 `coder-club-gateway`：统一入口、登录校验（401 语义统一）、loginId header 透传；现有 auth/subject/oss 服务接入网关（业务代码零迁移，`@SaCheckLogin` 保留双保险）；为阶段二~四新域提供统一入口基础。

## 2. 实施边界（仅以下范围）

### 2.1 新模块

- `coder-club-gateway`（starter 形态独立应用，WebFlux）
- 依赖：`spring-cloud-starter-gateway`、`sa-token-reactor`（WebFlux 反应式版）+ `sa-token-redis-jackson`（**与业务服务同一 Redis 存储**，共享 token 体系）、Nacos 服务发现（沿用现有注册中心；docker-compose 内服务名直连作为实现期验证取舍）

### 2.2 鉴权模型（登录校验级）

- SaReactorFilter 拦截全部请求：未登录（无有效 token）→ HTTP 401；白名单路径直接放行
- **匿名白名单（已知列举 + 强制逐项核对）**：`/auth/login`、`/auth/register`、`/auth/wx-login`、`/oss/upload`、`/oss/getUrl` 及健康检查路径；**实现期按契约 46 端点逐项核对白名单（验收强制项——漏配将导致登录/注册瘫痪）**，核对表写入回执
- **loginId 透传**：网关 GlobalFilter 解析 Sa-Token 取 loginId → 写入 header（`loginId`）转发下游；**必须覆盖客户端传入的同名头（防伪造）**
- **权限校验不迁移**：现有服务内权限逻辑（admin 系列等）维持现状，不搬网关（避免双份漂移）
- 401 语义：未登录 401 从网关返回（业务服务 `@SaCheckLogin` 双保险保留，行为不变；契约测试 standalone MockMvc 不经网关不受影响）

### 2.3 路由表

| 前缀 | 目标服务（Nacos 名/服务名） |
| --- | --- |
| `/auth/**` | coder-club-auth |
| `/subject/**` | coder-club-subject |
| `/oss/**` | coder-club-oss |
| `/practice/**` | coder-club-practice（预留，阶段二就绪后生效） |
| `/circle/**` | coder-club-circle（预留） |
| `/interview/**` | coder-club-interview（预留） |

StripPrefix 实现期按实际 controller 路径确认（现有 controller 路径即 `/域/...`，倾向直通）。

### 2.4 CORS

- CORS 统一配置在网关（允许域名占位符化，配置项化）；业务服务不再各自处理（现有无显式 CORS 则零迁移）

### 2.5 兼容性（外部零改动）

- 契约路径零变更（网关透明路由）；前端代码零改动（仅 vite proxy 目标改网关单入口 + 部署 env）；业务服务 `@SaCheckLogin` 保留；现有 Feign 透传（satoken 头）保留；契约测试不受影响

### 2.6 部署与运行

- docker-compose 新增 `coder-club-gateway` 服务（对外暴露网关端口；auth/subject 容器保持内部端口——本地/云端过渡期可双暴露，切换完成后收敛为仅经网关）
- 本地 `start-gateway.ps1`（Nacos 凭据沿用用户级环境变量模式，真实值不落盘）
- 前端 vite proxy 单入口调整说明（配置项，改由用户/前端随验收切换——**前端代码不改**）

## 3. 禁止事项

- 不修改业务服务业务代码（鉴权注解保留；不迁移权限逻辑；不删除 `@SaCheckLogin`）
- 不改契约、`api/` 快照、`status/sync-manifest.json` 及治理文件
- 不引入网关鉴权到权限级（不做 checkPermission 细则迁移）
- 不处理 WebSocket 透传（后置项，不经网关评估）

## 4. 交付与回执（规则 9 双轨）

1. 实施提交推送后端仓库（Conventional Commits，如 `feat(gateway): introduce spring-cloud-gateway with sa-token reactor auth (A8)`）。
2. 回执双轨落 `handoff/backend-to-frontend/2026-08-27/`：Markdown（模块结构、白名单逐项核对表（46 端点）、loginId 透传与覆写实现说明、路由表、CORS 配置、部署与切换说明、本地四命令/联调证据）+ `*-summary.json`（模板字段：`taskId=GW-1`、`sourceProject=G:/Dev/backend/Club/CoderClub`、`contractSnapshotSha256=4bfb3c72`（零变更）、`verificationResult`）。
3. 完成通知带四字段告知 B-Review 复核签署；签署后转 PM 验收。
4. 云端/本地真实联调：网关 401、白名单放行、loginId 透传（含覆写验证）、路由 6 前缀可达；**与 A8-P1-BE 云端验证衔接**（search/contribute/Feign/401 经网关链路一并验证）。

## 5. 验收标准

- [ ] 网关模块就绪，6 前缀路由可达（含预留 3 域配置）；未登录 401 语义统一
- [ ] 白名单逐项核对表完整（46 端点核对，漏配 0）；loginId 透传 + 覆写防伪造验证通过
- [ ] 兼容性：现有 auth/subject/oss 经网关功能可用（登录/浏览/上传冒烟）；`@SaCheckLogin` 保留；契约测试不受影响（全量回归绿）
- [ ] CORS 配置化；docker-compose + start 脚本 + 前端入口切换说明齐备
- [ ] 回执双轨 + 四字段；无真实环境信息（规则 8）

## 6. 关联

- 架构方向：`docs/superpowers/specs/2026-08-27-a8-backend-architecture-direction.md`（PR #79）§5
- 并行：阶段二 practice proposal（B-Review 差异分析 + 提案，另一任务）
- 后续：网关验收后阶段二~四新域接入网关；云端真实入口切换由用户/运维执行