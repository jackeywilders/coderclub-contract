# 阶段三配套实现（A8-P3-COMPA）——PM 验收

> 验收角色：协调 PM
> 验收日期：2026-08-30
> 回执：`handoff/backend-to-frontend/2026-08-30/backend-a8p3-companion-report.md` + `backend-a8p3-companion-summary.json`（PR #103，head `d4004ebc`，已合入 main `59831bcc`）
> 复核签署：`acceptance/backend/2026-08-30/a8p3-companion-review-signoff.md`（PR #104，merged，MCP 核验）
> 状态：**验收通过**

## 1. 验收结论

✅ **A8-P3-COMPA 验收通过。** 实施 `8649eba`（7 commits——回执"8"笔误经签署勘误）经 B-Review 复核签署（PR #104）与 PM 独立核验，与提案①②（PR #101）及 PM 决策（V1-V4 / N1-N3）相符；快照微同步随本验收执行。**两条 openFinding（`x1-consumer-key-mismatch`、`notrole-mapping-gap`）就此关闭；A8-P2 排行昵称已知限制闭环。**

## 2. 规则 9 核验链（四字段）

| 字段 | 值 |
| --- | --- |
| 实施提交 SHA | `8649eba`（`8649eba468ac97577acb2de5cfc0a5e30155488e`，7 commits） |
| 回执提交 SHA | `d4004ebc`（PR #103，已合入 main `59831bcc`） |
| PR 号 | CoderClub PR #16——**merged（merge `b15a735`，2026-08-30T06:45:06Z，B-Review 授权合入）** |
| R2 状态 | ✅ 双达成：实施合入 CoderClub main（`b15a735`）；签署 PR #104 合入交接仓库 main |

## 3. PM 独立复核（非签署转录）

1. **源契约实测（远端 main）**：`docs/api/coderclub-openapi.json` LF SHA-256 = `BF59FECD7DA3A97BBC86CA589AA2D0E21CCD450444A63CE82B8AD040E49382B4`（与回执/签署逐字一致）；74 路径 / 117 schemas；`IdentifierUserItem.required=["id"]`，`id` 属性定义完整（int64 + 主键语义 description）；端点 description 追加 id 说明；`info.description` 与快照 `DAAEECB7` 逐字一致（上轮授权的 74 措辞修正生效，该治理差异归零）。
2. **实现必然项认可**：auth 控制器手工组装处补 `vo.setId(u.getId())`（提案字面未列，缺此行 required 语义不成立）——属提案①语义的必然实现，回执已注明，PM 认可。
3. **快照微同步执行**：`DAAEECB7 → AE967C70`（74 路径 / 117 schemas / LF）；与源 diff 复核 = **11 项**（10 脱敏占位符 + 1 项 `IdentifierUserItem` 类级 description 治理修正）。
4. **敏感扫描**：零 hex-token 残留、零新增敏感模式；格式校验（LF、2 空格缩进、JSON 语法）通过。

## 4. 快照微同步登记

| 项 | before | after |
| --- | --- | --- |
| sourceCommit | `d9eb64f`（A8-P3 实施） | `8649eba`（配套实施，经 CoderClub PR #16 → main `b15a735`） |
| sourceSha256（LF） | `736F6588…` | `BF59FECD…` |
| snapshotSha256 | `DAAEECB7…` | `AE967C70FBF0CA69085D2429CB586B0A3C83BDAB9FB9F28D7A5A8B01F17E4F68` |
| semanticDifferenceCount | 11 | 11（构成更新，见下） |

**构成更新说明**：上轮 11 项 = 10 脱敏 + 1 `info.description` 治理修正；本轮源侧 74 措辞修正生效后该项**消除**，同时按签署请求在快照侧修正 `IdentifierUserItem` 类级 description（「（仅展示信息）」→「（展示信息与 auth_user 主键 id）」，源侧措辞留待下次实现轮顺带修正）→ 新 11 项 = 10 脱敏 + 1 类级 description 治理修正。任务书/签署预估「11→10」未计入此项修正，以实际 diff 为准如实登记。`IdentifierUserItem.id`、`required`、端点 description 追加均已随源采纳（不构成快照-源差异）。

## 5. openFindings 处置

| finding | 处置 |
| --- | --- |
| `x1-consumer-key-mismatch` | **closed（2026-08-30）**——`IdentifierUserItemVO.id` 4 副本同构落地 + circle/practice 双键别名生效；practice 排行数字 loginId 返回真实昵称（提案① §4 验收项，AuthUserDirectoryTest 5/5 + practice 29/29 实证）；**A8-P2 排行昵称已知限制闭环** |
| `notrole-mapping-gap` | **closed（2026-08-30）**——subject/practice `NotRoleException → 403` 防御性同步落地（与既有权限映射及 circle X3 先例逐字同形态；subject 102/102、practice 29/29 含 handler 单测） |
| `auth-role-check-gap` / `practice-detail-unique-index` / `pageinfo-duplication` | open 保持（另案/随后续提案评估） |

## 6. 观察项知悉（承接签署，不阻塞）

键碰撞「id 键优先」当前依赖双键插入顺序（提案① §5 登记，将来可两次遍历收严）；mock 覆盖收窄为 domain 层等价覆盖（回执已登记）；`IdentifierUserItem` 类级 description 源侧措辞待下次实现轮顺带修正；防御性 403 无自然触发端点（N2 既定，handler 单测覆盖）。

## 7. 后续

1. **前端阶段三（F-Impl 鸡圈页）任务书**：快照 `AE967C70`（74 路径）已就绪，为下一派发件（含 X2 `primaryCategoryId` 大类过滤消费）。
2. 阶段三前端回执签署并验收后推进 state `gate3-a8-phase3-*`（本验收按先例不推进 state）。
3. 阶段三整体收尾后进入阶段四（interview）评估与 A9 发布门禁（待用户授权）。

---

验收人：协调 PM，2026-08-30
