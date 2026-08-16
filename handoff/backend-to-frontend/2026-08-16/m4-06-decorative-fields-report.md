# M4-06 后端执行报告：装饰字段运行时移除

> **任务角色：** 后端实现（B-Impl）
> **任务来源：** `pm/requirements/2026-08-16/m4-06-implementation-task.md`（协调 PM 批准，2026-08-16）
> **复核角色：** 后端评审（B-Review）
> **报告日期：** 2026-08-16
> **契约影响：** 无（运行时移除装饰字段，不改变契约字段/路径/方法）

## 1. 来源与提交哈希

| 项目 | 值 |
| --- | --- |
| 来源项目 | `G:/Dev/backend/Club/CoderClub` |
| 来源分支 | `main`（特性分支 `m4-06-signature-field-removal` → PR） |
| 实施提交哈希 | `ae2bb7e`（feat(subject): M4-06 运行时移除列表项分页装饰字段 pageNo/pageSize） |
| 回执提交哈希 | `494e862`（docs(handoff): M4-06 装饰字段运行时移除执行回执） |

## 2. 提案编号与 PM 确认记录

- **提案**：`proposals/backend/2026-08-16/m4-06-decorative-fields-proposal.md`
- **PM 决策（提案 §7，2026-08-16）**：选定**案二（运行时移除）**——从运行时响应移除 `SubjectInfoDTO` 列表项的装饰性 `pageNo`/`pageSize`；契约快照保持现状（`api/coderclub-openapi.json` SHA `9a97c055…` 不变，无需同步快照）。
- **实施要求**：任务书 §3 实施要求 1-5（本回执逐项覆盖）。

## 3. 后端改造实现

**方案**：`SubjectController` 的响应端点改用响应视图 `SubjectInfoViewDTO`——字段与 `SubjectInfoDTO` 一致但**不继承** `PageInfo`，因此序列化时不再输出 `pageNo`/`pageSize` 装饰字段。

- 新建 `app/entity/SubjectInfoViewDTO.java`（`@AutoMapper(target=SubjectInfoBO.class)`，字段含 id/subjectName/subjectDifficult/settleName/subjectType/subjectScore/subjectParse/subjectAnswer/categoryIds/labelIds/optionList/categoryId/labelId/labelName）。
- `SubjectController`：`list()`→`List<SubjectInfoViewDTO>`、`getInfo()`（POST /querySubjectInfo）→`SubjectInfoViewDTO`、`querySubjectInfo()`（GET /querySubjectInfo/{id}）→`SubjectInfoViewDTO`、`page()`（getSubjectPage）→`PageResult<SubjectInfoViewDTO>`。
- **请求参数能力保留**：请求体仍用 `SubjectInfoDTO`（继承 `PageInfo`，可承载 `pageNo`/`pageSize`），分页请求不受影响。
- **未改变契约**：响应 `SubjectInfoDTO` schema 本无分页字段，运行时移除后与契约一致；未改字段/路径/方法。

## 4. 测试命令与原始输出

### 4.1 新增测试（视图序列化契约）

```bash
mvn test -pl coder-club-subject/coder-club-subject-app/coder-club-subject-app-controller -Dtest=SubjectInfoViewDtoSerializationTest
```
输出：`Tests run: 2, Failures: 0, Errors: 0, Skipped: 0 / BUILD SUCCESS`
- viewDtoSerialize_shouldNotIncludePageNoPageSize：视图序列化 JSON 不含 pageNo/pageSize ✅
- requestDtoDeserialize_shouldStillAcceptPageNoPageSize：SubjectInfoDTO 请求体仍可反序列化 pageNo/pageSize ✅

### 4.2 `SubjectContractTest` 回归 + 全量

```bash
mvn test
```
输出：全模块 BUILD SUCCESS，无 Failures/Errors；其中 subject-app-controller `Tests run: 77`（含 `SubjectContractTest` 49/49），oss 61、auth-domain 37、auth-app-controller 41 全绿。

> 任务书要求 `SubjectContractTest` 45/45 基线：现状为 49/49（G1-04 后扩展至 49），适配响应视图后无回归（断言改为对 `SubjectInfoViewDTO` 的 list 元素）。

## 5. 真实响应复核（Nacos dev 环境）

- **请求**：`POST /subject/getSubjectPage`，`Content-Type: application/json`，带登录 token，body `{"pageNo":1,"pageSize":10}`。
- **响应**（`data.list` 首元素）：`{"id":100,"labelName":["Redis","数据一致性","MySQL","算法基础"],"optionList":[],"subjectDifficult":1,"subjectName":"Redis支持哪几种数据类型？","subjectParse":"…","subjectScore":1,"subjectType":4}`
- **核验**：`data.list` 元素字段为 `id/labelName/optionList/subjectDifficult/subjectName/subjectParse/subjectScore/subjectType`，**不含 `pageNo`/`pageSize`** ✅
- **分页仍生效**：外壳 `data.pageNo=1`、`data.pageSize=10`、`total=28`、`listSize=10` ✅

## 6. 契约 SHA 核验

| 项 | SHA-256 | 结论 |
| --- | --- | --- |
| 后端 `docs/api/coderclub-openapi.json` | `7576e28a…`（43/43） | **未变 ✅** |
| 交接仓库 `api/coderclub-openapi.json` 快照 | `9a97c055…`（LF） | **未变 ✅**（未修改） |
| `status/sync-manifest.json` | — | **未变 ✅**（git status 无变更） |

## 7. 已知限制

- 仅覆盖 `SubjectInfoViewDTO` 所列业务字段；若后续字段增改需同步视图 DTO。
- 分页装饰字段在请求侧（`SubjectInfoDTO` 继承 `PageInfo`）仍保留（预期：请求参数能力保留）。
- 前端未消费列表项该两字段（提案 §2.3 已核实），移除零破坏。

## 8. 声明

- 未修改交接仓库 `api/coderclub-openapi.json` 快照与 `status/sync-manifest.json`（git status 确认无变更）。
- 未改变已批准契约的字段/路径/方法；提交消息与回执未写真实环境信息（规则 8）。
- 所有测试输出、真实响应与提交哈希为真实结果，未伪造。

## 9. 后端评审复核签署（待复核）
- [ ] （待后端评审复核后签署）
