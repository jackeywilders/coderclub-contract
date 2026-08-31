# 回执：subject 题目搜索升级 Meilisearch（B-Impl，①线）

> **回执角色：** 后端实现（B-Impl）
> **日期：** 2026-08-31（Asia/Shanghai）
> **任务书：** `pm/requirements/2026-08-31/subject-search-meilisearch-task.md`（第二批四线之一）
> **决策依据：** grill 共识（2026-08-31，用户逐项确认）——Meilisearch 引入、既有端点改造（前端无感）、写后同步 + 全量重建、ES 移除
> **设计/计划：** 后端仓库 `docs/superpowers/specs/2026-08-31-subject-search-meilisearch-design.md`（0f42c4a）、`docs/superpowers/plans/2026-08-31-subject-search-meilisearch.md`（fda8433，随本 PR 合入）

## 1. 来源与提交哈希

| 项 | 值 |
| --- | --- |
| 实现仓库 | jackeywilders/coderclub（后端） |
| 分支 | `feat/subject-search-meilisearch`（基于 `86a09e7`） |
| 实现头 | `73b98ea`（9 提交：spec + plan + S1 依赖 + S2 索引/文档 + S3 端点改造 + S4 同步/重建 + 3 个审查修复波） |
| PR | **#22**（feat/subject-search-meilisearch → main） |
| CI | build-and-test + sensitive-scan（head `73b98ea`，双绿核验后转人工合入） |
| 合入状态 | **R1 达成**；R2 待人工合入（用户/B-Review 在 CI 全绿后执行） |

## 2. 任务明细（对照任务书 S1-S5）

1. **S1 依赖与配置** ✅：BOM 引入 `meilisearch-java:0.21.0`（官方 SDK，Maven Central）；starter 新增 `MeiliClientConfig`（`Client` Bean，url/key 走 Nacos 占位 `${MEILISEARCH_URL:http://127.0.0.1:7700}`/`${MEILISEARCH_KEY:}`，规则 8 真实值不落盘）。
2. **S2 索引/文档** ✅：index `subject_pool`；文档字段（**扩展版**：+`subject_difficult`/`category_ids`(数组)/`label_ids`/`label_names`——保全既有 4 筛选，前端无感；brainstorming Q1 裁决）；`searchable=[subject_name]`、`filterable=[subject_type,subject_difficult,category_ids,label_ids,is_deleted]`；先 settings 后 addDocuments；answer 联 brief（subjectId Long 化后直查）、label/category 联 mapping→label（复用 `getLabelNamesFromMappingList` 先例）；**幂等建索引（primaryKey=subject_id，createIndex 竞态容错 index_already_exists）**。
3. **S3 端点改造** ✅：`getSubjectPageBySearch` 改 Meili 全文查询（q + filter + offset/limit → 命中 id → DB `queryByIds` + **按 ids 重排** + label 组装）；**契约不变前端无感**；**Meili 异常降级既有 LIKE**（countBySearch/queryByPageSearch 保留；catch 收窄至 Meili 调用，DB/组装异常自然上抛——S3.2 裁决）；排序=Meili 相关度（行为改进登记）。
4. **S4 写后同步 + 重建** ✅：add/update/逻辑删三处挂 upsert（**update 钩子重读持久化实体建 doc**——防部分字段更新丢 is_deleted，最终审查 C1；失败吞异常不影响主链路，重建兜底）；`POST /subject/search/admin/rebuild`（`@SaCheckRole("admin_user")`）幂等全量重建（清空容错仅 index_not_found，防假阳性成功——审查修复）。
5. **S5 质量门禁** ✅：契约/domain 判别性测试（走 Meili 未走 LIKE、降级、重排锚定、三钩子、重建幂等、端点 200/403/401）；全仓 mvn 绿 + CI 双绿；openapi **不新增端点**（重建端点登记随 PM 验收批次微同步）；回执双轨（**含 receiptCommitSha**）。

## 3. 测试证据

- 全仓 `mvn install -DskipTests -q` + `mvn test` 绿（exit 0）；聚焦 124+ 用例全绿（infra 16/domain 30/controller 78 + 契约）。
- 审查链：brainstorming（Q1 字段扩展/Q2 降级裁决）→ SDD 执行（Task1-4 子代理 + 任务审查，修复波均 ADDRESSED）→ 全分支最终审查（修完再合：C1 update 重读持久化 + I1 category_ids 数组 + M1-3）→ 定向复审 **5/5 ADDRESSED**。

## 4. 边界遵守声明（任务书 §2）

- 不引入/不保留 ES（登记移除，用户已执行）；改造既有端点语义不变、前端零改动；不触碰其他服务。
- Meilisearch 服务器部署由用户执行（A1）；B-Impl 仅配置对接 + 代码；未改 `api/` 快照与 `status/`（PM 验收后微同步）；规则 8 占位；Conventional Commits。

## 5. 已知限制与延后项（openFindings）

1. **全量重建 N+1 联查**（审查 I2，延后）：rebuildSearchIndex 逐实体联查 brief/mapping/label，万级题库重建慢——建议后续批量优化（mapping 按 subject_id 集合一次查 + label 一次性 batchQueryByIds）。
2. **`total` 为 Meili 估计值**（审查 M4）：`estimatedTotalHits` 受 `maxTotalHits`（默认 1000）封顶，超千命中 total 不精确——当前题库量级不触顶，登记。
3. **排序语义变化**（审查 M9）：Meili 相关度排序 vs 原 LIKE 无序——行为改进，规格/计划已登记。
4. **新端点 `/subject/search/admin/rebuild` 未登记 openapi**（审查 M8）：按规格 S5.3 裁决由 PM 验收批次登记（路径数微同步时一并）。
5. **命中数/实得行数可能漂移**（审查 M5）：total（Meili 估计）与 queryByIds 实得行数理论可差——量级内无影响。
6. **写钩子不 ensureIndex**（审查 M6）：首条写前依赖 Meili 自动建索引 + 主键推断（当前版本可工作）；可在 upsertDocument 前懒 ensureIndex（有性能权衡）——延后。
7. **add 钩子事务内写 Meili**（审查 M7）：提交失败会产生幽灵文档（低概率，重建兜底可清）——知晓登记。
8. **delete 钩子桩实体 doc 内容不完整**（复审观察）：逻辑删 doc 仅 id+isDeleted=1，filter 恒 is_deleted=0 不命中、功能正确——登记。

## 6. 后续链

1. B-Review 复核签署 → PM 验收 → **快照微同步**（openapi 登记 rebuild 端点 + 路径数随 interview 端点）→ 前端搜索页可直连 Meili 语义（无契约变化）。
2. 合入提醒：PR #22 CI 双绿，**合入由人工（用户/B-Review）在 GitHub 执行**。
3. 同批衔接：interview 后端/前端（同批三线）、redis-integration / r2-backup（并行推进中）。

---
- 回执角色：后端实现（B-Impl），2026-08-31
