# PM 决策：阶段三配套两提案确认（X1 VO 增补 + NotRoleException 映射）

> 决策角色：协调 PM
> 决策日期：2026-08-30
> 提案：`proposals/backend/2026-08-30/phase3-companion-x1-vo-amendment-proposal.md`、`proposals/backend/2026-08-30/phase3-companion-notrole-mapping-proposal.md`（同批 PR #101，实施提交 `291344b`，R2 main，MCP 核验）
> 任务书：`pm/requirements/2026-08-30/phase3-companion-proposals-task.md`（PR #99）
> 状态：**两提案均确认通过，B-Impl 小批次实现任务书随本轮派发**

## 1. 决策结果

| 提案 | 项 | 决策 |
| --- | --- | --- |
| ① X1 VO 增补 | V1：`IdentifierUserItemVO` 新增 `id`（required）+ 4 副本同构 | ✅ 按提案 |
| ① X1 VO 增补 | V2：消费方双键别名（circle/practice 各 +1 行，查找侧零改动） | ✅ 按提案 |
| ① X1 VO 增补 | V3：验收口径 §4（practice 排行昵称修复为验收项） | ✅ 按提案 |
| ① X1 VO 增补 | V4：contribute 双键改造列后续建议，不随本提案 | ✅ 知悉，后续按建议排期 |
| ② NotRole 映射 | N1：两服务各增一 handler，同形态对齐 | ✅ 按提案 |
| ② NotRole 映射 | N2：偏差处置（受影响端点=空，防御性同步 + 语义预登记） | ✅ 按提案 |
| ② NotRole 映射 | N3：边界（不补角色注解 / auth 另案不变） | ✅ 知悉 |

## 2. 决策理由

1. **提案①**：响应增字段属向后兼容变更；`id` 为 auth_user 主键、每个命中用户恒返回，required 语义成立。双键别名（`putIfAbsent(id 键)` + 保留 userName 键、查找侧零改动）是混合存量/增量数据下的生产安全解——消费方无需关心键空间归属，避免存量数据迁移。验收口径承接任务书指定（practice 排行昵称修复），A8-P2 遗留限制就此闭环。
2. **提案②**：任务书原假设"各受影响端点的错误响应说明更新"经 B-Review 实读核验修正为空集（subject/practice 当前零 `@SaCheckRole` 端点）；按**防御性同步**定稿确认——两个 handler 的边际成本远低于"未来任一服务新增角色注解即线上 500"的风险敞口，语义预登记（角色校验失败 = 403「无权限访问」）使未来端点生效即有既定契约。
3. **V4**：subject contribute 的 nickMap 同款双键改造（约一行）不扩大本批范围——存量 `subject_info.created_by` 为 userName 型不触发降级，待数字 loginId 型数据出现前落地即可，交 PM 后续排期。
4. **N3**：auth 服务缺 SaInterceptor（openFinding `auth-role-check-gap`）维持另案；本提案不触及 auth、不为既有端点叠双重门禁注解——与既有治理口径一致。

## 3. 派发

- B-Impl 小批次实现任务书：`pm/requirements/2026-08-30/phase3-companion-implementation-task.md`（本轮同批派发，含源契约文档 info.description 63→74 措辞修正授权）。
- 快照衔接：提案①实现合入后由 PM 做快照微同步（`IdentifierUserItemVO.id` 采纳 + description 差异消除，语义差异预计 11→10）。

## 4. 关联

- A8-P3-BE 回执 PR #97（C1 开放项）· 复核签署 PR #100 · 任务书 PR #99 · 提案 PR #101（R2 main）
- 决策人：协调 PM，2026-08-30
