# M1 整改验证记录

> 依据：《2026-07-31-M1公共模块提取-CodeReview报告》v2.0
> 整改范围：Task 1-7（N1-N5 + 设计文档脱节修正）

## 验证结果

执行日期：2026-07-31。以下为实测结果（非计划预期）：

| 项 | 结果 |
|----|------|
| mvn install -DskipTests | BUILD SUCCESS（exit 0） |
| PageResultTest（4 用例） | PASS（Tests run: 4, Failures: 0, Errors: 0, Skipped: 0） |
| AuthUserDomainServiceImplTest（含新增 page 回退） | PASS（Tests run: 4, Failures: 0, Errors: 0, Skipped: 0） |
| AuthRoleDomainServiceImplTest（既有） | PASS（Tests run: 3, Failures: 0, Errors: 0, Skipped: 0） |
| 单测合计（common + auth-domain） | Tests run: 11, Failures: 0, Errors: 0, Skipped: 0, BUILD SUCCESS |
| .error( 残留 | 0 |
| getResult/setResult/setRecords 残留 | 0 |
| 枚举死值引用 | 0 |

说明：三条机械性残留检查（`.error(`、`getResult/setResult/setRecords`、`ResultCodeEnum.INTERNAL_SERVER_ERROR/NOT_ACCEPTABLE`）按原 M1 门禁 grep 命令执行，均无输出（残留 0）。

## N6 顺延说明

OSS `FileController` 的 `/getUrl`、`/testGetAllBuckets` 裸 String 返回、无 `/oss` 前缀、无鉴权，按计划顺延至：
- M3（API 对齐）：补充 `@RequestMapping("/oss")` 前缀、`POST /oss/upload` 契约
- M4（安全加固）：`@SaCheckLogin` + 统一 `ResponseResult` 返回
本整改不处理。
