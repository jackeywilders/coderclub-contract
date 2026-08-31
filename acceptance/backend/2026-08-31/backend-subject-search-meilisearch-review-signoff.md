# SUBJECT-SEARCH-MEILISEARCH subject 搜索升级 Meilisearch——后端评审复核签署

> 角色：后端评审（B-Review）
> 签署日期：2026-08-31
> 任务书：`pm/requirements/2026-08-31/subject-search-meilisearch-task.md`
> 回执：`handoff/backend-to-frontend/2026-08-31/backend-subject-search-meilisearch-report.md` + `-summary.json`（PR #153，merge `5ce79b1`；回执 `2be6316` + 修正 `c06fc70`）
> 工作底稿：`designs/backend/2026-08-31/backend-subject-search-meilisearch-review-workpaper.md`
> 状态：**签署通过，转 PM 验收**

## 1. 复核结论

✅ **复核通过，签署本回执。** 实施 `73b98ea`（CoderClub PR #22，9 commits）经人链核验与独立复验与任务书/规格相符：

- [x] **S1 依赖与配置**：BOM 引入 `meilisearch-java:0.21.0` + `gson:2.13.2`（M1）；`MeiliClientConfig` url/key 走 Nacos 占位（规则 8 真实值不落盘）
- [x] **S2 索引/文档**：`subject_pool` 显式 primaryKey=subject_id 幂等建索引（index_not_found/index_already_exists 分级容错，含 M2 并发竞态）；扩展字段保全既有 4 筛选（filterable 含 `category_ids` 数组 — I1 修复）；先 settings 后 addDocuments；Gson 下划线序列化对齐
- [x] **S3 端点改造**：`getSubjectPageBySearch` 改 Meili 全文查询（countSearch 空页早退 → searchSubjectIds → queryByIds + 按命中顺序重排 → label 组装）；**catch 仅包 Meili 调用 → 降级既有 LIKE**（countBySearch/queryByPageSearch 保留）；**契约不变前端无感**
- [x] **S4 写后同步 + 重建**：add/update/逻辑删三挂钩子（update 重读持久化实体 — C1；失败吞异常不影响主链路）；`POST /subject/search/admin/rebuild`（@SaCheckLogin + @SaCheckRole admin_user）幂等全量重建（清空容错仅 index_not_found，防假阳性成功）
- [x] **契约测试判别**：Meili 命中未走 LIKE（`verify(never)`）与降级 LIKE 双轴判别断言；重建端点 200（admin）/403（无角色）/401（未登录）三态
- [x] **独立复验（本会话实跑，附着 `73b98ea`）**：全量 `mvn install -DskipTests` + `mvn test` **exit 0**（17 测试模块 + subject 聚焦 124+ 用例零失败）；openapi 文件零变更确认
- [x] **CI 双绿**：run 33424822450（GitHub API 逐 job 核实 build-and-test + sensitive-scan）
- [x] **边界遵守**：不引入/不保留 ES（登记移除，用户执行）；不触碰其他服务；`api/` 快照与 status 未动；docs/superpowers 属 B-Impl 范围

## 2. PM 注记采纳（源 SHA）

回执 `sourceDoc.lfSha256` 登记 `26AEC009` 系基于基线 `86a09e7`（D2 合入前）的过期值；当前后端 main 源实测 `57C2D6EE`（D2 合入后）。本批 openapi **零变更**（75 路径不变），重建端点登记由 PM 验收快照微同步按当前源一并执行——**无需 B-Impl 补正，签署知悉采纳**。

## 3. 规则 9 完成通知四字段（自检）

| 字段 | 值 |
| --- | --- |
| 实施提交 SHA | `73b98ea`（`73b98ea7458358c79aaa86db97b7f36a8d5c6ee3`，9 commits） |
| 回执提交 SHA | `2be6316`（receiptCommitSha 修正 `c06fc70`；交接仓库 PR #153 已合入 main，merge `5ce79b1`） |
| PR 号 | CoderClub PR #22——**已合入 main（merge `dc0dd284`，2026-08-31，B-Review 复核通过后执行授权合入）** |
| R2 状态 | **实施 R2 达成**（已合入 CoderClub main，main tip 核验 `dc0dd284`）；本签署随交接仓库流程合入 main |

## 4. 延后项与观察项（打包转 PM 验收，不阻塞）

| # | 项 | 处置标注 |
| --- | --- | --- |
| 1 | 全量重建 N+1 联查（批量优化延后） | 万级量重建慢，后续优化，接受 |
| 2 | `total` 为 Meili 估计值（maxTotalHits 1000 封顶） | 当前量级不触顶，登记，接受 |
| 3 | 排序语义变化（Meili 相关度 vs 原 LIKE 无序） | 行为改进，规格/回执已登记，接受 |
| 4 | `/subject/search/admin/rebuild` 未登记 openapi | 规格 S5.3 裁决：PM 微同步批次随 interview 端点一并 |
| 5 | 命中数/实得行数理论漂移 | 量级内无影响，接受 |
| 6 | 写钩子不 ensureIndex | 当前版本可工作，懒 ensureIndex 延后，接受 |
| 7 | add 钩子事务内写 Meili（幽灵文档低概率） | 重建兜底可清，知晓登记，接受 |
| 8 | delete 钩子桩 doc 内容不完整 | filter 恒 is_deleted=0 不命中、功能正确，接受 |

## 5. 关联

- 任务书 · grill 共识 · 回执 PR #153 · 实施 CoderClub PR #22（merged `dc0dd284`）
- 后续：PM 验收 → 快照微同步（openapi 登记 rebuild 端点，路径数随 interview 端点一并）→ 前端搜索页直连 Meili 语义（无契约变化）→ Meilisearch 部署验证（A1，用户已部署）

签署：后端评审（B-Review），2026-08-31