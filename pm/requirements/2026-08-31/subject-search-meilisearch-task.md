# 任务书：subject 题目搜索升级 Meilisearch（B-Impl）

> 派发角色：协调 PM
> 派发日期：2026-08-31
> 执行角色：后端实现（B-Impl）
> 决策依据：grill 共识（2026-08-31，用户逐项确认）——本轮引入 Meilisearch + 题目搜索升级；改造既有端点（前端无感）；写后同步 + 全量重建；移除 ES + 部署 Meilisearch；独立任务书与 interview 任务书三线同批
> 批次：阶段四同批（interview 后端 `interview-implementation-task.md` + interview 前端 `interview-frontend-task.md` + 本任务书）
> **ES 结论（登记）**：服务器 Elasticsearch（8.17.4，闲置、无客户端）**移除**；题目搜索改用 **Meilisearch**（轻量、官方 Java SDK 成熟），不保留 ES

## 前置基线

- 依赖：`com.meilisearch.sdk:meilisearch-java`（**官方 SDK**，Maven Central `0.21.0`）；`@Configuration` 注入 `Client` Bean（url + key 走 **nacos 配置**，`master key` 占位符由用户持有、不落盘）。
- **服务部署（用户执行，A1 模式前置）**：移除 ES 容器；部署 Meilisearch docker 容器（默认端口 **7700**）；B-Impl 不执行服务器操作、仅配置对接。
- 现有快照 `74417DD8`（75 路径）；本批改造既有端点，**路径数不变（83，随 interview 端点登记后）**。
- 建议分支 `feat/subject-search-meilisearch`。

## 1. 任务明细

### S1 Meilisearch 客户端
- `coder-club-subject` 引入官方 SDK 依赖（`com.meilisearch.sdk:meilisearch-java`）；`@Configuration` 创建 `Client` Bean。
- nacos 配置：`meilisearch.url`（http://<host>:7700，占位）、`meilisearch.key`（占位引用，用户持有真实值）；规则 8 占位符。

### S2 索引与文档
- index 命名 `subject_pool`；文档字段：`subject_id / subject_name / subject_answer / subject_type / label_names / is_deleted`；`searchableAttributes` = subject_name/type；`filterableAttributes` = subject_type/label_names。
- 遵循官方 Good practices：**先配置 settings 再 addDocuments**；构建索引映射（对齐既有 `SubjectSearchItemVO` 消费字段）。

### S3 改造搜索端点（前端无感）
- `POST /subject/search`（`getSubjectPageBySearch`）：后端从 SQL LIKE 切换为 **Meilisearch 全文查询**（keyword 全文匹配 + subject_type/label filter + 分页），响应结构与既有 `PageResult<SubjectSearchItemVO>` 一致（含 labelName 组装、空串空页语义沿用）。
- **契约不变**（方法/路径/参数/响应）；前端 SearchView 零改动。

### S4 索引一致性（写后同步 + 全量重建）
- **写后同步**：subject 题目新增/修改/删除处同步 `add/update/delete` Meilisearch 文档（B-Impl 在 subject 保存/删除钩子调用；删除含逻辑删 is_deleted 处理）。
- **全量重建**：管理端点（admin_user，如 `POST /subject/search/admin/rebuild`）从 `subject_info` 全量导入索引；提供触发（管理端调用，前端管理页可后续接）。

### S5 质量门禁
1. **契约测试** `SubjectContractTest` 补/改：Meilisearch 查询映射（keyword/filter/分页/空结果）、响应结构（SubjectSearchItemVO/labelName）——判别性断言（走 Meili 后端而非 LIKE，误走 SQL 必失败）。
2. **domain 单测**：索引映射（BO→文档）、搜索参数转换、分页边界、写后同步钩子、全量重建幂等。
3. 全仓 mvn 绿 + CI 双绿（build-and-test + sensitive-scan）；源文档 LF 登记（改造不增端点，路径数不变）；快照微同步随 PM 验收批次（interview 端点登记时一并）。
4. 回执双轨（`handoff/backend-to-frontend/` 按创建日期，**含 `receiptCommitSha`**）+ 完成通知四字段。

## 2. 约束

- **不引入/不保留 ES**（已登记移除）；改造既有端点语义不变、**前端零改动**；不触碰其他服务。
- Meilisearch 服务器部署由用户执行（A1 模式）；B-Impl 仅配置对接 + 代码。
- 不改 `api/` 快照与 `status/`（PM 验收后微同步）；规则 8 占位符（master key/url 不落盘）；Conventional Commits。

## 3. 关联

- 参考项目 jc-club（ES 仅用于题目搜索，本文档对应能力升级）· grill 共识（同批派发 PR）· interview-implementation-task.md / interview-frontend-task.md（三线同批）· 服务器 ES 移除（用户执行）