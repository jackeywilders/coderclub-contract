# G1-04 后端执行任务：死代码清理 + 真实数据库分页复核

> **任务角色：** Claude Code 后端
>
> **批准角色：** PM / 跨项目协调 Codex
>
> **任务日期：** 2026-08-12
>
> **任务状态：** 待 Claude Code 后端执行

## 1. 任务摘要

完成 G1-04 的最后一项关闭条件：**在真实数据库环境复核分页行为**（无结果、单页、多页与过滤组合下 `total`/`list`/`totalPages` 一致性），并在复核前清理遗留死代码 `SubjectInfoService.page()`。

## 2. 前置事实（PM 已核验）

### 2.1 现有代码级证据（已完成，不重复执行）

- 分页修复提交 `06397f444f094a577cfde3f8684ae4f60622e871d`（fix(subject): align pagination count filters）。
- `countByCondition()` 与 `queryByPage()`（`SubjectInfoMapper.xml`）过滤口径一致：内连接 `subject_mapping.subject_id = subject_info.id`，分类/标签/难度/题型/逻辑删除进 WHERE。
- 真实请求路径：`POST /subject/getSubjectPage` → domain `page()` → `countByCondition()` + `queryByPage()`。
- infra 单测 `SubjectInfoServiceImplTest` 3/3、domain 单测 `SubjectInfoDomainServiceImplTest` 3/3 通过（Mockito / SQL 字符串断言，未连真实 DB）。

### 2.2 待清理死代码（任务第一部分）

`SubjectInfoService.page(SubjectInfoEntity, int, Long, Long, Integer)`（接口）与其实现 `SubjectInfoServiceImpl.page(...)`（leftJoin + 固定 `info.getId()` 关联的旧实现）：

- **已确认无任何调用者**（真实请求路径走 domain `page()`，不经过 infra `page()`）。
- **不影响 HTTP 契约**（OpenAPI 路径/方法/字段不变，无需 `proposals/backend/`）。
- 清理范围：删除接口方法声明与实现；同步检查 `SubjectInfoServiceImpl` 中因删除产生的未使用 import（如 `Page`、`QueryMethods` 相关）；确认 `SubjectInfoServiceImplTest`、`SubjectContractTest`、domain 测试编译与通过不受影响。
- 清理后重新运行既有测试：`mvn -pl coder-club-subject/coder-club-subject-domain -am '-Dtest=SubjectInfoDomainServiceImplTest,SubjectInfoServiceImplTest' '-Dsurefire.failIfNoSpecifiedTests=false' test`，以及 Subject Controller 契约测试 `mvn -pl coder-club-subject/coder-club-subject-app/coder-club-subject-app-controller -am '-Dtest=SubjectContractTest' '-Dsurefire.failIfNoSpecifiedTests=false' test`。

### 2.3 真实数据库环境（任务第二部分）

- **PM 已验证运行库 dump**：`docs/database/schema/doc_<jc-club-db>-init.sql`（2024-04-12 导出，源 `<mysql-dump-src>:<mysql-probe-port>`，库 `<jc-club-db>`，MySQL 5.7.44）即当前运行库数据。
- 运行环境依赖 Nacos 动态配置：`NACOS_ADDR=<nacos-dev-addr>:<nacos-port>`、`NACOS_NAMESPACE=<dev-namespace>`；MySQL/Redis 连接以 Nacos 拉取值为准（启动脚本 `start-subject.ps1`、`start-auth.ps1`）。
- **登录账号**：运行库 `auth_user` 全部为微信 openid 用户，`password` 字段为 NULL，**无现成账号密码用户**。需注册测试账号（见第 4 节步骤 1）。

### 2.4 存量数据覆盖度（PM 已盘点，零写入即可覆盖全部场景）

| 表 | 数据 | 覆盖场景 |
| --- | --- | --- |
| `subject_info` | 22 条（type=1 共 4 条 id 328-331；type=2 共 3 条 id 332-334；type=3 共 3 条 id 335-337；type=4 共 12 条 id 100-110、327） | 单页、多页、过滤组合 |
| `subject_mapping` | 23 条（category_id=2/label_id=1 为主；105 双映射 category 2/3 + label 44） | 过滤组合 |
| `subject_category` | id=1 后端、id=2 缓存 | 过滤组合 |
| `subject_label` | id=1 Redis、id=44 数据一致性 | 过滤组合 |

**结论：全部验证场景可用存量数据直接覆盖，无需插入或清理测试数据。**

## 3. 清理 + 验证步骤（按顺序执行）

### 步骤 1：注册测试账号并获取 Token

```
POST {AUTH_SERVICE_URL}/auth/register
{"userName": "<test-account>", "password": "<redacted-password>", "nickName": "G1-04 分页复核账号"}

POST {AUTH_SERVICE_URL}/auth/login
{"userName": "<test-account>", "password": "<redacted-password>"}
→ 取响应 data.token，后续请求头 Authorization: <token>
```

> `AUTH_SERVICE_URL` 为 Auth 服务实际地址（本地启动默认 `http://localhost:3100`，按实际环境调整）。
> `POST /auth/register` 存在（`AuthLoginController`），密码经 `BCryptPasswordEncoder` 加密。

### 步骤 2：清理死代码（见 2.2），提交并记录提交哈希

### 步骤 3：启动 Subject 服务（依赖远程 Nacos/MySQL/Redis），执行真实 DB 验证

对 `POST {SUBJECT_SERVICE_URL}/subject/getSubjectPage` 执行以下场景，**记录原始 JSON 响应**：

| # | 场景 | 请求体 | 预期 |
| --- | --- | --- | --- |
| 1 | 无结果 | `{"pageNo":1,"pageSize":5,"subjectType":99}` | `total=0`, `list=[]`, `totalPages=0` |
| 2 | 单页 | `{"pageNo":1,"pageSize":5,"subjectType":1}` | `total=4`, `list.length=4`, `totalPages=1` |
| 3 | 多页 | `{"pageNo":1,"pageSize":5,"subjectType":4}` | `total=12`, `list.length=5`, `totalPages=3` |
| 4 | 多页第 2 页 | `{"pageNo":2,"pageSize":5,"subjectType":4}` | `list.length=5`, 与第 1 页不重复 |
| 5 | 多页第 3 页 | `{"pageNo":3,"pageSize":5,"subjectType":4}` | `list.length=2`, 与第 1/2 页不重复 |
| 6 | 过滤：分类 | `{"pageNo":1,"pageSize":20,"categoryId":2}` | `total` 与「按分类过滤的列表条数」一致（≥22 条记录范围需实测确认） |
| 7 | 过滤：分类+标签 | `{"pageNo":1,"pageSize":20,"categoryId":2,"labelId":44}` | `total=1`（仅 subject 105 双映射中该组合） |
| 8 | 过滤：难度 | `{"pageNo":1,"pageSize":20,"subjectDifficult":2}` | `total` 与 `list` 过滤口径一致 |
| 9 | 契约字段 | 任选上述响应 | `data` 含 `pageNo/pageSize/total/totalPages/list` 五字段，类型与快照 `PageResultSubjectInfo` 一致（`ResponseResultPageSubjectInfo`：`success/code/message/data`） |

> `subjectType` 取值：1=单选、2=多选、3=判断、4=简答（以运行库实际数据为准，若 type=4 实测数量与 12 不符，以实测为准并在回执中记录实际 total）。
> 每场景同时核对：`total` 与「不带分页条件的同口径 list 条数」一致；`totalPages = ceil(total/pageSize)`。

### 步骤 4：提交回执（Backend Codex 复核后写入）

回执文件：`handoff/backend-to-frontend/2026-08-12/g1-04-claude-code-backend-execution-report.md`，必须包含：

1. 来源项目、分支、**死代码清理提交哈希**与回执提交哈希。
2. 每个场景的**原始请求与原始 JSON 响应**（不截断）。
3. 清理前后的测试命令与结果（`git show --check <commit>` 通过；测试通过数）。
4. 与快照契约逐字段核验结论（`PageResultSubjectInfo` 五字段 + `ResponseResultPageSubjectInfo` 四字段）。
5. 已知限制（如 `subjectType=4` 实际条数与 dump 差异、服务地址、环境变量）。
6. 声明：未修改交接仓库 `api/` 快照、`status/sync-manifest.json`、前端项目；未伪造验证输出。

## 4. 验收边界与关闭条件

- 本任务不改变 HTTP 契约，不产生 `proposals/backend/`。
- 关闭条件（全部满足后 PM 复核关闭 G1-04 并发布 Gate 1 关闭结论）：
  1. 死代码清理提交存在且既有测试全通过。
  2. 真实 DB 下三场景（无结果/单页/多页）+ 过滤组合 + 契约字段全部与预期一致。
  3. 回执含原始输出与提交哈希，Backend Codex 复核签名。
- 若真实 DB 复核发现 `total`/`list` 口径不一致或契约字段不符：**G1-04 不关闭**，问题写入 `proposals/backend/` 或修复后重新验证；环境/数据问题则修正后重跑。

## 5. 禁止事项

- 不得修改后端项目以外的文件；不得修改交接仓库 `api/coderclub-openapi.json`、`status/sync-manifest.json`。
- 不得向运行库插入或删除任何业务测试数据（存量数据已覆盖全部场景）。
- 不得在回执中伪造请求、响应或测试输出。

- 批准角色：PM / 跨项目协调 Codex
- 日期：2026-08-12
