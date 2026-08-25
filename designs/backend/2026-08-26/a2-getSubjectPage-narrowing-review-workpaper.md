# A2 getSubjectPage 请求体运行时收窄——后端评审复核工作底稿

> 角色：后端评审（B-Review）
> 日期：2026-08-26
> 任务书：`pm/requirements/2026-08-26/getSubjectPage-runtime-narrowing-implementation-task.md`（PR #49 已合入 main）
> 决策：`pm/reviews/2026-08-26/getSubjectPage-schema-alignment-decision.md`（PR #41，案 B/C）
> 提案：`proposals/backend/2026-08-26/getSubjectPage-request-schema-alignment-proposal.md`（PR #40）
> 回执：`handoff/backend-to-frontend/2026-08-26/backend-a2-getSubjectPage-narrowing-report.md` + `-summary.json`（交接仓库 PR #50/#51 合入 main `d286439`）
> 实施分支：`feat/backend-a2-getSubjectPage-narrow`（后端项目 CoderClub，PR #8，head `6b2aedd`）

## 1. 人链核验：实施提交存在性（verification-workflow §5）

| 项 | 证据 | 结果 |
| --- | --- | --- |
| 提交对象存在 | `git cat-file -t 6b2aedd` → `commit`；`git log --oneline -1 6b2aedd` → `6b2aedd refactor(subject): narrow getSubjectPage request body to SubjectPageQueryDTO (A2)` | ✅ |
| 远端 PR 可见（R1） | CoderClub PR #8（open，base main，head `6b2aedd`） | ✅ |
| CI | PR #8 check runs：`build-and-test` success + `sensitive-scan` success | ✅ |
| 与回执声明一致 | 回执 §1 来源表：实施提交 `6b2aedd`、PR #8——逐字一致 | ✅ |

## 2. 代码级复核（对照实施 diff，`main..6b2aedd` 共 4 文件 93+/6-）

| 核对项 | 结果 |
| --- | --- |
| `SubjectController.page` 请求体 `SubjectInfoDTO` → **`SubjectPageQueryDTO`**，保留 `@Validated(value={Groups.PageQuery.class})`（空标记接口，行为不变） | ✅ 本地实读 `SubjectController.java:163` 确认 |
| 显式映射：`converter.convert(subjectPageQueryDTO, SubjectInfoBO.class)`；service/Domain 链路不变（仍收 `SubjectInfoBO`） | ✅ |
| 新 DTO `SubjectPageQueryDTO extends PageInfo`：`@AutoMapper(target=SubjectInfoBO.class)`，自有 4 筛选字段（subjectDifficult/categoryId/labelId/subjectType）+ 继承 pageNo/pageSize = 契约 6 字段 | ✅ |
| BO 目标字段存在性：`SubjectInfoBO` 含 6 字段（pageNo/pageSize 继承 `PageInfo`，默认 1/20——与契约 schema default 一致；subjectDifficult/categoryId/labelId/subjectType 自有） | ✅ 本地实读确认 |
| 行为保持（硬条件）：多余字段（subjectName/settleName/subjectScore 等）由 Jackson 默认 `FAIL_ON_UNKNOWN_PROPERTIES=false` 静默忽略；新增用例显式断言 200 非 400 + 多余字段不进 BO | ✅ diff 含 `getSubjectPage_shouldIgnoreExtraFields_andNotReturn400` |
| 测试适配：既有 page 用例请求体构造/桩适配新 DTO | ✅ diff `doReturn(bo).when(converter).convert(any(SubjectPageQueryDTO.class), eq(SubjectInfoBO.class))` |
| 源文档 description 更新：`SubjectPageQueryDTO.description`「实际绑定 SubjectInfoDTO…」→「getSubjectPage 请求体即本 DTO，6 字段全部参与筛选。」（A2 决策附带条件 2，已批准） | ✅ diff 仅 description 2 行 |
| 边界：不新增端点/字段/鉴权改动；`keyword` 死参数不在本范围（前端 A3 已清理） | ✅ diffstat 仅 4 文件 |

## 3. 独立复验（本底稿复核时执行，附着 `6b2aedd`）

| 命令 | 结果 |
| --- | --- |
| 全量 `mvn install -DskipTests -q`（reactor，先装依赖） | exit 0 |
| `mvn test -pl coder-club-subject/coder-club-subject-app/coder-club-subject-app-controller -Dtest=SubjectContractTest -DfailIfNoTests=false -Dsurefire.failIfNoSpecifiedTests=false` | **Tests run: 52, Failures: 0, Errors: 0, Skipped: 0 — BUILD SUCCESS**（51 基线 + 1 新增行为保持用例） |
| OpenAPI 源文档 SHA-256（LF 字节态，cmd 重定向 git 对象） | before（main `88f7336`）`05933BEA`；after（`6b2aedd`）`A8C6A460` —— 与回执 §5 逐字一致 |
| OpenAPI diff 语义 | 仅 `SubjectPageQueryDTO.description` 文案变更；**无字段/结构/路径/方法变更**；43 paths/43 ops 不变 |
| 工作区换行影响说明 | `core.autocrlf=true` 且无 `.gitattributes` → 工作区文件为 CRLF；SHA 按 LF（git 对象字节态）计算，与交接仓库快照口径一致 |

## 4. 复核结论与备注

- **结论：通过，可签署。**
- 与回执声明（实施内容、52/52 回归、SHA、行为保持、已知限制）逐项一致；未发现 [必须修复] / [建议修改] 问题。
- [仅供参考] 回执 summary `receiptCommitSha: 4bcf820` 早于回执最终修订（`258821e` 补真实请求验证，PR #51 合入 main）——语义上未指向回执终稿提交，属引用类小瑕疵（§8 分级：笔误/引用类，不构成实质不符），建议 B-Impl 后续或 PM 验收时补正；不阻塞签署（核心证据链完整）。
- [仅供参考] 真实请求验证证据（回执 §4 A/B 组：400-401 登录门禁、6 字段筛选 total=28→6、多余字段不 400）取自回执声明 + CI 全绿 + 本会话独立复验 52/52；本复核未重复连接云端中间件（凭据约束，规则 8：不接触真实凭据）。
- [仅供参考] 实施 PR #8 尚未合入 CoderClub `main`（open 状态，CI 全绿）——合入由用户/后端评审按既有流程执行（本次签署不依赖实施合入；签署对象为实施提交 `6b2aedd` 与交接仓库回执的 R2 状态）。

复核签署：后端评审（B-Review），2026-08-26