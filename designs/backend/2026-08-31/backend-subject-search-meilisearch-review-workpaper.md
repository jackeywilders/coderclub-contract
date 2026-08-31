# SUBJECT-SEARCH-MEILISEARCH subject 搜索升级 Meilisearch——后端评审复核工作底稿

> 角色：后端评审（B-Review）
> 日期：2026-08-31
> 任务书：`pm/requirements/2026-08-31/subject-search-meilisearch-task.md`；grill 共识（Meilisearch 引入/降级 LIKE/写后同步 + 重建/ES 移除）
> 回执：`handoff/backend-to-frontend/2026-08-31/backend-subject-search-meilisearch-report.md` + `-summary.json`（PR #153，merge `5ce79b1`；回执 `2be6316` + receiptCommitSha 修正 `c06fc70`）
> 实施：CoderClub PR #22（head `73b98ea`，9 commits；**本会话复核通过后已合入 main `dc0dd284`，R2 达成**）

## 1. 人链核验：实施提交存在性与一致性

| 项 | 证据 | 结果 |
| --- | --- | --- |
| 提交对象 | `git cat-file -t 73b98ea` 成功（走 7892 代理 fetch `feat/subject-search-meilisearch`）；远端 PR #22 head 与本地对象一致 | ✅ |
| CI | PR #22 head `73b98ea`：build-and-test ✅（job 99595739795，run 33424822450）+ sensitive-scan ✅（job 99595739380）——GitHub API 逐 job 核实 | ✅ |
| 提交数 | **9 commits**（spec + plan + S1 依赖 + S2 索引/文档 + S3 端点 + S4 同步/重建 + 3 审查修复波）——与回执一致 | ✅ |
| summary 一致性 | `implementationCommitSha=73b98ea`、`receiptCommitSha=2be6316`（+ 修正 c06fc70）、PR #22、pathCount 75→75 一致；源 SHA 26AEC009 系基线过期值（PM 注记采纳，本批 openapi 零变更，当前源实测 57C2D6EE） | ✅ |
| PR #22 合入 | 本会话独立复核（CI 双绿 + 代码级复核 + 本地全量测试复验全过）后以 merge 方式合入 main（merge `dc0dd284`，B-Review 授权合入人身份）——**R2 达成**（main tip 核验 `dc0dd284`） | ✅ |

## 2. 代码级复核（对照任务书 S1-S5 与规格，实读源码 @ `73b98ea`）

| 核对项 | 证据 | 结果 |
| --- | --- | --- |
| **S1 依赖与配置** | BOM 引入 `meilisearch-java:0.21.0`（官方 SDK）+ `gson:2.13.2`（M1 审查修复，subject-infra 文档序列化编译期可见）；starter `MeiliClientConfig`（`Client` Bean，url/key 走 Nacos 占位 `${MEILISEARCH_URL:http://127.0.0.1:7700}`/`${MEILISEARCH_KEY:}`，规则 8 真实值不落盘） | ✅ |
| **S2 索引/文档** | index `subject_pool`，**显式 primaryKey=subject_id**（幂等建索引：getIndex 容错仅 index_not_found、createIndex 容错 index_already_exists 并发竞态，其余上抛防假阳性）；`searchable=[subject_name]`、`filterable=[subject_type, subject_difficult, category_ids, label_ids, is_deleted]`（**category_ids 数组 — I1 修复**：多分类题目按任一分类命中，保全既有 4 筛选前端无感）；Gson LOWER_CASE_WITH_UNDERSCORES 序列化与 attributes 对齐；先 settings 后 addDocuments | ✅ |
| **S3 端点改造** | `getSubjectPageBySearch` 改 Meili：countSearch → total=0 空页早退 → searchSubjectIds → DB `queryByIds` + **按 Meili 命中顺序重排**（`Comparator.comparingInt(hitOrder::indexOf)`）→ label 组装；**catch 仅包 Meili 调用**（S3.2 裁决：DB/组装异常自然上抛）→ 降级既有 LIKE（`countBySearch`/`queryByPageSearch` 保留）；**契约不变前端无感** | ✅ |
| **S4 写后同步** | add/update 成功挂 `upsertDocument`（update 钩子重读持久化实体建 doc，防部分字段更新丢 is_deleted — C1 修复）；失败吞异常 + `log.warn` 不影响主链路；重建兜底 | ✅ |
| **S4 重建端点** | `POST /subject/search/admin/rebuild`（`@SaCheckLogin` + `@SaCheckRole("admin_user")`）→ `rebuildSearchIndex()`：全量取数 → 逐条 buildSearchDoc → `rebuild`（deleteAllDocuments + settings + **单次批量 addDocuments**、空集跳过、null 早退）；幂等可重复调用 | ✅ |
| **契约测试判别** | `SubjectContractTest`：Meili 命中判别（`verify(meiliSearchService).searchSubjectIds` + `verify(subjectInfoService, never()).queryByPageSearch/countBySearch`）与降级 LIKE 判别（Meili 抛异常 → LIKE mapper 真实调用）；重建端点 200（admin）/403（登录无角色）/401（未登录）三态 | ✅ |
| **openapi 零变更** | PR 16 files 无 `docs/api/coderclub-openapi.json`（确认）；重建端点登记由 PM 验收批次随 interview 端点一并微同步（规格 S5.3 裁决） | ✅ |
| **边界** | 不引入/不保留 ES（登记移除，用户执行）；不触碰其他服务；`api/` 快照与 status 未动；docs/superpowers 属 B-Impl 范围 | ✅ |

## 3. 独立复验（本底稿复核时执行，附着 `73b98ea`）

采用 `git archive` 提取实施快照至隔离目录（不动主工作区），实跑：

| 命令/动作 | 结果 |
| --- | --- |
| 全量 `mvn install -DskipTests -q` + `mvn test` | **exit 0，BUILD 全绿**（17 测试模块含 subject 聚焦 124+ 用例零失败） |
| openapi 文件改动 | 无（PR 文件清单不含 openapi；本批零变更符合声明） |
| 源 SHA 对照 | 当前后端 main 源 = `57C2D6EE…`（D2 合入后；回执 26AEC009 系基线 86a09e7 过期值——PM 注记采纳，无需 B-Impl 补正） |

## 4. 延后项核查（回执 openFindings 8 项，均不阻塞，PM 已知悉）

| # | 项 | 复核意见 |
| --- | --- | --- |
| 1 | 全量重建 N+1 联查（brief/mapping/label 逐实体） | 万级量重建慢，批量优化延后，接受 |
| 2 | `total` 为 Meili 估计值（maxTotalHits 1000 封顶） | 当前量级不触顶，登记，接受 |
| 3 | 排序语义变化（Meili 相关度 vs 原 LIKE 无序） | 行为改进，规格/回执登记，接受 |
| 4 | rebuild 端点未登记 openapi | 规格 S5.3 裁决：PM 微同步批次随 interview 端点一并，接受 |
| 5 | 命中数/实得行数理论漂移 | 量级内无影响，接受 |
| 6 | 写钩子不 ensureIndex（首写依赖自动建索引 + 主键推断） | 当前版本可工作，懒 ensureIndex 延后，接受 |
| 7 | add 钩子事务内写 Meili（提交失败幽灵文档） | 低概率，重建兜底可清，知晓登记，接受 |
| 8 | delete 钩子桩 doc 内容不完整（仅 id+isDeleted=1） | filter 恒 is_deleted=0 不命中、功能正确，接受 |

## 5. 复核结论

**通过，签署。** 回执声明（9 提交、S1-S5 逐项、聚焦 124+ 用例、判别/降级/重排/三钩子/重建幂等测试、边界遵守）与人链核验、代码实读、本地全量测试复验逐项一致；PM 注记（源 SHA 过期值，openapi 零变更无需补正）已采纳；PR #22 已按授权合入 main（`dc0dd284`），R2 达成。未发现 [必须修复]/[建议修改] 问题。

## 6. 关联

- 任务书 · grill 共识 · 回执 PR #153（merge `5ce79b1`）· 实施 CoderClub PR #22（merged `dc0dd284`）
- 后续：PM 验收 → 快照微同步（openapi 登记 `/subject/search/admin/rebuild` 端点，路径数随 interview 端点一并）→ 前端搜索页直连 Meili 语义（无契约变化）→ Meilisearch 部署验证（A1，用户已部署）