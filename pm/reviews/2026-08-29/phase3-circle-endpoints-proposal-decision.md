# PM 决策：A8 阶段三 circle 契约提案确认（11 新增 + 2 扩展，X1-X6/D0）

> 角色：协调 PM
> 决策日期：2026-08-29
> 提案：`proposals/backend/2026-08-29/phase3-circle-endpoints-proposal.md`（PR #94）；差异分析 `designs/backend/2026-08-29/phase3-circle-diff-analysis.md`（同批）
> 状态：**确认通过；转 B-Impl 实现任务书**

## 1. 确认内容

| 项 | 确认 |
| --- | --- |
| 端点集 | **11 新增**（圈子 1 + 动态 3 + 评论 3 + 消息 2 + 敏感词管理 2）+ **2 既有端点向后兼容扩展**（X1/X2） |
| 消息形态 | 落库 + 拉取（Q6 决策 A），无 WebSocket（后置不进验收） |
| DDL | 无（差异分析 D0，5 表 + sensitive_words 全支撑，字符集一致） |
| 网关 | 零改动（`/circle/**` GW-1 预留路由转实） |
| 快照预期 | 63 → **74 路径**（+11），语义差异 38 → **51**（+11 端点 + 2 扩展；验收时按实际登记计） |

## 2. 决策项（X1-X6 / D0，按建议确认）

| # | 项 | 决策 |
| --- | --- | --- |
| X1 | `list-by-identifiers` 数字 id 匹配扩展 | **确认**：纯数字串同时按 `id IN` 匹配（`user_name IN OR id IN`），向后兼容；顺带修复 practice 排行昵称显示（practice 零改动） |
| X2 | `getSubjectPage` 新增可选 `primaryCategoryId` | **确认**：语义定界一级=primaryCategoryId、二级=categoryId、显式不递归；缺省不生效（向后兼容）；**openFinding `categoryId-primary-filter-semantics` 随此关闭** |
| X3 | 敏感词管理鉴权 | **确认**：`@SaCheckRole("admin_user")` + circle 注册 SaInterceptor/roleKeys（**本系统首个实际生效的角色注解端点**；403 语义）；为 auth role-check 缺口的修复提供同款模式参考（auth 另案） |
| X4 | 消息契约形态 | **确认**：结构化 VO + 中性文案（"评论了你的动态"/"回复了你的评论"）+ 昵称读时组装 + from==to 不落 + unRead 返回 Integer（只计数不改状态） |
| X5 | 蓝本增强 E1-E5 | **知悉**：归属校验（本人/动态作者）/ DFA 管理端触发重建立即生效（修复蓝本重启才生效缺陷）/ 消息结构化 / 自评论不落消息 / POST+角色注解 |
| X6 | 圈子管理 CRUD（save/update/remove） | **知悉**：不纳入本阶段（任务书清单外，后续管理端另案） |
| D0 | DDL 变更 | **知悉**：无 |

## 3. 追认

- **落盘目录偏差**：交付物落 `2026-08-29/`（任务书原文 2026-08-28/）——按治理规则 6（日期目录以文档创建日期为准，Asia/Shanghai），交付日为 2026-08-29，**追认合规**。

## 4. 质量点（B-Impl 任务书硬条件）

1. 敏感词 DFA：管理端 save/remove 后**同步重建**（立即生效）；发布/评论校验黑名单命中拒绝、白名单跳过
2. 评论树：子树批量软删 + `reply_count` 按**实际更新条数**回减（同事务）；树形全量返回（回复套回复）
3. 消息：读取即已读（按页内 ids 批量置读，幂等）；from==to 不落
4. 归属/幂等：动态删除仅本人、评论删除本人或动态作者；删除类幂等 true；越权 400
5. 扩展兼容：X1/X2 向后兼容（既有消费方行为不变或变优）；X2 与 internal I2 同模式（经 mapping 过滤）

## 5. 后续链

1. B-Impl 实现任务书（本决策同批派发）：`coder-club-circle` 新模块（四层，含 SaInterceptor/角色解析）+ 11 端点 + 2 既有扩展 + BOM caffeine；与网关既有链路衔接（/circle 路由转实）
2. B-Impl 回执 → B-Review 签署 → PM 验收 → 快照全链同步（+11 路径 / +13 语义差异）→ 前端阶段三任务书（F-Impl：鸡圈页）
3. openFinding：`categoryId-primary-filter-semantics` → closed（X2 落地验收时）；`auth-role-check-gap` → 保持（auth 另案，circle 模式已示范）

## 6. 关联

- 提案 PR #94 · 任务书 PR #93 · 架构方向 PR #79 §7
- 本决策：`pm/reviews/2026-08-29/phase3-circle-endpoints-proposal-decision.md`

决策：协调 PM，2026-08-29