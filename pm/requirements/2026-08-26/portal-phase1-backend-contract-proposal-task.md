# 任务书：A8 阶段一后端契约提案起草（门户化配套 2 端点，批量 proposal）

> **派发角色：** 协调 PM
> **派发日期：** 2026-08-26
> **执行角色：** 后端评审（B-Review）
> **设计依据：** `docs/superpowers/specs/2026-08-26-a8-frontend-portal-design.md`（A8 门户化设计，已批准合入 main，PR #64）§ 4.3/4.5/6
> **类型：** 契约提案起草（`proposals/backend/`，PM 确认后转 B-Impl 实现）

## 1. 目标

为 A8 阶段一门户化起草 **2 个新契约端点**（一个批量 proposal 文件涵盖两个端点），供 PM 确认后派发 B-Impl 实现。门户化前端将消费这两个端点（题库首页右栏出题贡献榜 + 搜索页）。

参考设计文档决策：题库首页三栏（Q5）、搜索页（§4.5：「keyWord 匹配 subjectName + 题干关键词 LIKE；分页；不扩大范围（不做全文检索/拼音）」）、出题贡献榜（§4.3 右栏）。

## 2. 端点语义建议（起草时按此基准细化/完善）

### 2.1 `POST /subject/getSubjectPageBySearch`（搜索）

| 项 | 建议 |
| --- | --- |
| 请求体 | `keyWord`（必填，字符串，长度上限建议 50）+ `pageNo`/`pageSize`（分页，默认 1/20，语义与 `getSubjectPage` 一致）+ 可选筛选（`subjectType`/`subjectDifficult`/`categoryId`/`labelId`，与 `getSubjectPage` 对齐——阶段一前端可不传，定义为可选） |
| 匹配范围 | `subjectName` + 题干关键词（LIKE '%keyWord%'）；不扩全文检索/拼音/分词 |
| 响应 | 分页结构（与 `getSubjectPage` 响应同构：total + 列表；列表项含 id/subjectName/subjectType/subjectDifficult 等展示字段） |
| 空 keyWord | 语义待 B-Review 定夺（建议：空字符串返回空列表，不抛 400；仅缺失 keyWord 字段时 400） |
| 鉴权 | 沿用 `getSubjectPage` 现状（设计勘察实证：无登录态 401，`@SaCheckLogin`）——**如有差异须在 proposal 中明示** |
| 错误码 | 对齐现有契约错误码体系（不做新错误码，除非必要并明示） |

### 2.2 `POST /subject/getContributeList`（出题贡献榜）

| 项 | 建议 |
| --- | --- |
| 请求体 | 可空（默认 TOP 10）；如需可加 `topN`（上限建议 20） |
| 语义 | 按出题人分组统计题目数量（`subject` 表 `created_by` 分组计数，count 降序），TOP N |
| 响应 | `list[{ count, 出题人展示字段 }]`——出题人展示字段命名与来源（`auth_user` 关联 user_name/nick_name）待 proposal 定；排序 count 降序；字段命名遵循契约 `UserInfoVO` 侧 `userName`/`nickName` 口径（注意：契约用户信息字段为 userName/nickName） |
| 空数据 | 无题目时返回空列表（count=0 列表） |
| 鉴权 | 沿用登录鉴权（同 2.1） |

## 3. 约束

- 只新增上述 2 端点；不修改/不删除任何现有端点、字段、鉴权、错误码语义。
- 风格与现有 `getSubjectPage` 提案范式一致（响应统一 `ResponseResult` 包装、DTO 命名 `PageQuery` 风格、description 中文注释）。
- proposal 中端点示例值不含真实环境信息（规则 8）。
- 不修改交接仓库 `api/` 快照与 `status/sync-manifest.json`（PM 确认并实现验收后全链同步）。

## 4. 交付与回执（规则 9）

1. 起草 `proposals/backend/2026-08-26/portal-phase1-search-contribute-proposal.md`（命名可调整，语义清晰即可），经 `codex/backend-contract` PR 合入交接仓库 main（governance-check 自动合并）。
2. 完成通知带规则 9 四字段（实施 SHA、回执/PR SHA、PR 号、R2 状态）告知 PM；PM 确认 proposal 后派发 B-Impl 实现。
3. 若起草中发现设计文档 §4.5/§4.3 语义与后端现状冲突（如字段来源差异），在 proposal 中明示差异与建议，交 PM 决策。

## 5. 验收标准

- [ ] 两端点请求/响应/鉴权/错误码/示例完整定义，与现有契约风格一致
- [ ] 与 `getSubjectPage` 分页与响应范式同构（前端可复用列表组件）
- [ ] 批量单 proposal 文件，无单端点往返
- [ ] 未改现有端点与 `api/` 快照、`sync-manifest`；proposal 无敏感信息
- [ ] 合入 main + 通知四字段

## 6. 关联

- A8 设计文档：`docs/superpowers/specs/2026-08-26-a8-frontend-portal-design.md`（PR #64）
- 后续：PM 确认 proposal → B-Impl 实现任务书 → 前端门户化任务书（F-Impl）