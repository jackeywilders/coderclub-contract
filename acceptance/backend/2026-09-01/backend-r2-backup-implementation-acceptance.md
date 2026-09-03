# R2 备份/归档（R2-BACKUP，③线）——PM 验收

> 验收角色：协调 PM
> 验收日期：2026-09-01
> 回执：`handoff/backend-to-frontend/2026-09-01/backend-r2-backup-report.md` + `-summary.json`（PR #163，**impl/backend 稳定分支直提**——分支治理新规首次实践，`receiptCommitSha=5000e1f` + 修正 `c86406c`，已合入 main）
> 复核签署：`acceptance/backend/2026-09-01/backend-r2-backup-review-signoff.md` + 工作底稿 `designs/backend/2026-09-01/backend-r2-backup-review-workpaper.md`（PR #165，**review/backend 稳定分支直提**，merged，MCP 核验；含 chinese-code-review 分级意见）
> 状态：**验收通过**

## 1. 验收结论

✅ **R2-BACKUP 验收通过。** 实施 `30b27a8`（7 commits，经 CoderClub PR #26 合入 main `64fffaed`）经 B-Review 复核签署（PR #165，Code Review：无 [必须修复]）与 PM 独立核验，与任务书 `pm/requirements/2026-08-31/r2-backup-task.md` 相符——Bash 备份脚本（db 远程 mysqldump→gzip→rclone copyto R2 / logs 按日 tar.gz / prune 滚动 + `--dry-run`）+ 配置模板 + cron 示例 + 恢复 SOP（11 节，rclone Cloudflare + 强制 IPv4 + R2 生命周期）。**本批快照零变更**（openapi 75→75，纯运维脚本+文档）；**交付边界**：真实 cron 部署 / rclone 密钥 / R2 生命周期 / 首次恢复演练由管理员按 SOP 执行（用户裁定，openFinding 登记，不阻塞本批验收）。

## 2. 规则 9 核验链（四字段）

| 字段 | 值 |
| --- | --- |
| 实施提交 SHA | `30b27a8`（`30b27a81699421d07a681f906d9ec50d8f775319`，7 commits） |
| 合并提交 SHA | `64fffaed`（CoderClub PR #26 merge，2026-09-01T16:39:44Z，合并人 JackeyWilder） |
| 回执提交 SHA | `5000e1f`（PR #163，merge `c86406c`；**impl/backend 直提**，已合入 main） |
| PR 号 | CoderClub #26（merged `64fffaed`）；交接仓库回执 #163、签署 #165（均 merged，**新分支直提**） |
| R2 状态 | ✅ 双达成：实施合入 CoderClub main（`64fffaed`）；回执/签署均合入交接仓库 main |
| CI | run `33530426827` 双绿：build-and-test（job 99931888539 success）+ sensitive-scan（job 99931888139 success） |

## 3. PM 独立复核（非签署转录）

1. **实施 R2 实测（远端 main）**：CoderClub PR #26 已合入 main（merge `64fffaed`，合并人 JackeyWilder，16:39:44Z）；CI 双绿逐 job 核验（run 33530426827）；PR 6 files（scripts/backup/backup.sh + env 模板 + cron + docs/ops/backup-restore-sop.md + specs/plans），**0 Java/pom 变更**——openapi 零变更确认。
2. **签署链实测（分支治理新规落地）**：交接仓库 PR #163（`impl/backend` 直提，回执 `5000e1f`）+ PR #165（`review/backend` 直提，签署 `084ef5e`）均合入 main——**2026-09-01 分支治理新规（稳定分支直提、不再一次性 receipt 分支）在 B-Impl/B-Review 双侧首次实践成功**。
3. **源契约实测（远端 main）**：openapi 75→75 无变更；本批为运维脚本 + SOP，不涉契约源。
4. **快照处理（零变更）**：快照保持 `ADCCD073`（75 路径 / 119 schemas），与源 diff = **12 项**（构成不变）；无挂起端点项。
5. **交付边界确认**：脚本 + SOP 已交付；cron 部署 / rclone 密钥配置 / 服务器放脚本 / R2 生命周期规则 / 首次恢复演练由管理员（用户）按 SOP §3-9 执行——首次演练后在 SOP §9 登记（B-Review 提请）。此边界属既定交付裁定，不构成阻塞。
6. **敏感扫描**：env 模板全占位符（规则 8）；回执/签署全文无真实 IP/凭据。

## 4. 快照微同步登记（本批零变更）

| 项 | before | after |
| --- | --- | --- |
| sourceSha256（LF） | `57C2D6EE…` | `57C2D6EE…`（不变，本批不涉契约源） |
| snapshotSha256 | `ADCCD073…` | `ADCCD073…`（不变） |
| pathCount / operationCount | 75 / 75 | **75 / 75**（不变） |
| semanticDifferenceCount | 12 | **12**（构成不变） |

## 5. Code Review 意见与延后项登记（承接签署 §2/§4，均不阻塞）

| # | 项 | 级别/处置 |
| --- | --- | --- |
| 1 | db 子命令 dry-run：`> file` 重定向吞回显 + 残留空 .sql | [建议修改]——下个批次 dry-run 重定向 `/dev/null` 或 echo 走 stderr，登记 |
| 2 | `-p"$MYSQL_PASSWORD"` 命令行凭据进程可见 | [建议修改]——SOP 已 chmod 600 + 单机管理面缓解；建议改用 `MYSQL_PWD` 环境变量，登记 |
| 3 | cmd_logs 注释「仅当日」与实现不符；rclone size 校验 grep 脆弱不门禁 | [仅供参考]，登记，接受 |
| 4 | cron 部署 / 恢复演练属管理员交付边界 | 首次演练后在 SOP §9 登记，不阻塞 |

## 6. 后续

1. **管理员部署**：按 `docs/ops/backup-restore-sop.md` §3-9 执行 rclone 密钥配置、服务器放脚本、注册 crontab、R2 生命周期、首次恢复演练（演练后 SOP §9 登记）——属用户运维动作，非本批验收阻塞项。
2. **Minio 快照扩展节**：未来批次（SOP §11）。
3. **[建议修改] 2 项**：随下个迭代批次统一（dry-run 重定向 + MYSQL_PWD）。
4. **第二批四线全部完成**：④isRead ✅ ①Meili ✅ ②Redis ✅ ③R2 ✅。剩余推进项：**interview 后端/前端**（同批三线），后端待 Nacos 配置模板真实值；前端待后端端点落地后微同步（75→83 + rebuild 端点）。

## 7. 修复闭环补记（2026-09-03）

R2-BACKUP 的 B-Review Code Review 意见（2 建议修改 + 2 仅供参考）已由 B-Impl 以 CoderClub **PR #28**（head `56b55d5`，1 commit 改 `scripts/backup/backup.sh`）全部处理并合入 main（merge `5e50ead6`，2026-09-03T04:39:24Z，R2 达成，CI 双绿 run 33535341606）：

- **[建议修改]** db dry-run 重定向改 `/dev/null`（无残留空 .sql，实测 dry-run 前后 db/ 文件数不变）+ 回显 `MYSQL_PWD=***` 打码；
- **[建议修改]** 凭据改 `MYSQL_PWD` 环境变量传递（避 `/proc/<pid>/cmdline` 可见）；
- **[仅供参考]** logs 注释「仅当日」→ 对齐实现「打包目录全部内容（按日命名区分）」；
- **[仅供参考]** rclone size 校验升级硬门禁（对象大小 0 Byte / 无法获取 Total size → fail，仅成功才 log OK）。

B-Review 复核：4 项全部到位、无 [必须修复]；PR #28 已合入（R2 达成）。**R2-BACKUP 意见闭环，验收记录收口。**

---

验收人：协调 PM，2026-09-01
