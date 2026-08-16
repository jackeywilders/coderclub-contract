# M4-06 提案：SubjectInfoDTO 装饰字段 pageNo/pageSize 收敛

> **提案角色：** 后端评审（B-Review）
> **提案日期：** 2026-08-16
> **任务来源：** `pm/requirements/2026-08-13/m4-06-decorative-fields-task.md`（协调 PM 批准，2026-08-13）
> **遗留依据：** `pm/reviews/2026-08-13/g1-04-close-acceptance.md` 记录事项 3
> **状态：** 待协调 PM 确认方案（确认前不得实施）

## 1. 背景与目标

`SubjectInfoDTO` 列表项（`POST /subject/getSubjectPage` 响应 `data.list` 的元素）携带快照未声明的装饰性 `pageNo`/`pageSize` 字段（G1-04 遗留记录事项 3）。本提案评估两案并给出推荐，消除快照与运行时响应差异。

## 2. 现状事实（2026-08-16 复核）

### 2.1 运行时（后端项目 `main`，提交 `0eac42a`）

- `SubjectInfoDTO extends PageInfo`（`coder-club-subject-common` 的 `PageInfo` 含 `pageNo=1`/`pageSize=20` 字段及兜底 getter），`@AutoMapper(target=SubjectInfoBO.class)`。
- 控制器 `SubjectController.page()`：`POST /subject/getSubjectPage`，请求体 `@RequestBody SubjectInfoDTO`，返回 `ResponseResult<PageResult<SubjectInfoDTO>>`；`list` 元素经 `converter.convert(boList, SubjectInfoDTO.class)` 生成。
- 因继承 `PageInfo`，每个列表项 JSON 序列化时**实际输出 `pageNo`/`pageSize`**（装饰字段）；列表项的分页语义无意义（分页参数在请求体，分页结果在外壳）。

### 2.2 运行时 OpenAPI 源（`docs/api/coderclub-openapi.json`，SHA-256 `7576e28a…`，43/43）

- 请求体 schema 引用 `SubjectPageQueryDTO`（`pageNo`/`pageSize` + `subjectDifficult`/`categoryId`/`labelId`）——**请求侧分页参数已独立声明**。
- 响应外壳 `PageResultSubjectInfo`（`pageNo`/`pageSize`/`total`/`totalPages`/`list`）——**外壳分页字段已声明**。
- `SubjectInfoDTO` schema：`id/subjectName/subjectDifficult/settleName/subjectType/subjectScore/subjectParse/subjectAnswer/categoryIds/labelIds/categoryId/labelId/labelName/optionList`，**未声明 `pageNo`/`pageSize`**。
- 结论：差异点仅在 `list` 元素（`SubjectInfoDTO`）——快照声明无分页字段，运行时实际输出。

### 2.3 前端消费（`CoderClubFront`，main 基线）

- 全仓 `pageNo`/`pageSize` 引用均为**分页请求参数/分页组件状态/响应外壳**（`filters.pageNo`、请求体、`PageResult<T>` 类型外壳）；**没有任何代码访问列表项（`data.list[i]`）的 `pageNo`/`pageSize`**。
- 前端类型 `PageResult<T>` 仅在外壳声明 `pageNo`/`pageSize`，列表项类型未声明该两字段。
- 结论：前端**不消费**列表项装饰字段，移除无破坏性。

### 2.4 测试基线（后端项目）

- `SubjectContractTest` 45/45（G1-04 基线）；当前全量回归 subject 53/53。
- `SubjectContractTest` 中**无**对列表项 `pageNo`/`pageSize` 的断言（grep 无命中）——移除装饰字段不影响既有断言。
- 快照与运行时源一致声明 43 路径 / 43 操作。

## 3. 两案评估

### 案一：声明进契约

将 `pageNo`/`pageSize` 声明进 `SubjectInfoDTO` schema（运行时保持现状）。

- **兼容性影响**：后端无代码改动，运行时行为不变；测试基线 45/45 不受影响；需要 PM 同步 `api/` 快照（`SubjectInfoDTO` 增加两字段），并同步源提交/SHA-256/快照提交/SHA-256/语义差异全链。
- **前端消费影响**：前端不消费该两字段，声明不破坏现有消费；但前端类型若按契约生成，会额外获得无意义字段。
- **风险**：把**无分页语义的装饰字段制度化**进契约——列表项带 `pageNo`/`pageSize` 会误导消费方以为列表项自身支持分页参数；且请求侧已有 `SubjectPageQueryDTO`、外壳已有 `PageResult` 声明分页，契约层面重复且语义错位。契约"如实反映运行时"的收益低于"契约语义正确"的价值。

### 案二：运行时移除

从运行时响应移除 `SubjectInfoDTO` 列表项的 `pageNo`/`pageSize`（快照保持现状）。

- **兼容性影响**：后端需改造响应结构（如列表项改用不含分页字段的视图类型/输出，或序列化忽略继承字段）；请求体分页参数经 `SubjectPageQueryDTO`/请求参数仍完整；`SubjectContractTest` 无相关断言，移除后测试全绿预期（实施后全量回归确认）；快照不变化，无需 PM 同步快照。
- **前端消费影响**：前端不消费列表项该两字段（§2.3），移除零破坏。
- **风险**：改动涉及响应序列化路径，需后端实现谨慎处理请求体（`SubjectInfoDTO` 仍作请求参数承载 `pageNo`/`pageSize`）与响应体（列表项不输出）的分离；实施后需真实响应复核 + `SubjectContractTest` 45/45 回归。

## 4. 两案对照与推荐

| 维度 | 案一：声明进契约 | 案二：运行时移除 |
| --- | --- | --- |
| 快照/运行时差异 | 消除（快照改） | 消除（运行时改） |
| 后端代码改动 | 无 | 有（响应输出路径） |
| 契约语义 | 固化无意义装饰字段（劣） | 保持快照正确语义（优） |
| 前端破坏性 | 无（不消费） | 无（不消费，已核实） |
| 测试影响 | 无 | 预期全绿（无相关断言） |
| PM 快照同步 | 需要（全链哈希） | 不需要 |
| 长期可维护性 | 装饰字段随契约扩散 | 契约与实现语义一致 |

**推荐：案二（运行时移除）。**

理由：
1. `pageNo`/`pageSize` 在列表项上**无分页语义**（分页参数在请求、结果在外壳），属装饰冗余；契约应反映真实语义而非全部运行时输出。
2. 快照当前声明（`SubjectInfoDTO` 无分页字段、`SubjectPageQueryDTO` 承载请求分页、`PageResult` 承载外壳分页）**语义正确**，运行时移除后即可达成一致，无需改动快照（避免全链哈希同步成本与快照变动风险）。
3. 前端与测试均不依赖列表项该两字段（已核实），移除零破坏。

## 5. 影响面清单（案二选定后）

- **后端**：`SubjectInfoDTO` 响应输出路径改造（保留其作为请求参数的 `pageNo`/`pageSize` 能力）；涉及 controller 转换与/或 DTO/序列化配置；`SubjectContractTest` 45/45 回归 + 全量 `mvn test`（subject 53 基线）。
- **契约**：`docs/api/coderclub-openapi.json` 与 `api/` 快照**均不变化**（SHA-256 保持 `7576e28a…` / 快照 `9a97c055…`）；`status/sync-manifest.json` 不变。
- **前端**：无改动、无破坏（不消费列表项装饰字段）。
- **回执**：实施后回执须含真实响应复核（列表项无 `pageNo`/`pageSize`）+ 测试输出 + 快照哈希核验。

## 6. 决策请求

请协调 PM 在本提案上记录决策（选定方案、日期、决策依据）。**未经 PM 确认前，后端实现不得进入实施**。

- 提案角色：后端评审（B-Review）
- 日期：2026-08-16
