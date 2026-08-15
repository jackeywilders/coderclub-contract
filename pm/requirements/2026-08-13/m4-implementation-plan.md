# M4 阶段实施计划（任务收口 + Gate 4 发布门禁）

> **面向 AI 代理的工作者：** 必需子技能：使用 superpowers:subagent-driven-development（推荐）或 superpowers:executing-plans 逐任务实现此计划。步骤使用复选框（`- [ ]`）语法来跟踪进度。
>
> **执行角色与边界：** 本计划由 **协调 PM** 在交接仓库 `G:/Dev/backend/Club/coderclub-contract-codex-pm` 执行（分支 `codex/pm-coordination`）。后端业务实现由 **后端实现**在其项目 `G:/Dev/backend/Club/CoderClub` 执行、**后端评审** 复核签署；PM 不得代写后端代码。跨会话分发通过任务书文件路径与任务书内「回执路径」完成。
>
> **参考规格：** `pm/requirements/2026-08-13/m4-task-design.md`（已获用户批准）；任务书模板参考 `pm/requirements/2026-08-12/g1-04-claude-code-backend-task.md`。

**目标：** 按设计规格逐项推进 M4 六项任务（M4-01~06）的任务书 → 分发 → 回执核验 → PM 验收关闭，并建立 Gate 4 发布门禁执行流程（发布状态仅在用户明确授权后变更）。

**架构：** 沿用 G1-04 已验证的逐项独立流程：PM 产出任务书与验收记录，后端实现执行并提交回执，后端评审 复核签署；全部文档按日期目录规则归档（`<类别>/<YYYY-MM-DD>/<文件名>`，文件名无日期前缀）；状态以 `status/*.json` 追踪。

**技术栈：** Git（交接仓库，Gitee 远端）、Markdown 治理文档、JSON 状态文件（node 解析验证）；后端侧由 后端实现使用 Maven/JUnit（本计划仅核验其结果，不执行）。

---

### 任务 0：环境与基线确认

**文件：**
- 读取：`AGENTS.md`、`CLAUDE.md`、`docs/INDEX.md`、`pm/requirements/2026-08-13/m4-task-design.md`、`pm/requirements/2026-08-12/g1-04-claude-code-backend-task.md`（任务书模板）
- 状态：`status/pm.json`、`status/backend.json`、`status/sync-manifest.json`

- [ ] **步骤 1：确认工作区与远端同步**

运行：
```bash
cd "G:/Dev/backend/Club/coderclub-contract-codex-pm"
git status --short --branch
git fetch origin && git merge --ff-only origin/main
```
预期：工作区干净；`codex/pm-coordination` 与 `origin/main` 内容一致（若落后则先合并）。

- [ ] **步骤 2：确认设计规格已提交**

运行：`git log --oneline -3`
预期：包含 `1f139b5 docs(pm): add M4 task design and Gate 4 release gate spec`（若不存在，先补交设计文档再继续）。

- [ ] **步骤 3：确认基线状态**

运行：`node -e "JSON.parse(require('fs').readFileSync('status/pm.json','utf8'))"` 等 4 个状态文件逐一解析。
预期：全部 `OK`；`status/pm.json` 的 `state` 为 `gate0-1-development-contract-accepted-release-pending`，`openFindings` 为空数组。

- [ ] **步骤 4：Commit（如步骤 1 产生了合并）**

```bash
git add -A && git commit -m "merge(main): sync before M4 execution" || echo "nothing to commit"
```

### 任务 1：M4-01 任务书（细粒度角色/权限矩阵）

**文件：**
- 创建：`pm/requirements/2026-08-13/m4-01-fine-grained-permission-task.md`
- 测试：无（Markdown 治理文档，验证方式见步骤 3）

- [ ] **步骤 1：编写任务书**

按 `g1-04-claude-code-backend-task.md` 的结构（任务摘要 / 前置事实 / 步骤 / 验收边界与关闭条件 / 禁止事项）编写，内容取自设计规格 §3 M4-01，必须包含：

- 任务角色：后端实现；批准角色：PM；任务日期：2026-08-13；状态：待执行
- 前置事实：`G1-02-FINE-GRAINED-PERMISSION` 来源（`status/backend.json` openItems）；Auth 已覆盖 `admin_user` 角色与 403 回归；`SubjectContractTest` 45/45 现状；G1-02 统一 401/403 语义（HTTP 状态 + 业务 code + 统一响应体）
- 执行步骤：
  1. 盘点 Subject/Auth 管理端点清单（写/读/管理），输出权限矩阵文档（端点 × 角色 × 匿名/登录/角色/权限）
  2. 配置角色/权限数据并实施鉴权（`@SaCheckPermission` 类策略或等价），补齐管理端点 403 断言
  3. 测试命令：`mvn -pl coder-club-subject/coder-club-subject-app/coder-club-subject-app-controller -am '-Dtest=SubjectContractTest' '-Dsurefire.failIfNoSpecifiedTests=false' test`（预期全绿）及 Auth 侧等价命令
- 回执路径：`handoff/backend-to-frontend/<执行日期>/m4-01-fine-grained-permission-report.md`（回执目录按回执实际创建日期落位，AGENTS.md 第 6 条）
- 关闭条件（全部满足 PM 复核关闭）：① 权限矩阵文档 + 实施提交存在；② 三态（匿名/普通/管理员）401/403 测试通过；③ 回执含原始命令输出与提交哈希，后端评审 签署
- 禁止事项：不得修改交接仓库 `api/` 快照与 `status/sync-manifest.json`；契约字段/路径/方法变更必须先提案

- [ ] **步骤 2：Commit**

```bash
git add pm/requirements/2026-08-13/m4-01-fine-grained-permission-task.md
git commit -m "docs(pm): create M4-01 fine-grained permission task"
```

- [ ] **步骤 3：验证**

运行：`git diff --check && git status --short`
预期：无输出错误；工作区仅剩未提交的新任务书（后续任务依次提交）。

### 任务 2：M4-02 任务书（OSS 访问控制）

**文件：**
- 创建：`pm/requirements/2026-08-13/m4-02-oss-access-control-task.md`

- [ ] **步骤 1：编写任务书**

按任务 1 相同结构，内容取自设计规格 §3 M4-02。必须包含：
- 前置事实：M3 已实现 OSS 真实上传与统一 400（`acceptance/backend/milestones/M3/2026-08-02/M3联调记录.md`）；「接口可用但默认匿名」不确定性待去除
- 执行步骤：盘点 OSS 端点（上传/URL 查询/调试）→ 输出策略文档（每端点明确匿名/登录/角色）→ 实施鉴权 → 鉴权测试（未登录/登录态/越权三态）
- 回执路径：`handoff/backend-to-frontend/<执行日期>/m4-02-oss-access-control-report.md`（回执目录按回执实际创建日期落位，AGENTS.md 第 6 条）
- 关闭条件：① 策略文档 + 实施提交；② 三态测试通过；③ 后端评审 签署回执
- 明确：OpenAPI 与运行时差异须先提案（`proposals/backend/`），不得静默改契约

- [ ] **步骤 2：Commit**

```bash
git add pm/requirements/2026-08-13/m4-02-oss-access-control-task.md
git commit -m "docs(pm): create M4-02 OSS access control task"
```

### 任务 3：M4-03 任务书（凭据与环境收口）

**文件：**
- 创建：`pm/requirements/2026-08-13/m4-03-credential-hardening-task.md`

- [ ] **步骤 1：编写任务书**

内容取自设计规格 §3 M4-03。必须包含：
- 前置事实：启动脚本已改为先安装再运行（后端提交 `7c3ac66`）；`status/backend.json` 的 `apiSourceJwtOrAbsolutePathValues=false`
- 执行步骤（**代码侧**，后端实现）：
  1. grep 全模块明文凭据（密码/密钥/Token），清理脚本与配置文件
  2. 统一配置读取优先级（Nacos → 环境变量 → 本地默认）并文档化
  3. 输出端口策略文档（<subject-port>/<subject-alt-port>、<mysql-probe-port>/<mysql-port> 标准用途）
- **运维侧**（用户/运维职责，任务书仅要求记录）：历史暴露凭据轮换完成记录（由用户提供，后端评审 在回执中引用）
- 回执路径：`handoff/backend-to-frontend/<执行日期>/m4-03-credential-hardening-report.md`（回执目录按回执实际创建日期落位，AGENTS.md 第 6 条）
- 关闭条件：① 无明文凭据（grep 核验 + 提交哈希）；② 配置优先级与端口策略文档；③ 轮换记录引用（或 PM 书面例外）；④ 后端评审 签署

- [ ] **步骤 2：Commit**

```bash
git add pm/requirements/2026-08-13/m4-03-credential-hardening-task.md
git commit -m "docs(pm): create M4-03 credential hardening task"
```

### 任务 4：M4-04 任务书（测试质量门禁）

**文件：**
- 创建：`pm/requirements/2026-08-13/m4-04-test-quality-gate-task.md`

- [ ] **步骤 1：编写任务书**

内容取自设计规格 §3 M4-04。必须包含：
- 执行顺序约束：建议在 M4-01/02/05 完成后再启动验收（作为最终质量基线）；任务书标注「本任务书可先创建，验收启动条件见关闭条件 0」
- 执行步骤：
  1. 实测当前模块覆盖率（`mvn test` + jacoco 或等价），记录基线值
  2. 按设计规格约定目标值（不低于实测基线且不少于 60%，以任务书约定为准）写入任务书
  3. 输出集成测试方案文档（场景/命令/环境，参考 M3 联调记录）
  4. 输出 CI/CD 执行命令与失败处理文档；无外部 CI 时以「本地可重复命令 + 文档化」为最小验收
- 回执路径：`handoff/backend-to-frontend/<执行日期>/m4-04-test-quality-gate-report.md`（回执目录按回执实际创建日期落位，AGENTS.md 第 6 条）
- 关闭条件：① 覆盖率报告达基线；② 集成测试方案文档；③ CI/CD 文档；④ 后端评审 签署

- [ ] **步骤 2：Commit**

```bash
git add pm/requirements/2026-08-13/m4-04-test-quality-gate-task.md
git commit -m "docs(pm): create M4-04 test quality gate task"
```

### 任务 5：M4-05 任务书（非法请求体处理）

**文件：**
- 创建：`pm/requirements/2026-08-13/m4-05-invalid-request-body-task.md`

- [ ] **步骤 1：编写任务书**

内容取自设计规格 §3 M4-05。必须包含：
- 执行步骤：
  1. 构造非法 UTF-8/畸形 JSON 请求（真实 HTTP 调用，记录原始请求与响应）
  2. 确认归类 400（HTTP 400 + 业务 code + 统一响应体，对齐 G1-02 语义）
  3. 补齐全局异常映射测试（异常处理器覆盖非法请求体）
- 回执路径：`handoff/backend-to-frontend/<执行日期>/m4-05-invalid-request-body-report.md`（回执目录按回执实际创建日期落位，AGENTS.md 第 6 条）
- 关闭条件：① 实测 400（原始请求/响应）；② 异常映射测试通过；③ 既有测试全绿；④ 后端评审 签署

- [ ] **步骤 2：Commit**

```bash
git add pm/requirements/2026-08-13/m4-05-invalid-request-body-task.md
git commit -m "docs(pm): create M4-05 invalid request body task"
```

### 任务 6：M4-06 任务书（装饰字段收敛 + 提案引导）

**文件：**
- 创建：`pm/requirements/2026-08-13/m4-06-decorative-fields-task.md`

- [ ] **步骤 1：编写任务书**

内容取自设计规格 §3 M4-06。必须包含：
- 前置事实：G1-04 遗留记录（`pm/reviews/2026-08-13/g1-04-close-acceptance.md` 记录事项 3）；`SubjectInfoDTO` 实测含 `pageNo`/`pageSize` 装饰字段，快照未声明
- 流程（必须先提案后实施）：
  1. **后端评审** 撰写提案 `proposals/backend/<日期>/m4-06-decorative-fields-proposal.md`（后端实现提供运行时实现事实与影响评估输入；选定方案记录在提案文内或 PM 决策中）：评估「声明进契约」vs「运行时移除」两案（兼容性影响、前端消费影响）
  2. PM 确认方案（在提案上记录决策）
  3. 后端实现实施 + 测试（含 `SubjectContractTest` 45/45 回归）
  4. 如涉契约声明：按 `AGENTS.md` 规则 1 同步 `api/` 快照（源提交/SHA-256/快照提交/SHA-256/语义差异全链）
- 回执路径：`handoff/backend-to-frontend/<执行日期>/m4-06-decorative-fields-report.md`（回执目录按回执实际创建日期落位，AGENTS.md 第 6 条）
- 关闭条件：① 提案获 PM 批准（含选定方案）；② 实施提交 + 测试全绿；③ 快照/基线一致（如涉）；④ 后端评审 签署
- 禁止事项：未经 PM 确认方案前不得实施；不得直接修改 `api/` 快照

- [ ] **步骤 2：Commit**

```bash
git add pm/requirements/2026-08-13/m4-06-decorative-fields-task.md
git commit -m "docs(pm): create M4-06 decorative fields task"
```

### 任务 7：任务书交付与分发

**文件：**
- 读取：任务 1-6 创建的 6 份任务书

- [ ] **步骤 1：整体校验任务书集合**

运行：
```bash
cd "G:/Dev/backend/Club/coderclub-contract-codex-pm"
git diff --check
git status --short
```
预期：`git diff --check` 无输出；工作区仅 6 份任务书为未跟踪/已提交状态，无其他杂项。

- [ ] **步骤 2：按序分发（跨会话交接点）**

按设计规格建议顺序 `M4-01 → M4-02/M4-03（并行）→ M4-05 → M4-04 → M4-06 独立并行`，在交接文档/会话说明中通知 **后端实现**与 **后端评审**：
- 分发内容：6 份任务书路径 + 设计规格路径 + 回执路径约定 + 「回执须 后端评审 复核签署」
- 记录分发日期与对象（在 `status/pm.json` 的 `lastAction` 或本计划的进度复选框）
- 预期：后端实现逐项执行并提交回执到 `handoff/backend-to-frontend/<日期>/m4-0X-...-report.md`

- [ ] **步骤 3：Commit（如分发说明写入了交接文档）**

```bash
git add -A
git commit -m "docs(pm): dispatch M4 task books for execution" || echo "nothing to commit"
```

### 任务 8：逐项 PM 验收（每份回执到达后执行一次）

**文件：**
- 创建：`pm/reviews/<回执日期>/m4-0X-close-acceptance.md`（每项一份）
- 修改：`status/backend.json`（后端评审 会先更新，PM 复核后确认）、`status/pm.json`

- [ ] **步骤 1：核验回执（对照任务书关闭条件）**

对每项 M4-0X：
1. 读回执 `handoff/backend-to-frontend/<日期>/m4-0X-...-report.md`，逐条对照任务书关闭条件
2. 交叉核验后端提交存在性（只读）：`git -C "G:/Dev/backend/Club/CoderClub" show <commit> --stat`（如可访问）
3. 核验契约未变：回执中 OpenAPI 源 SHA-256 与 `status/sync-manifest.json` 记录（`7576e28a...`）一致；若有差异须有已批准提案
4. 核验 后端评审 签署存在（回执内签署节 + `status/backend.json` 状态）
预期：全部关闭条件有证据支撑；任一不满足 → 返回 后端评审 补充，不关闭。

- [ ] **步骤 2：编写 PM 关闭验收**

按 `pm/reviews/2026-08-13/g1-04-close-acceptance.md` 结构（关闭依据 / 证据链核验 / 关闭条件逐项核对 / 记录事项 / 结论）编写 `pm/reviews/<日期>/m4-0X-close-acceptance.md`，结论节必须声明「M4-0X closed；发布仍受其余 M4 项与 Gate 4 约束」。

- [ ] **步骤 3：更新状态文件**

```bash
node -e "JSON.parse(require('fs').readFileSync('status/pm.json','utf8'))"
```
编辑 `status/pm.json`：更新 `lastAction` 记录关闭项与证据；`state` 维持 `gate0-1-development-contract-accepted-release-pending` 直至 M4 全部关闭（M4 全部关闭后改为 `gate0-1-m4-accepted-gate4-pending`）。同步确认 `status/backend.json` 已由 后端评审 更新（PM 不代改）。

- [ ] **步骤 4：Commit**

```bash
git add pm/reviews/<日期>/m4-0X-close-acceptance.md status/pm.json
git commit -m "docs(pm): close M4-0X after receipt verification"
```

- [ ] **步骤 5：M4 全部关闭后更新总状态**

当 6 项均关闭：更新 `status/pm.json`（`state=gate0-1-m4-accepted-gate4-pending`）、`pm/roadmap/2026-08-10/pm-coordination-roadmap.md`（Gate 2 状态 → 已收口）并 commit：
```bash
git commit -m "docs(pm): mark M4 (Gate 2) fully accepted"
```

### 任务 9：Gate 4 发布门禁

**文件：**
- 创建：`pm/reviews/<日期>/release-acceptance.md`
- 修改：`status/sync-manifest.json`、`status/pm.json`、`pm/roadmap/2026-08-10/pm-coordination-roadmap.md`

- [ ] **步骤 1：确认触发条件**

核验：① M4 六项 `pm/reviews/<日期>/m4-0X-close-acceptance.md` 全部存在且结论 closed；② Gate 3 前端正式联调回执存在（`handoff/frontend-to-backend/<日期>/...`，由 前端评审 提交）。
任一不满足 → 停止，不进入发布验收。

- [ ] **步骤 2：逐项核对发布检查清单**

按设计规格 §5.2 的 7 项检查清单逐项核对（Gate 0/1 记录、M4 六项验收、前端联调回执、安全项、质量门禁、契约一致性、凭据安全），每项记录证据路径。全部通过才继续；不通过项须先关闭。

- [ ] **步骤 3：获取用户授权（硬性门禁）**

向用户明确请求发布授权（区分「开发契约发布 `releaseStatus`」与「最终发布 `finalReleaseStatus`」）。**未获授权不得变更任何发布状态字段**；记录授权人、授权日期、授权范围。

- [ ] **步骤 4：编写发布验收记录**

编写 `pm/reviews/<日期>/release-acceptance.md`：检查清单逐项核对表 + 授权记录 + 结论（发布放行范围）。

- [ ] **步骤 5：状态变更（仅在授权后）**

```bash
node -e "JSON.parse(require('fs').readFileSync('status/sync-manifest.json','utf8'))"
```
编辑 `status/sync-manifest.json`：`releaseStatus` → `published`（如授权开发契约发布）；`finalReleaseStatus` → `published`（如授权最终发布）。
编辑 `status/pm.json`：`releaseReady` → `true`（`state` 维持 `gate0-1-m4-accepted-gate4-pending` 不变是有意为之，发布状态以 `status/sync-manifest.json` 为准）；`lastAction` 记录授权人/日期/证据。
编辑 `pm/roadmap/2026-08-10/pm-coordination-roadmap.md`：Gate 4 状态 → 已放行。

- [ ] **步骤 6：Commit**

```bash
git add pm/reviews/<日期>/release-acceptance.md status/sync-manifest.json status/pm.json pm/roadmap/2026-08-10/pm-coordination-roadmap.md
git commit -m "docs(pm): complete Gate 4 release acceptance and authorize publish"
```

### 任务 10：收尾与同步

**文件：**
- 修改：`docs/INDEX.md`（如门禁结构变化需要）、`CONTEXT.md`（如发布状态表述变化，仅授权后）

- [ ] **步骤 1：全量验证**

运行：
```bash
cd "G:/Dev/backend/Club/coderclub-contract-codex-pm"
for f in status/*.json; do node -e "JSON.parse(require('fs').readFileSync('$f','utf8'))" || echo "FAIL $f"; done
git diff --check && git status --short
```
预期：4 个 JSON 全部解析通过；`git diff --check` 无输出；工作区干净。

- [ ] **步骤 2：分支同步与交付**

```bash
git fetch origin && git merge --ff-only origin/main || git merge --no-ff origin/main -m "merge(main): sync before M4 delivery"
```
向用户请求推送/PR 授权（沿用既有流程：推送 → 建 PR → 评审/测试门禁 → 无冲突合并 → 分支同步）。

- [ ] **步骤 3：更新本计划进度**

将全部已完成步骤勾选为 `- [x]`，commit：
```bash
git add pm/requirements/2026-08-13/m4-implementation-plan.md
git commit -m "docs(pm): mark M4 implementation plan complete"
```
