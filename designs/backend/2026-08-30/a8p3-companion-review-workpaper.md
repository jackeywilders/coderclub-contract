# A8-P3-COMPA 阶段三配套——后端评审复核工作底稿

> 角色：后端评审（B-Review）
> 日期：2026-08-30
> 任务书：`pm/requirements/2026-08-30/phase3-companion-implementation-task.md`（PR #102 批次）
> 回执：`handoff/backend-to-frontend/2026-08-30/backend-a8p3-companion-report.md` + `-summary.json`（PR #103，head `d4004ebc`，**已合入 main `59831bc`**）
> 实施：CoderClub PR #16（head `8649eba`，**7 commits**，**本会话复核通过后已合入 main `b15a735`，R2 达成**）
> 提案/决策：PR #101（R2 main）· `pm/reviews/2026-08-30/phase3-companion-proposals-decision.md`（V1-V4/N1-N3 全部确认）

## 1. 人链核验：实施提交存在性与一致性

| 项 | 证据 | 结果 |
| --- | --- | --- |
| 提交对象 | `git rev-parse 8649eba…` 成功（本机 worktree 即停于该提交，B-Impl 遗留状态原状未动）；远端 `feat/backend-a8p3-companion` head 一致 | ✅ |
| CI | PR #16 head `8649eba`：build-and-test ✅ + sensitive-scan ✅（run 33295007263，GitHub API 逐 job 核实；首推 run 33293974452 经修复波重跑） | ✅ |
| 提交数 | GitHub 实计 **7 commits**（spec + plan + 4 实现/文档 + 1 最终审查修复波，回执自身分解即 7）——回执头"8 提交"与 PM 通知"8 commits"为笔误，随签署勘误 | ✅ 勘误 |
| summary 一致性 | `implementationCommitSha=8649eba`、PR #16、`contractSnapshotSha256=DAAEECB7`、`sourceDoc lfSha256After=BF59FECD…` 与回执/快照一致 | ✅ |
| PR #16 合入 | 本会话独立复核（CI 双绿 + 代码级复核 + 独立测试复验全过）后以 merge 方式合入 main（merge `b15a735`，B-Review 授权合入人身份）——**R2 达成** | ✅ |

## 2. 代码级复核（对照回执 §2，实读源码 @ `8649eba`）

| 核对项 | 证据 | 结果 |
| --- | --- | --- |
| **4 副本 VO 同构 +id** | auth 源（`app/entity`）+ circle-api / practice-api / subject-api 四文件各含 `private Long id`（`git grep -c` 逐文件 1/1） | ✅ |
| **auth 控制器 setId（提案字面外必然项）** | `AuthUserController:85` `vo.setId(u.getId())`（手工组装无转换器，缺此行 required 语义不成立——PM 决策已认可，复核确认实现位置正确） | ✅ |
| **双键别名（查找侧零改动）** | circle `AuthUserDirectory:46-47`、practice `PracticeDetailDomainServiceImpl:510-511`：`if (id != null) putIfAbsent(String.valueOf(id), u)`（id 键优先 + null 守卫）后保留 userName 键；查找侧（`nickName(identifier, users)` / rankList `getOrDefault`）零改动 | ✅ |
| **403 映射同形态** | practice handler `:98-100`、subject handler `:118-120`：`@ExceptionHandler(NotRoleException.class)` + `@ResponseStatus(FORBIDDEN)` → `fail(FORBIDDEN.getCode(), "无权限访问")`——与两服务既有权限映射及 circle 先例逐字一致 | ✅ |
| **触及面边界** | `git diff 583b4bb..8649eba --name-only` 共 20 文件；auth 仅 controller + VO + 契约测试 3 文件，**auth domain/infra（X1 查询层）零改动**；contribute nickMap 未动；无新依赖/DDL | ✅ |
| **源文档任务 3** | `IdentifierUserItem` schema `required=["id"]` + 含 id 属性 + `info.description`「74 个路径 74 个操作」；**74 路径不变**（pwsh 独立解析） | ✅ |
| **源-快照 description 一致性** | 源文档（8649eba）与快照 DAAEECB7（`api/coderclub-openapi.json`）`info.description` **区分大小写字节级相等（`-ceq` True）**；快照 74 路径独立确认 | ✅ |
| **LF SHA 独立计算** | `git show 8649eba:docs/api/coderclub-openapi.json \| sha256sum` = `bf59fecd…382b`——与回执 `736F6588→BF59FECD` 逐字一致 | ✅ |

## 3. 独立复验（本底稿复核时执行，附着 `8649eba`；非回执声明转录）

| 命令/动作 | 结果 |
| --- | --- |
| 全量 `mvn install -DskipTests -q`（34 模块） | **exit 0** |
| 定向测试 5 模块（auth 契约 / circle domain / practice 契约+domain / subject 契约） | **exit 0，BUILD SUCCESS，零失败** |
| subject app-controller | **102/102**（SubjectContractTest 73 + GlobalExceptionHandlerTest 11 含 403 用例 + coverage 系） |
| auth app-controller | **46/46**（AuthContractTest 13 含 `$.data[0].id` 断言） |
| practice | app-controller **29/29**（PracticeContractTest 22 + handler 测试 3 含 `@ResponseStatus` 断言）+ domain 40/40（PracticeDetailDomainServiceImplTest 25 含数字 loginId 真实昵称用例） |
| circle domain | **41/41**（**AuthUserDirectoryTest 5/5**：id 键/userName 键/未命中降级/null 跳过/碰撞 id 键优先；三链路 id 键用例 = moment 10 / comment 11 / message 7 较上轮各 +1） |
| 云端联调 | 本批次为消费侧小改（无新端点/新表），云端验证以 PM 验收批次的快照微同步衔接；本会话未重放云端链路（如实声明） |

## 4. 复核结论

**通过，签署。** 回执声明（三任务语义、setId 必然项、双键口径、403 同形态、SHA、description 一致性、测试数字、边界遵守）与人链核验、代码实读、独立复验逐项一致。一处笔误（提交数 8→**7**，回执自身分解即 7）随签署勘误，不影响实质。未发现 [必须修复]/[建议修改] 问题。

## 5. 关联

- 签署：`acceptance/backend/2026-08-30/a8p3-companion-review-signoff.md`
- 提案 PR #101 · 决策（V1-V4/N1-N3）· 任务书 PR #102 · 回执 PR #103 · 实施 CoderClub PR #16（merged `b15a735`）

---
- 复核角色：后端评审（B-Review），2026-08-30
