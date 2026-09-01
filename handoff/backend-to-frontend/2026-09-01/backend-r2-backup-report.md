# 回执：R2 备份/归档实施（B-Impl，③线）

> **回执角色：** 后端实现（B-Impl）
> **日期：** 2026-09-01（Asia/Shanghai）
> **任务书：** `pm/requirements/2026-08-31/r2-backup-task.md`（第二批四线之三）
> **决策依据：** 存储方案评估（2026-08-31 A 方案：Minio 主存储 + Cloudflare R2 备份/归档，零出口带宽费）+ brainstorming 澄清确认（交付边界：脚本+SOP，cron 部署由管理员执行；MySQL 与应用服务器异机→远程 mysqldump 连接串参数化；不含 Minio 快照）+ 权威源调研（Cloudflare 官方 R2+rclone、R2 生命周期、MySQL→R2 备份最佳实践）
> **设计/计划：** 后端仓库 `docs/superpowers/specs/2026-09-01-r2-backup-design.md`（1a1f813）、`docs/superpowers/plans/2026-09-01-r2-backup.md`（db77a77，随本 PR 合入）

## 1. 来源与提交哈希

| 项 | 值 |
| --- | --- |
| 实现仓库 | jackeywilders/coderclub（后端） |
| 分支 | `feat/backend-r2-backup`（基于 `a8e11ca`） |
| 实现头 | `30b27a8`（7 提交：spec + plan + T1 骨架 + T2 db + T3 logs/prune（含 fix round 1）+ T5 SOP；T4 验证无代码变更） |
| PR | **#26**（feat/backend-r2-backup → main） |
| CI | build-and-test + sensitive-scan（head `30b27a8`，run 33530426827 双绿——无 Java/pom 变更，build-and-test 快速通过） |
| 合入状态 | **R1 达成**；R2 待人工合入（用户/B-Review 在 CI 全绿后执行） |

## 2. 任务明细（对照任务书 S1-S5）

1. **S1 备份范围** ✅（脚本交付）：
   - **MySQL**：`backup.sh db` 远程 `mysqldump --single-transaction --routines --triggers --skip-lock-tables --quick` 全库 → gzip（pigz 可用优先）→ `rclone copyto r2:<BUCKET>/db/`；连接串环境变量（`MYSQL_HOST/PORT/USER/PASSWORD/DATABASE`，MySQL 与应用服务器异机——用户澄清）。
   - **日志归档**：`backup.sh logs` 按 `LOG_DIRS`（逗号分隔）按日 tar.gz（hostname+目录名安全化前缀）→ `r2:<BUCKET>/logs/`；目录缺失跳过、tar 失败不阻塞。
   - **Minio 快照** ⏸️ 本批不做（任务书"可选"；SOP §11 留扩展节：`rclone sync minio:<bucket> r2:<BUCKET>/minio/`）。
2. **S2 工具与配置（rclone，S3 兼容）** ✅：
   - rclone remote `r2`（`type=s3`、`provider=Cloudflare`、`endpoint=https://<ACCOUNT_ID>.r2.cloudflarestorage.com`、`acl=private`）；**密钥由管理员服务器侧 `rclone config` 加密存储**（或 `RCLONE_CONFIG_R2_*` env）——脚本/模板零真实凭据（规则 8）。
   - **强制 IPv4**：R2 实测 IPv6 不通 → SOP §4（/etc/gai.conf 优先 IPv4 或 sysctl 禁用 IPv6），管理员部署步骤。
   - multipart 并发：rclone 默认分片（SOP 注明 `--s3-upload-cutoff/chunk-size` 成本注意）；产物已压缩。
3. **S3 调度与保留** ✅（部署由管理员）：
   - `backup.cron` 示例（每日 02:30）→ SOP §6 注册指引。
   - **R2 保留**：生命周期规则（`db/` 30 天、`logs/` 7 天）由管理员在 R2 控制台/S3 API 配置（SOP §7）；脚本 `prune` 仅管**本地保留 3 份**滚动（`BACKUP_KEEP_DB`）。
4. **S4 验证** ✅：
   - 上传校验：非 dry-run `rclone size` 确认对象存在 + 大小（脚本内）。
   - **dry-run**：`--dry-run` 全子命令演练（打印命令不执行）；本地 Git Bash 验证通过（bash -n + db/logs/prune 三子命令 + prune 模拟样本 5 份保留 3 份 + 空目录无算术错误）。
   - **恢复演练**：SOP §9 完整步骤（`rclone copy` → `gunzip` → `mysql` 导入临时库验证可读 + 演练登记表）——**首次实施后由管理员执行一次**（交付边界）。
   - **失败告警**：cron 日志重定向 + SOP §10（MAILTO / webhook 示例思路）。
5. **S5 质量门禁** ✅：`bash -n` + dry-run 演练 + 模拟样本（task-4 报告）；文档 SOP 落后端 `docs/ops/`；CI 双绿；回执双轨（**含 receiptCommitSha**）。

## 3. 测试证据

- `bash -n scripts/backup/backup.sh` 通过（git-bash.exe + 原生 bash.exe 复核 exit 0）。
- `--dry-run` db/logs/prune 三子命令演练通过（Git Bash，占位 env）；prune 模拟：5 份保留 3 份删除最旧 2 份；空目录打印「本地 0 份 ≤ 保留 3 份」无算术错误（fix round 1：`|| true` 兜底 pipefail 双行缺陷——实现者实证微调裁定方案，复审 ADDRESSED）。
- 审查链：brainstorming（交付边界/MySQL 异机/不含 Minio）→ SDD 执行（T1-T5 子代理 + 任务审查，1 个 fix round：prune 空目录计数）→ 定向复审 ADDRESSED；T4 验证无代码变更。
- 权威源对齐：Cloudflare 官方 R2+rclone（[developers.cloudflare.com/r2/examples/rclone](https://developers.cloudflare.com/r2/examples/rclone/)）、R2 生命周期（[object-lifecycles](https://developers.cloudflare.com/r2/buckets/object-lifecycles/)）、MySQL→R2 备份最佳实践（[ashleyrich.com](https://ashleyrich.com/blog/mysql-backups-cloudflare-r2)）。

## 4. 边界遵守声明（任务书 §2）

- Minio 业务链零改动（主存储不动）；R2 仅备份/归档。
- R2 凭据/endpoint 全占位符（规则 8：backup.env.example 零真实值，SOP 79 处 `<...>` 占位）；强制 IPv4 由 SOP 部署步骤承载；rclone 为运维工具脚本层，无新业务依赖。
- 未改 `api/` 快照与 `status/`；Conventional Commits；未改交接仓库治理文件/其他角色目录。

## 5. 已知限制与延后项（openFindings）

1. **cron 部署/真实备份/恢复演练由管理员执行**（交付边界裁定）：rclone 密钥配置、放脚本、注册 crontab、R2 生命周期规则、首次恢复演练——SOP §3-9 指引，B-Impl 未执行。
2. **dry-run db 回显落点**：`run mysqldump ... > file` 重定向使 dry-run 回显写入产物 .sql（并创建空占位文件）——`run` 包装对 shell 重定向不可见的已知取舍（任务 1/2 Minor 登记），真实执行重定向正确，无实际影响。
3. **凭据进程列表可见**：`-p"$MYSQL_PASSWORD"` 使密码短暂见于进程 cmdline——环境变量取值（非硬编码），MySQL 命令行固有特性；后续可评估 `MYSQL_PWD` 替代（Minor）。
4. **`rclone size` 校验仅 log 不门禁**：对象缺失/0 字节仍打印"备份完成"——简报层设计（校验失败即 fail 可在后续收紧）。
5. **SOP 细节张力**（任务 5 Minor）：GRANT 示例无条件授 SHOW VIEW/TRIGGER 与"视需要"说明略有张力；webhook 示例 Content-Type 与 text/plain 不符（已标注示例思路）——非阻塞，后续可润色。
6. **`MYSQL_*`/`R2_BUCKET` 全局 `:?` 校验**使 prune/logs 也依赖 DB env（任务 3 Minor）——可选优化：按子命令校验所需变量。

## 6. 后续链

1. B-Review 复核签署 → PM 验收。
2. 合入提醒：PR #26 CI 双绿（run 33530426827），**合入由人工（用户/B-Review）在 GitHub 执行**。
3. 管理员后续动作（SOP 指引）：服务器 rclone 配置 + 放脚本 + crontab 注册 + R2 生命周期规则 + 首次恢复演练——完成后回执可更新演练记录。
4. 同批衔接：r2-backup 为四线之三收官（②redis-integration 已完成）；interview 后端/前端（同批三线）推进中。

---
- 回执角色：后端实现（B-Impl），2026-09-01
