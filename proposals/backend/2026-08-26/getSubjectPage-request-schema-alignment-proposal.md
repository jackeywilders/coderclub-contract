# 提案：getSubjectPage 请求 Schema 整段对齐

> **提案角色：** 后端评审（B-Review）
> **提案日期：** 2026-08-26
> **任务书：** `pm/requirements/2026-08-26/getSubjectPage-schema-alignment-proposal-task.md`（协调 PM，PR #39 已合入）
> **来源：** P3 决策附件项（`pm/reviews/2026-08-18/p1-p2-p3-interface-decisions.md` §P3：请求 schema 与运行时整段对齐后续单独提案）
> **状态：** 待协调 PM 确认方案（确认前不得实施；实施阶段由 PM 在 A3 合入后另行派发）

## 1. 现状事实（2026-08-26 复核）

### 1.1 契约侧（快照 `0DAE8D3A`，源 `05933BEA`）

- `getSubjectPage` 请求体引用 **`SubjectPageQueryDTO`**（6 字段）：`pageNo`/`pageSize`/`subjectDifficult`/`categoryId`/`labelId`/`subjectType`
- `SubjectInfoDTO` schema（契约中）：14 字段（id/subjectName/subjectDifficult/settleName/subjectType/subjectScore/subjectParse/subjectAnswer/categoryIds/labelIds/categoryId/labelId/labelName/optionList）

### 1.2 运行时侧（后端 main，来源提交 `6a5daff` / `fad2312` / `f964f88`）

- `SubjectController.page`（`SubjectController.java` @ `6a5daff`）：`@RequestBody @Validated(PageQuery) SubjectInfoDTO` → 接收**全量字段**（宽入）
- 实际消费（service 链路）：
  - `SubjectInfoDomainServiceImpl.page`：仅用 `pageNo`/`pageSize`（分页）+ `categoryId`/`labelId`（透传筛选）
  - `SubjectInfoServiceImpl.countByCondition`（@ `fad2312`）：按 `subjectDifficult`/`subjectType`（非空时）+ `categoryId`/`labelId` + `isDeleted` 筛选
  - `SubjectInfoMapper.queryByPage`（XML）：`categoryId`/`labelId` 条件
- **结论**：运行时实际生效的筛选字段 = `pageNo`/`pageSize`/`subjectDifficult`/`subjectType`/`categoryId`/`labelId`——与契约 `SubjectPageQueryDTO` 6 字段**逐字一致**；`SubjectInfoDTO` 的其余字段（subjectName/settleName/subjectScore 等）在 page 链路**不参与筛选**，属冗余宽入。

### 1.3 前端侧（CoderClubFront main）

- `SubjectList.vue`：queryParams 传 `keyword`/`subjectType`/`subjectDifficult`/`categoryId`/`pageNo`/`pageSize`
- `SubjectBrowse.vue`：filters 传 `categoryId`/`subjectType`/`subjectDifficult`/`pageNo`/`pageSize`
- **发现死参数**：前端 `keyword`（标题搜索）在运行时**无对应筛选**（countByCondition/queryByPage 均无 subjectName 条件），当前被后端静默忽略——不在本提案范围（端点边界），但记录备查，建议前端在 A3 收敛时移除或后续单独提案补 subjectName 搜索。

## 2. 案 A：契约对齐运行时（改引用 SubjectInfoDTO）

将 `getSubjectPage` 请求体 schema 从 `SubjectPageQueryDTO` 改为引用 **`SubjectInfoDTO`**（全量 14 字段），文档与实现一致。

- **来源提交**：契约源 `f964f88`；运行时 `6a5daff`
- **兼容性影响**：
  - 前端：现传参（6 筛选字段）是 `SubjectInfoDTO` 的子集，**全部继续有效**，无破坏
  - 契约语义：请求体暴露 14 字段但仅 6 个参与筛选——**契约比实现"宽"**，把冗余宽入制度化
  - 快照：需 PM 同步（`getSubjectPage` 请求 schema 引用改为 `SubjectInfoDTO`，语义差异 +1 处引用变更）；`SubjectPageQueryDTO` 仍被其他端点使用与否需核（当前仅 getSubjectPage 引用）
- **建议方案**：直接改引用；保留 `SubjectPageQueryDTO`（若仍被使用）或清理
- **验证方式**：OpenAPI 源更新 → SHA 记录；`SubjectContractTest` 回归；真实请求（筛选字段生效、全量字段容忍）

## 3. 案 B：运行时收窄对齐契约（controller 改收窄请求体）

将 `SubjectController.page` 请求体从 `SubjectInfoDTO` 改为 **`SubjectPageQueryDTO`**（或等价的窄 DTO），实现与契约一致。

- **来源提交**：运行时 `6a5daff`（controller）→ 需新提交；契约 `f964f88`
- **兼容性影响**：
  - 后端：controller 签名改 `SubjectPageQueryDTO`；converter 转换目标调整（`SubjectPageQueryDTO` → BO 需字段映射）；`@Validated(PageQuery)` 分组保留；service 层接口不变（仍收 BO）——改动集中在 controller + 可能新增 assembler/映射
  - 前端：现传参 6 字段 = 契约 6 字段，**继续有效，无破坏**（`keyword` 本就无效，不受影响）
  - 测试：`SubjectContractTest` 中 page 相关用例的请求体类型断言需适配（如 mock `@RequestBody` 类型）
  - 快照：**不需要变更**（契约已声明 `SubjectPageQueryDTO`）
- **建议方案**：controller 改用 `SubjectPageQueryDTO`，converter 显式映射 6 字段 → BO
- **验证方式**：`SubjectContractTest` 回归（51/51 基线）+ 真实请求（6 字段筛选生效、`subjectName` 等不再被接受/忽略）

## 4. 案 C（第三案，推荐候选）：独立查询 DTO —— `SubjectPageQueryDTO` 维持 + 运行时对齐

**实质即案 B 的变体**：以契约 `SubjectPageQueryDTO` 为"唯一真源"，运行时收窄到该 DTO，并在 service/domain 层以显式映射落地。

- 与案 B 等价，但强调**契约先行**（不新增 schema、不改契约、快照零变更），契约 6 字段即运行时 6 字段，语义最小且无冗余
- 额外收益：前端 `keyword` 死参数在 A3 收敛时按契约 6 字段对齐（前端侧移除或后端补 subjectName——后者单独提案）

## 5. 两案对照与推荐

| 维度 | 案 A：契约对齐运行时 | 案 B/C：运行时对齐契约 |
| --- | --- | --- |
| 契约/运行时一致 | 一致（但契约暴露冗余字段） | 一致（窄、精确） |
| 快照影响 | **需 PM 同步**（引用改 SubjectInfoDTO） | **零变更**（契约不动） |
| 后端改动 | 无代码改动 | controller 收窄 + 映射（中等） |
| 前端破坏性 | 无 | 无（现传参=契约 6 字段） |
| 契约语义 | 宽（14 字段仅 6 生效）—— 把"宽入但忽略"制度化 | 窄（6 字段全生效）—— 契约即真相 |
| 长期可维护 | 差（契约误导消费方字段可用性） | 好（契约=实现=前端对齐） |

**推荐：案 B/C（运行时收窄对齐契约，`SubjectPageQueryDTO` 为唯一请求 schema）。**

理由：
1. **契约即真相原则**：`SubjectPageQueryDTO` 6 字段与运行时实际生效筛选字段**逐字一致**（1.2 节），契约本来就是"正确声明"；案 A 反而把 8 个冗余字段写进契约，误导前端以为可传 subjectName/subjectScore 等筛选（实际被忽略）。
2. **零快照变更**：案 B/C 不动契约 → PM 无需重新同步快照全链（对比案 A 需 +1 语义差异与全链哈希更新），避免前端基线再次漂移（与并行说明"避免前端基线反复更新"一致）。
3. **前端无破坏**：现传参即契约 6 字段；`keyword` 死参数属前端侧清理，A3 收敛时一并处理。
4. 改动集中在 controller 收窄 + 显式映射，影响面小、测试基线明确（`SubjectContractTest` 51/51 回归可验证）。

## 6. 快照影响标注

- 若采纳**案 A**：`api/coderclub-openapi.json` 快照需 PM 同步——`getSubjectPage` 请求体引用 `SubjectPageQueryDTO` → `SubjectInfoDTO`，语义差异预估 +1（引用变更，无字段级破坏）；`SubjectPageQueryDTO` schema 若不再被引用需评估保留/清理。
- 若采纳**案 B/C**（推荐）：**快照零变更**（`0DAE8D3A` 维持），无需同步。

## 7. 边界与流程

- **边界**：本提案只针对 `getSubjectPage` 请求 schema；不扩大到其他端点。前端 `keyword` 死参数仅记录备查（A3 收敛范围），不在此实施。
- **流程**：PM 确认方案 → 实施阶段另行派发 B-Impl（待前端 A3 合入后，避免前端基线反复更新）→ 实施回执按规则 9 双轨。
- **提交/PR**：本提案经 `codex/backend-contract` PR 合入交接仓库 main（governance-check 自动合并），提交/PR 无真实环境信息（规则 8）。

- 提案角色：后端评审（B-Review）
- 日期：2026-08-26
