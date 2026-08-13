# G1-04 正式关闭验收

> **验收角色：** PM / 跨项目协调 Codex
>
> **验收日期：** 2026-08-13
>
> **验收结论：** G1-04 正式关闭（closed）。死代码清理、真实数据库分页复核与回执签署全部完成，Gate 1（G1-01 至 G1-05）随之全部通过。

## 一、关闭依据

本关闭基于任务书 `pm/requirements/2026-08-12/g1-04-claude-code-backend-task.md` 的第 4 节关闭条件，由 Claude Code 后端执行、Backend Codex 复核签署回执后，PM 独立核验证据链并出具本验收。

## 二、证据链核验（PM 独立复核）

### 1. 死代码清理提交（后端仓库实测）

| 项目 | 值 |
| --- | --- |
| 清理提交 | `fad2312`（refactor(subject): 移除无调用者的 SubjectInfoService.page 死代码） |
| 变更范围 | 仅 infra 2 个源文件：接口 −3 行（删 `page(...)` 声明与 `Page` import）、实现 −20 行（删旧 `leftJoin` + 固定 `info.getId()` 实现与 `Page`/`ObjectUtils` import） |
| import 基线 | `QueryMethods`/`QueryWrapper`/`SubjectMappingEntity`/`SelectKey` 保留（`countByCondition()`/`add()` 使用），无误删 |
| 契约影响 | `git show fad2312 -- docs/api/coderclub-openapi.json` 为空；源 SHA-256 `7576e28a…` 不变，43 路径 / 43 操作 |

### 2. 启动脚本修复提交（过程发现处置）

`7c3ac66`（fix(scripts): 启动脚本先安装再运行，避免引用过期 m2 jar）：`start-subject.ps1`/`start-auth.ps1`/`start-oss.ps1` 增加 `mvn install -DskipTests -q -pl <starter> -am` 前置。首轮因本地仓库 2026-08-03 过期 infra jar 导致的 total 全错数据已作废，回执第 3 节完整披露，以下证据均来自新构建。

### 3. 测试重跑（Backend Codex 独立复验）

- `SubjectInfoServiceImplTest` 3/3 + `SubjectInfoDomainServiceImplTest` 3/3，BUILD SUCCESS
- `SubjectContractTest` 45/45，BUILD SUCCESS

### 4. 真实数据库九场景（原始请求/响应 JSON）

任务书场景 1-8 + 6b 交叉验证 + 9 契约字段全部核对：

| 场景 | 预期 | 实测 | 结果 |
| --- | --- | --- | --- |
| 1 无结果（type=99） | total=0 / list=[] / totalPages=0 | 0 / [] / 0 | ✅ |
| 2 单页（type=1） | total=4 / list=4 / totalPages=1 | 4 / 4 / 1 | ✅ |
| 3 多页第 1 页（type=4） | total=12(以实测为准) / list=5 / totalPages=3 | 14 / 5 / 3 | ✅ |
| 4 多页第 2 页 | list=5，与第 1 页不重复 | 5，id 不重复 | ✅ |
| 5 多页第 3 页 | list=2，与第 1/2 页不重复 | 4（14−5−5），不重复 | ✅ |
| 6 过滤-分类（categoryId=2） | total 与 list 口径一致 | total=22，6b 全量 22 条交叉验证 | ✅ |
| 7 过滤-分类+标签（2+44） | total=1 / list=1 / totalPages=1 | 1 / 1 / 1 | ✅ |
| 8 过滤-难度（difficult=2） | total 与 list 口径一致 | 3 / 3 | ✅ |
| 9 契约字段 | `ResponseResultPageSubjectInfo` 四字段 + `PageResultSubjectInfo` 五字段 | 全部一致 | ✅ |

通用核对：`total` == 同口径 list 条数、`totalPages` == `ceil(total/pageSize)`、多页间不重复、空结果语义正确。

### 5. 回执签署与状态刷新

- 回执 `handoff/backend-to-frontend/2026-08-12/g1-04-claude-code-backend-execution-report.md`：来源/分支/提交哈希、每场景原始 JSON、测试命令与结果、契约字段核验、已知限制、声明、Token 脱敏，必含项齐全
- 复核工作底稿 `designs/backend/2026-08-13/g1-04-backend-review-workpaper.md`：Backend Codex 逐项核对并签署（复核结论 7 项）
- `status/backend.json`：`g1-04-backend-evidence-verified`，5 项 g1-04 验证标志全 true
- 签署链：PR !29（执行报告）→ `75835f5`（签署）→ `36ee962`（补回执哈希）→ main `9f32b47`（合入）

## 三、关闭条件逐项核对（任务书 §4）

| 关闭条件 | 状态 | 证据 |
| --- | --- | --- |
| 1. 死代码清理提交存在且既有测试全通过 | ✅ | `fad2312`；3/3 + 3/3 + 45/45 |
| 2. 真实 DB 三场景（无结果/单页/多页）+ 过滤组合 + 契约字段与预期一致 | ✅ | 九场景原始 JSON；type=4 实测 14 条按任务书以实测为准 |
| 3. 回执含原始输出与提交哈希，Backend Codex 复核签名 | ✅ | 回执 §1/§4/§8；工作底稿签署 |

## 四、记录事项（不阻塞关闭，后续评估）

1. **type=4 实测 14 条**（dump 12 条）：运行库含 dump 未列出的新增题（id=338 `feign-chain-verify-20260803-1`），以实测为准。
2. **id=105 双映射重复行**（category 2/3 + label 44）：count 与 list 均内连接、口径一致；与「去重后条数」不符属语义层面，已记录，不阻塞关闭。
3. **装饰性多余字段**：`SubjectInfoDTO` 列表项携带快照未声明的 `pageNo`/`pageSize` 字段（既有行为）。建议后续独立提案评估收敛，本任务不产生契约变更。
4. **首轮过期 m2 jar 事件**：已由 `7c3ac66` 修复启动脚本并披露错误数据作废过程，Backend Codex 复核属实。

## 五、结论与后续

- **G1-04：closed**（2026-08-13）。
- **Gate 1：全部通过并正式关闭**（G1-01 至 G1-05 均 accepted）。
- `releaseStatus` 与 `finalReleaseStatus` 维持 `not-published`，不因 Gate 1 关闭而变更；发布仍受 **Gate 2（M4 后端安全与质量收口）** 与 PM 发布验收约束。
- 遗留移交 M4：`G1-02-FINE-GRAINED-PERMISSION`（后端 openItem，severity medium，细粒度角色/权限矩阵）；装饰字段收敛评估。
- Gate 1 关闭后，前端可基于 PM 批准快照推进已确认范围的开发并进入正式联调，但不得视为发布放行。

- 验收角色：PM / 跨项目协调 Codex
- 日期：2026-08-13
