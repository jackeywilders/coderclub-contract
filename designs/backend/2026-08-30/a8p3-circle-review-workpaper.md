# A8-P3-BE circle 社区域——后端评审复核工作底稿

> 角色：后端评审（B-Review）
> 日期：2026-08-30
> 任务书：`pm/requirements/2026-08-29/phase3-circle-implementation-task.md`（PR #95）
> 回执：`handoff/backend-to-frontend/2026-08-30/backend-a8p3-circle-domain-report.md` + `-summary.json`（PR #97，head `101b900`）
> 实施：CoderClub PR #15（head `d9eb64f`，18 commits，**本会话复核通过后已合入 main `583b4bb`，R2 达成**）

## 1. 人链核验：实施提交存在性与一致性（verification-workflow）

| 项 | 证据 | 结果 |
| --- | --- | --- |
| 提交对象 | `git rev-parse d9eb64fb51c7ee5f22c947b4ee77c34574d38a1c` 成功（本机 worktree 即停于该提交，B-Impl 会话遗留状态，原状未动）；远端分支 `feat/backend-a8-p3-circle` head 一致 | ✅ |
| CI | PR #15 head `d9eb64f`：`build-and-test` ✅ success + `sensitive-scan` ✅ success（run 33267186300，GitHub API 逐 job 核实） | ✅ |
| 提交数 | GitHub PR 实计 **18 commits**（3 携带：`.apifox` gitignore / spec / plan + 15 实现，含 3 轮修复）——回执"17 提交：3 携带 + 14 实现"为笔误，随签署勘误（不影响 head SHA 与 CI 对应关系） | ✅ 勘误 |
| summary 一致性 | `implementationCommitSha=d9eb64f`、`pullRequestNumber=15`、`contractSnapshotSha256=2583b906`（零漂移）、`sourceDoc lfSha256Before/After` 与回执逐字一致 | ✅ |
| PR #15 合入 | 本会话独立复核（CI 全绿 + 代码级复核 + 独立测试复验全过）后以 merge 方式合入 main（merge `583b4bb`，B-Review 授权合入人身份）——**R2 达成** | ✅ |

## 2. 代码级复核（对照回执 §2 逐条，实读源码 @ `d9eb64f`）

| 核对项 | 证据 | 结果 |
| --- | --- | --- |
| **DFA 方案 A′** | `SensitiveWordDomainServiceImpl:22` `private volatile WordContext context`（不可变快照引用，DCL 惰性加载）；`WordContext` 构建后不可变、白词节点 isWhiteWord 标记；不做原地 addWord/removeWord（YAGNI） | ✅ |
| **X3 角色鉴权 403** | `SensitiveWordsController:34/:43` 两端点 `@SaCheckRole("admin_user")`；`CircleSaTokenConfigure`（roleKeys 会话解析，subject 先例）+ `SaTokenWebConfig` SaInterceptor 注册（`addPathPatterns("/**")`）；`GlobalExceptionHandler:100` `@ExceptionHandler(NotRoleException.class)` → 403（本系统首个实际生效的角色注解端点） | ✅ |
| **消息 from==to 不落 + 读取即已读** | `ShareMessageDomainServiceImpl:54` `Objects.equals(fromId,toId) → return false`；`:56` is_read 显式置 2；`:59` 中性文案（COMMENT→"评论了你的动态"/REPLY→"回复了你的评论"）；`:85-87` 返回前按页内 ids 批量置已读 + **空页守卫**（防 `id in ()` SQL 语法错误）；unRead 只计数不改状态 | ✅ |
| **评论计数按实际行数回减** | `ShareCommentDomainServiceImpl:175-176` `int affected = softDeleteByIds(subtree)` → `incrReplyCount(momentId, -affected)`（用返回值而非集合大小，同事务） | ✅ |
| **归属/越权** | `ShareMomentDomainServiceImpl:115` 非本人 400「无权删除」+ 事务内级联软删；`ShareCommentDomainServiceImpl:159` `!isCommentOwner && !isMomentAuthor → 400`；删除查无/已删幂等 true | ✅ |
| **X1 向后兼容** | `AuthUserDomainServiceImpl:85-110` 两查询合并：`user_name IN 全部` ∪ `id IN 数字子集`，按 id 去重；超长数字串（parseLong 失败）仅参与 name 匹配不抛异常；请求/响应结构零变化 | ✅ |
| **X2 向后兼容** | `SubjectInfoDomainServiceImpl:87-97` 可选 `primaryCategoryId` → `listIdsByPrimary`（大类自身+直接子分类）→ `listSubjectIdsByCategoryIds`（subject_mapping）→ 注入 count/list 双路径；null 走原路径零影响；空集短路空页 | ✅ |
| **圈子树缓存** | `ShareCircleDomainServiceImpl:36` `@Cacheable(cacheNames="circle:tree")`（Caffeine TTL 30s，yaml spec 配置）；两层树组装 | ✅ |
| **11 端点契约登记** | source doc 74 路径逐一存在（含 circle 11 + X1/X2 语义补充）；快照 `2583b906` 零漂移 | ✅ |

## 3. 独立复验（本底稿复核时执行，附着 `d9eb64f`；非回执声明转录）

| 命令/动作 | 结果 |
| --- | --- |
| 全量 `mvn install -DskipTests -q`（34 模块含新 circle） | **exit 0** |
| 定向测试 6 模块（circle 契约+domain / auth 契约+domain / subject 契约+domain）`mvn test` | **exit 0，BUILD SUCCESS，零失败** |
| `CircleContractTest` | **20/20**（11 端点正例 + 401/403/400 矩阵 + 幂等） |
| circle domain 单测 | **33/33**（WordFilter 4 + 敏感词域 4 + 评论 10 + 消息 6 + 动态 9；回执分解写"圈子 1+评论 9"实为"评论 10"，总数 33 正确——笔误勘误） |
| `AuthContractTest` | **13/13**（auth-app 全模块 46/46）；auth domain **40/40**（含 X1 三用例） |
| `SubjectContractTest` | **73/73**（surefire 报告核实；subject domain 全绿零失败，含 X2 展开/短路用例） |
| 源文档 LF SHA-256（`git show` 字节态独立计算） | before（`2cf74d0`）`9ec37c66…9d4d` → after（`d9eb64f`）`736f6588…3225`——与回执 §4 逐字一致 |
| 路径/schema 计数（pwsh ConvertFrom-Json 独立解析） | **63→74 路径、96→117 schema**——与回执一致 |
| 云端 6 步联调 | 取自回执 §5 声明 + CI 全绿 + 本会话复验佐证；云端环境本会话未重放（如实声明，不跳过） |

## 4. 复核结论

**通过，签署。** 回执声明（11+2 端点、DFA A′、X3 403、消息语义、计数口径、X1/X2 兼容、SHA、路径数、测试数字、云端 6 步）与人链核验、代码实读、独立复验逐项一致。两处笔误（提交数 17/14→18；domain 分解"圈子 1+评论 9"→"评论 10"）随签署勘误，不影响实质。未发现 [必须修复]/[建议修改] 问题。

## 5. 关联

- 签署：`acceptance/backend/2026-08-30/a8p3-circle-domain-review-signoff.md`
- 开放项处置：C1 与 NotRoleException 映射 → 配套提案任务书（PR #99，B-Review 起草中）

---
- 复核角色：后端评审（B-Review），2026-08-30
