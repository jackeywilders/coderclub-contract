# GW-1 网关引入 + A8-P2-BE practice 练题域——后端评审复核工作底稿（双任务）

> 角色：后端评审（B-Review）
> 日期：2026-08-27/28
> 任务书：GW-1 `pm/requirements/2026-08-27/gateway-introduction-task.md`（PR #80）；A8-P2 `pm/requirements/2026-08-27/phase2-practice-implementation-task.md`（PR #82）
> 回执：`handoff/backend-to-frontend/2026-08-27/backend-gw1-gateway-introduction-*` + `backend-a8p2-practice-domain-*`（已合入交接仓库 main）
> 实施：GW-1 CoderClub PR #13（head `5c0fb421`，24 commits，**已合入 main** `b960da3`）；A8-P2-BE CoderClub PR #14（head `a57f6b8a`，25 commits，open 未合入）

## 1. 人链核验：实施提交存在性（verification-workflow §5）

| 项 | 证据 | 结果 |
| --- | --- | --- |
| GW-1 提交对象 | `git rev-parse 5c0fb421be9d3f2e6d0c54d44e36f5b7cd10a63f` 成功；main @ `b960da3`（PR #13 merge，R2 已合入） | ✅ |
| A8-P2 提交对象 | `git rev-parse a57f6b8ae7142a8c4b1e5cfbc32b8936af297dfc` 成功；远端分支 head 一致（含 final-review `b33d310` 交卷守卫 + `a57f6b8` openapi） | ✅ |
| CI | PR #13 / PR #14：build-and-test + sensitive-scan 均 success | ✅ |
| summary 一致性 | GW-1 `implementationCommitSha=5c0fb421`、PR #13、`receiptCommitSha=0ad60da0`；A8-P2 `a57f6b8a`、PR #14、`c24b51e3`；均 `contractSnapshotSha256=4bfb3c72` 与回执/快照一致 | ✅ |

## 2. GW-1 代码级复核（对照 diff：+26 文件 2082+/8-；gateway 模块 + pom/docker/scripts）

| 核对项 | 结果 |
| --- | --- |
| 白名单：7 项配置（5 端点 + 2 actuator）逐项核对 46 端点（回执 §4 表 1-46）——匿名集合 = 白名单 5 项，41 需登录；`oss/upload` 服务内 `@SaCheckLogin` 双保险放行 | ✅ 逐项比对契约路径一致 |
| 401 语义：SaReactorFilter 未登录 → 401 + `{"success":false,"code":401,"message":"未登录或Token已过期","data":null}`（与 auth 全局异常一致） | ✅ |
| loginId 透传/覆写：GlobalFilter 剥除客户端同名头防伪造；白名单剥除且不写；`SaReactorSyncHolder` 上下文窗口 | ✅ 集成测试 15 覆盖 |
| 6 前缀路由 + StripPrefix=0；预留域（practice/circle/interview）503 | ✅ RouteDefinition 3 用例 |
| SCG 5.0.0 配置命名空间 `spring.cloud.gateway.server.webflux.*` | ✅ 路由完备性断言防回归 |
| CORS 统一（GATEWAY_CORS_ALLOWED_ORIGINS 占位符）；OPTIONS 预检放行 | ✅ |
| sa-token 1.45→1.46 全盘升级（BOM 单点）；上游 #916/#968/#970 影响分析（无 Redisson/Lettuce） | ✅ README §8 |
| 业务服务代码零改动；`@SaCheckLogin` 保留双保险；契约零变更（`4bfb3c72`） | ✅ diff 确认仅 pom/docker/oss-yaml 1 键 |
| 部署：Dockerfile.gateway 全 pom 树、compose +gateway、start-gateway.ps1（NACOS_ADDR env） | ✅ |

## 3. A8-P2-BE 代码级复核（对照 diff：+146 文件 11722+/188-）

| 核对项 | 结果 |
| --- | --- |
| internal 4 端点（I1 随机抽题/I2 类目计数/I3 批量取题/I4 判分）路径登记 + Feign 边界（全 diff 无可疑表直连） | ✅ 17 路径逐一确认 |
| **判分唯一实现**：`AbstractSubjectTypeHandler` 新增抽象 `judgeSubject(Long,String)` + 4 Handler 实现；`buildStandardAnswer` 标准侧唯一（isCorrect==1 → optionType → distinct → 排序 → join）；radio/multiple 集合相等比对、judge 布尔、brief `judgeable=false` | ✅ 实读源码 |
| **交卷先补差集再算率**：`PracticeDetailDomainServiceImpl` 差集 = set_detail 全题集 − 已答集 → saveBatch → 重读统计（分母剔除简答）→ correct_rate HALF_UP → complete_status=1 → set_heat+1；InOrder 断言锁定 | ✅ 源码 + 测试 |
| **submitSubject update-or-insert 幂等** + **交卷后禁止提交 400 守卫**（final-review `b33d310` 加） | ✅ |
| **越权防护**：`requireOwnedPractice`（存在/本人）覆盖 6 端点；giveUp 交卷后亦可放弃 | ✅ |
| 报告标签聚合→星级（C6）、getSubjectDetail I3 withAnswer=true（C5）、排行 topN 10/20 + Feign 昵称降级 | ✅ |
| 17 路径契约登记（practice 13 + internal 4）；既有 46 路径语义零变更 | ✅ 路径逐一存在 |
| 无 DDL（D0）；`api/` 快照与 sync-manifest 零改动 | ✅ |

## 4. 独立复验（本底稿复核时执行，附着 `a57f6b8a`；非回执声明转录）

| 命令 | 结果 |
| --- | --- |
| 全量 `mvn install -DskipTests -q`（含新 module） | exit 0 |
| `mvn test -pl coder-club-gateway`（GW-1） | **69/69** BUILD SUCCESS（WhitelistClassification 49 + AuthIntegration 15 + RouteDefinition 3 + Context 2） |
| `SubjectContractTest`（A8-P2，subject-app-controller） | **71/71**（57 基线 + internal 14） |
| `PracticeContractTest`（A8-P2，practice-app-controller） | **22/22**（13 端点全覆盖） |
| 源文档 LF SHA-256（A8-P2，`git show` cmd 字节态） | before（`b960da3`）`BA74B152…93B1` → after（`a57f6b8a`）`9EC37C66…9D4D`——与回执 §5 逐字一致 |
| 新路径登记 | 17 个（practice 13 + internal 4）逐一在 source doc 中确认存在 |
| 容器级 | **本机无 Docker（`Get-Command docker`=False）**——容器冒烟无法本地执行，按回执建议列为验收补充（README §7 `docker compose up --build`） |

## 5. SAP 观察项（签署中打包，不阻塞）

| 观察项 | 依据 | 建议 |
| --- | --- | --- |
| docker 容器冒烟 | 本机无 Docker；GW-1/A8-P2 回执均列"容器级实证验后补充" | 验收/后续在有 docker 环境执行 `docker compose up --build` 全栈冒烟（README §7 / §12）；本机可先行 mvn 层复验（已做） |
| practice_detail 唯一索引 | DDL 无 `uk(practice_id, subject_id)`；submitSubject update-or-insert 低概率并发二行窗口（回执 §8 已记录，D0 人类裁定） | 保持无 DDL（接受 + putIfAbsent/distinct 兜底）；后续可经 proposal 评估补唯一索引 |
| 双套 PageInfo 架构债 | `com.jackey.common.entity.req.PageInfo`（common）与 `com.jackey.subject.common.entity.req.PageInfo`（subject-common）并存；practice 用 common 版 | 单独立项收敛（subject-common 移除或合流）；不随本任务处理 |

## 6. 复核结论与备注

- **结论：两份均通过，可签署。**
- 与回执声明（白名单 46 核对、401 精确体、loginId 覆写、云端 9 项联调、17 端点、硬条件锁定、1028 例、SHA、契约完整）逐项一致；未发现 [必须修复] / [建议修改] 问题。
- [仅供参考] GW-1 回执 §11 观察：auth 未注册 SaInterceptor → 类级 `@SaCheckRole("admin_user")` 当前运行时实际不生效（既有权检查缺口）；网关登录校验级使 admin 类端点至少要求有效 token，权限级收敛待服务内处理（任务书声明权限不迁移）——随签署知悉，非本任务引入。
- [仅供参考] A8-P2 排行昵称回退：`practice_info.created_by` 存 loginId（数字）；auth list-by-identifiers 按 userName 查询不命中时回退 userName（= 数字串）——按契约 fallback 设计，前端阶段二消费时可优化。
- 云端联调证据（GW-1 9/9、A8-P2 全状态机）取自回执声明 + CI 全绿 + 本会话独立复验（69/71/22/SHA）；本机无 Docker 故容器冒烟未本地执行（如实声明，不跳过）。

复核签署：后端评审（B-Review），2026-08-28