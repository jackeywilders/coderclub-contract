# Gate 1 分页一致性后端验收记录

## 验收范围

接口：`POST /subject/getSubjectPage`
代码提交：`06397f444f094a577cfde3f8684ae4f60622e871d`
验证日期：2026-08-10

## 修复前问题

当请求带 `subjectType=99`、`pageSize=5` 时，旧实现可能返回 `data.list=[]`、`data.total=23`、`data.totalPages=5`。根因是 count 查询把题型/难度过滤放在 `LEFT JOIN ... ON` 中，且关联条件使用固定题目 ID；列表查询则在 WHERE 中按实际题目与映射关系过滤。

## 修复后设计

`countByCondition()` 现在使用与分页列表一致的内连接和过滤口径：

- `subject_mapping.subject_id = subject_info.id`；
- `categoryId`、`labelId`、`subjectDifficult`、`subjectType` 均为可选 WHERE 条件；
- `subject_info.is_deleted=0`、`subject_mapping.is_deleted=0` 与列表查询一致。

## 回归证据

| 测试 | 覆盖 | 结果 |
| --- | --- | --- |
| `SubjectInfoServiceImplTest` | count SQL 的 WHERE 过滤、null 分类/标签守卫、非 null 分类/标签 | 3/3 通过 |
| `SubjectInfoDomainServiceImplTest` | 无结果、单页、多页的 `total/list/totalPages` | 3/3 通过 |
| `SubjectContractTest` | Subject HTTP 契约与未登录 401 | 41/41 通过 |

命令：

```powershell
mvn -pl coder-club-subject/coder-club-subject-domain -am '-Dtest=SubjectInfoDomainServiceImplTest,SubjectInfoServiceImplTest' '-Dsurefire.failIfNoSpecifiedTests=false' test
mvn -pl coder-club-subject/coder-club-subject-app/coder-club-subject-app-controller -am '-Dtest=SubjectContractTest' '-Dsurefire.failIfNoSpecifiedTests=false' test
```

## 验收结论

后端代码层面的分页一致性问题已修复，单元和 MockMvc 回归通过；`total`、当前页 `list` 和 `totalPages` 在无结果、单页、多页测试场景一致。尚未连接真实 MySQL 执行 `subjectType=99` 的线上等价请求，PM/Frontend 可在联调环境按原复现参数做最终运行时复核。
