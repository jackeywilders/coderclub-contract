# M4-06 后端评审复核工作底稿

> 角色：后端评审（B-Review）
> 日期：2026-08-16
> 任务来源：`pm/requirements/2026-08-16/m4-06-implementation-task.md`（协调 PM 分派）
> 提案与决策：`proposals/backend/2026-08-16/m4-06-decorative-fields-proposal.md`（PM 决策 §7 选定案二运行时移除）
> 回执：`handoff/backend-to-frontend/2026-08-16/m4-06-decorative-fields-report.md`
> 实施提交：`ae2bb7e`（feat(subject): M4-06 运行时移除列表项分页装饰字段 pageNo/pageSize，后端项目 main 本地，特性分支 m4-06-signature-field-removal）

## 1. code-review 双轴结论（提交 `ae2bb7e`，diff `579bcd3...HEAD`）

### 规范轴
- 未发现文档化规范违规（包结构/分层/DTO 注解/统一 ResponseResult/测试风格均符合 AGENTS.md Conventions）。
- 判断性气味 4 条（不影响签署）：
  1. `SubjectInfoViewDTO` 与 `SubjectInfoDTO` 逐字段重复 14 个业务字段（案二既定取舍，javadoc 已说明）；
  2. 新 DTO javadoc 未沿用仓库既有 `@ClassName/@Author/@Version/...` 模板（叙事体）；
  3. 测试类名 `SubjectInfoViewDtoSerializationTest` 的 "ViewDto" 与类名 "ViewDTO" 缩写不一致；
  4. 序列化测试 `json.contains("pageNo")` 子串断言有误报脆弱性。

### 规格轴
- 未发现规格偏差：PM 决策实施要求 1-5 逐项核对（4 端点全部改用 ViewDTO、请求参数能力保留、契约 SHA 不变、SubjectContractTest 适配、回执完整）；无范围蔓延；ViewDTO 14 字段与契约 schema 逐字段同名同型。

## 2. 独立复验（本底稿复核时执行，后端项目 `ae2bb7e`）

| 验证项 | 结果 |
| --- | --- |
| subject-app-controller 全量测试 | **77/77**（SubjectContractTest 49 + SubjectInfoViewDtoSerializationTest 2 + GlobalExceptionHandlerTest 10 + GlobalExceptionMappingTest 2 + CoverageTest 3+3+4 + FeignConfigTest 2 + 配置测试 2），BUILD SUCCESS |
| SubjectContractTest | 49/49（回执声明一致） |
| 新增序列化测试 | SubjectInfoViewDtoSerializationTest 2/2（视图序列化不含 pageNo/pageSize + 请求体仍可反序列化） |
| 后端 OpenAPI 源 SHA-256 | `7576e28a346dcf60b304bdd405f0bb82b72252df37e96013509ece00c6a14a2e` 未变（43/43） |
| diff 契约文件 | `579bcd3...HEAD` 无 openapi/sync-manifest/api 文件变更 |

## 3. 代码要点复核

- `SubjectInfoViewDTO implements Serializable`（不继承 `PageInfo`），`@AutoMapper(target=SubjectInfoBO.class)`，14 业务字段与契约 schema 一致。
- `SubjectController`：`list()`/`getInfo()`/`querySubjectInfo(id)`/`page()` 4 个读端点响应类型全部改为 ViewDTO；请求体仍为 `SubjectInfoDTO`（继承 PageInfo，分页参数能力保留）。
- 未改变任何契约字段/路径/方法。

## 4. 复核结论与备注

- **结论：通过，可签署。**
- 与回执声明（测试 77、响应体结构、SHA 不变、4 端点改造）逐项核对一致；未发现 [必须修复] / [建议修改] 问题。
- 上述规范轴 4 条气味均为 [仅供参考] 级别：字段重复为案二既定取舍（可后续以组合/继承优化）；javadoc 模板、类名缩写、子串断言不影响本次功能正确性，已记录备查，不建议阻塞合入。
- 已知限制与回执一致：前端不消费列表项两字段（提案 §2.3 核实）零破坏；请求侧装饰字段保留为预期行为。

复核签署：后端评审（B-Review），2026-08-16
