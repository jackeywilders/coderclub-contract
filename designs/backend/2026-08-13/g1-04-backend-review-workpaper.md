# G1-04 Backend Codex 复核工作底稿

> 角色：Backend Codex
>
> 日期：2026-08-13
>
> 定位：G1-04 复核执行清单（工作底稿）。收到 Claude Code 后端实现提交后，按本底稿从上到下逐项核对并勾选。
>
> 任务来源：`pm/requirements/2026-08-12/g1-04-claude-code-backend-task.md`（PM 批准，Claude Code 后端执行，Backend Codex 复核后写入回执）

## 1. 任务与角色分工

| 事项 | 内容 |
| --- | --- |
| 任务 | G1-04：死代码清理（`SubjectInfoService.page()`）+ 真实数据库分页复核（9 场景） |
| 执行角色 | Claude Code 后端（实现 + 测试 + 本地提交） |
| 复核角色 | Backend Codex（本底稿 + 独立复验 + 写回执） |
| 批准角色 | PM / 跨项目协调 Codex |
| 契约影响 | 无（不改变 HTTP 契约，无需 `proposals/backend/`） |
| 回执路径 | `handoff/backend-to-frontend/2026-08-12/g1-04-claude-code-backend-execution-report.md` |

## 2. 已核验事实基线（复核前静态确认）

### 2.1 死代码位置

- 接口：`coder-club-subject/coder-club-subject-infra/src/main/java/com/jackey/subject/infra/basic/service/SubjectInfoService.java:22`
  `Page<SubjectInfoEntity> page(SubjectInfoEntity info, int start, Long categoryId, Long labelId, Integer pageSize);`
- 实现：`coder-club-subject/coder-club-subject-infra/src/main/java/com/jackey/subject/infra/basic/service/impl/SubjectInfoServiceImpl.java:53-69`
  - 旧实现特征：`leftJoin` + 固定 `info.getId()` 关联、过滤条件写入 ON 子句、无 `is_deleted` 过滤。

### 2.2 无调用者证据

全 subject 模块 grep `.page(`（排除 target）仅命中 domain 层，infra `SubjectInfoService.page()` 无调用者：

| 位置 | 调用对象 |
| --- | --- |
| `SubjectController.java:159` | `subjectInfoDomainService.page(...)`（domain 层） |
| `SubjectContractTest.java:500, 511` | mock `subjectInfoDomainService.page(...)` |
| `SubjectInfoDomainServiceImplTest.java:87` | `service.page(query)`（domain 层） |

### 2.3 真实请求路径（不受清理影响）

`POST /subject/getSubjectPage` → `SubjectController` → domain `page()`（`SubjectInfoDomainServiceImpl.java:75-104`）→ `countByCondition()` + `queryByPage()`；`count == 0` 时提前返回，由 `PageResult` 默认值兜底。

过滤口径（count 与 list 一致）：

- 内连接 `subject_mapping.subject_id = subject_info.id`；
- `categoryId` / `labelId` / `subjectDifficult` / `subjectType` 可选 WHERE；
- 两张表 `is_deleted = 0`。

### 2.4 import 清理预期

| 文件 | 删除 | 保留（勿误删） |
| --- | --- | --- |
| `SubjectInfoService.java`（接口） | `Page` | `List`、`IService`、`SubjectInfoEntity` |
| `SubjectInfoServiceImpl.java` | `Page`、`ObjectUtils`（仅 page() 使用） | ⚠️ `QueryMethods`（`countByCondition()` 使用）、`QueryWrapper`、`SubjectMappingEntity`、`SelectKey`（`add()` 使用） |

### 2.5 测试现状

| 测试 | 覆盖 | 现状 |
| --- | --- | --- |
| `SubjectInfoServiceImplTest` | count SQL 的 WHERE 过滤、null 分类/标签守卫 | 3/3，无 `page` 引用，删除不受影响 |
| `SubjectInfoDomainServiceImplTest` | 无结果、单页、多页的 `total/list/totalPages` | 3/3 |
| `SubjectContractTest` | Subject HTTP 契约 | 45/45（G1-03 后），mock domain 层，不受 infra 删除影响 |

### 2.6 空结果语义（代码级，支撑场景 1）

`PageResult`（coder-club-common）：默认 `pageNo=1`、`pageSize=20`、`total=0`、`list=Collections.emptyList()`；`totalPages` 为派生 getter = `ceil(total/pageSize)`（`pageSize<=0` 或 `total` 为 null 时返回 0）。

### 2.7 契约字段基线（快照 `api/coderclub-openapi.json`）

- `PageResultSubjectInfo` 必填五字段：`pageNo` / `pageSize` / `total` / `totalPages` / `list`（`list` 为 `SubjectInfoDTO[]`）。
- `ResponseResultPageSubjectInfo` 四字段：`success` / `code` / `message` / `data`。

## 3. 死代码清理提交核对点

- [ ] `git show --check <commit>` 通过
- [ ] 提交范围仅 infra 2 个源文件（接口 + 实现），无其他模块 / OpenAPI / 文档变更
- [ ] grep 确认 `.page(` 无 infra 残留
- [ ] import 清理符合 2.4 基线（`QueryMethods` 未误删）
- [ ] 测试命令 1：`mvn -pl coder-club-subject/coder-club-subject-domain -am '-Dtest=SubjectInfoDomainServiceImplTest,SubjectInfoServiceImplTest' '-Dsurefire.failIfNoSpecifiedTests=false' test` → 全通过（3/3 + 3/3）
- [ ] 测试命令 2：`mvn -pl coder-club-subject/coder-club-subject-app/coder-club-subject-app-controller -am '-Dtest=SubjectContractTest' '-Dsurefire.failIfNoSpecifiedTests=false' test` → 45/45
- [ ] 运行时 OpenAPI 源未变化（SHA-256 仍为 `7576e28a346dcf60b304bdd405f0bb82b72252df37e96013509ece00c6a14a2e`，43 paths / 43 operations）

## 4. 真实 DB 九场景核对

### 前置

- [ ] 注册测试账号：`POST {AUTH}/auth/register`（`userName=<test-account>`，`password=<redacted-password>`，`nickName=G1-04 分页复核账号`）
- [ ] 登录取 token：`POST {AUTH}/auth/login` → `data.token`（回执中 token 必须脱敏）
- [ ] 记录服务地址（AUTH/SUBJECT）与 Nacos 环境变量

### 场景表（请求 `POST {SUBJECT}/subject/getSubjectPage`）

| # | 请求体 | 预期 total / list.length / totalPages | 核对 |
| --- | --- | --- | --- |
| 1 | `{"pageNo":1,"pageSize":5,"subjectType":99}` | 0 / 0 / 0 | [ ] |
| 2 | `{"pageNo":1,"pageSize":5,"subjectType":1}` | 4 / 4 / 1 | [ ] |
| 3 | `{"pageNo":1,"pageSize":5,"subjectType":4}` | 12 / 5 / 3 | [ ] |
| 4 | `{"pageNo":2,"pageSize":5,"subjectType":4}` | list.length=5，与第 1 页不重复 | [ ] |
| 5 | `{"pageNo":3,"pageSize":5,"subjectType":4}` | list.length=2，与第 1/2 页不重复 | [ ] |
| 6 | `{"pageNo":1,"pageSize":20,"categoryId":2}` | total 与「按分类过滤的 list 条数」一致（实测确认） | [ ] |
| 7 | `{"pageNo":1,"pageSize":20,"categoryId":2,"labelId":44}` | 1 / 1 / 1 | [ ] |
| 8 | `{"pageNo":1,"pageSize":20,"subjectDifficult":2}` | total 与 list 口径一致 | [ ] |
| 9 | 任选上述响应 | data 五字段 + 外层四字段类型与快照一致 | [ ] |

### 每场景通用核对

- [ ] 记录原始请求 + 原始 JSON 响应（不截断）
- [ ] `total` == 同口径 list 条数
- [ ] `totalPages` == `ceil(total / pageSize)`
- [ ] 多页间 list 不重复（场景 4/5）
- [ ] 若 `subjectType=4` 实测条数与 dump（12）不符：以实测为准，回执记录实际 total

## 5. 回执必含项核对

回执路径：`handoff/backend-to-frontend/2026-08-12/g1-04-claude-code-backend-execution-report.md`（治理规则：日期目录 + 文件名无日期前缀）

- [ ] 来源项目 / 分支、死代码清理提交哈希、回执提交哈希
- [ ] 每场景原始请求与原始 JSON 响应（不截断）
- [ ] 清理前后测试命令与结果（`git show --check` 通过；测试通过数）
- [ ] 契约逐字段核验结论（`PageResultSubjectInfo` 五字段 + `ResponseResultPageSubjectInfo` 四字段）
- [ ] 已知限制（`subjectType=4` 实测差异、服务地址、环境变量）
- [ ] 声明：未修改 `api/` 快照、`status/sync-manifest.json`、前端项目；未伪造验证输出
- [ ] token 脱敏检查

## 6. 关闭条件与失败路径

### 关闭条件（3 条全满足）

| # | 条件 | 状态 |
| --- | --- | --- |
| 1 | 死代码清理提交存在且既有测试全通过 | [ ] |
| 2 | 真实 DB 三场景（无结果 / 单页 / 多页）+ 过滤组合 + 契约字段全部与预期一致 | [ ] |
| 3 | 回执含原始输出与提交哈希，Backend Codex 复核签名 | [ ] |

### 失败路径

- 若 `total` / `list` 口径不一致或契约字段不符 → **G1-04 不关闭**，写入 `proposals/backend/` 或修复后重新验证；环境 / 数据问题修正后重跑。

### 复核完成后动作

- [ ] 更新 `status/backend.json`（`lastCommit` → 实现提交；`sourceSha256` → `7576e28a346dcf60b304bdd405f0bb82b72252df37e96013509ece00c6a14a2e`）
- [ ] 回执提交到 `codex/backend-contract`（本地，不 push，推送需 PM 授权）

## 7. 已知风险

- **双映射重复行**：subject 105 双映射（23 条 mapping / 22 条 subject），count 与 list 均内连接 → 口径一致即通过；若与「去重后条数」不符属语义层面，记录即可，不阻塞关闭。
- `categoryId=2` 实际 total 需实测记录（任务未给固定值）。
- 存量数据零写入（任务禁止插入 / 删除业务测试数据）。
