# P1/P3 后端评审复核工作底稿

> 角色：后端评审（B-Review）
> 日期：2026-08-19
> 任务书：`pm/requirements/2026-08-18/backend-p1-p3-implementation-task.md`
> 决策：`pm/reviews/2026-08-18/p1-p2-p3-interface-decisions.md`（P1=方案 A 补 sort；P3=补 subjectType 声明）
> 回执：`handoff/backend-to-frontend/2026-08-18/backend-p1-p3-implementation-report.md`
> 实施分支：`feat/backend-p1-p3-sort-subjecttype`（后端项目，PR #7）

## 1. 代码级复核（提交 `49067f1`/`8e25e5f`/`6a3af0d`/`914fad3`/`d08faa4`/`13a1d86`/`f964f88`/`ab90f8e`）

### P1 —— 分类 sort 字段
| 核对项 | 结果 |
| --- | --- |
| `SubjectCategoryEntity` 新增 `@Column("sort") Integer sort`（infra） | ✅ |
| `SubjectCategoryBO`/`SubjectCategoryDTO` 新增 `sort`（DTO 无校验注解=非必填） | ✅ |
| `SubjectCategoryAssembler` 双向复制 sort（Entity↔BO） | ✅ 两方向均含 |
| SQL 层 `queryCategory`：`orderBy("sort IS NULL",true).orderBy(sort,true).orderBy(id,true)` — sort 升序、NULL 最后、id 兜底 | ✅ 与设计规格一致 |
| 内存层 `queryTree`：`sortTree` Comparator（NULL→MAX_VALUE + nullsLast(id)）递归排序根与 children | ✅ 与 SQL 层语义一致 |
| 三份建表 SQL 同步 `sort int(11) DEFAULT NULL` | ✅ init.sql / doc_jc-club-init.sql / seed-data |
| 契约 `SubjectCategoryDTO` schema 补 `sort`（integer int32，非必填） | ✅ OpenAPI diff 确认 |

### P3 —— getSubjectPage 契约补 subjectType
| 核对项 | 结果 |
| --- | --- |
| `SubjectPageQueryDTO` schema 补 `subjectType`（integer int32 + example 1） | ✅ |
| 请求示例补 `subjectType: 1` | ✅ |
| 零 Java 行为改动（后端运行时已支持筛选） | ✅ diff 无 SubjectInfoServiceImpl 改动 |

### 测试
| 核对项 | 结果 |
| --- | --- |
| `SubjectContractTest` 新增 sort 透传契约断言（DTO 树含 sort + add sort=7 透传 BO/Entity） | ✅ 46 行新增 |
| `SubjectCategoryServiceImplTest`/`SubjectCategoryDomainServiceImplTest`/`AssemblerTest` 排序断言 | ✅ 各 +22/+26/+33 |
| flaky 修复 `a6e5831`（GlobalExceptionHandlerTest 约束消息断言顺序敏感 → 数量 + containsAll） | ✅ 合理，独立提交未混入 P1/P3 |

## 2. 独立复验（本底稿复核时执行，`feat/backend-p1-p3-sort-subjecttype`）

| 命令 | 结果 |
| --- | --- |
| 全量 `mvn test`（reactor） | **BUILD SUCCESS**（oss 61、auth-app-controller 41、auth-domain 37 等全绿） |
| `mvn test -pl ...app-controller -am -Dtest=SubjectContractTest`（回执命令） | **51/51**，BUILD SUCCESS |
| subject-app-controller 全量（-am） | **79/79**，BUILD SUCCESS |
| OpenAPI SHA-256 | `05933bea`，与回执 §5 一致 |
| OpenAPI 计数 | 43 paths / 43 ops 未变；`SubjectCategoryDTO.sort` + `SubjectPageQueryDTO.subjectType` 均已声明 |

> 注：首次用 `-pl`（不带 `-am`）单模块编译失败（domain/infra 依赖的 sort 未 install 到本地 m2）——属 Maven 模块依赖正常行为（非代码缺陷）；回执命令含 `-am` 为正确用法，复验通过。

## 3. 复核结论与备注

- **结论：通过，可签署。**
- 与回执声明（实现内容、测试数、SHA、已知限制）逐项一致；未发现 [必须修复] / [建议修改] 问题。
- [仅供参考] 已知限制与回执一致：① 前端旧 payload 带 `sort:0` 在补字段后会被真实写入 0（前端需收敛，决策文档已注明）；② 请求 schema 与运行时整段对齐后续单独提案；③ 运行库 `ALTER TABLE` 迁移未执行（待运行环境，无 MySQL 凭据）——已列入回执，PM 同步快照后由运行侧跟进。
- [仅供参考] `sortTree` 的 `Comparator` 用 `Integer.MAX_VALUE` 表示 NULL 排最后，与 SQL 层 `sort IS NULL ASC` 语义等价；两处一致性良好。

复核签署：后端评审（B-Review），2026-08-19
