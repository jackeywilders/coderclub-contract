# R2-BACKUP R2 备份/归档——后端评审复核工作底稿（含 Code Review）

> 角色：后端评审（B-Review）
> 日期：2026-09-01
> 任务书：`pm/requirements/2026-08-31/r2-backup-task.md`；交付边界（用户裁定）：脚本 + SOP 文档，cron 部署由管理员执行
> 回执：`handoff/backend-to-frontend/2026-09-01/backend-r2-backup-report.md` + `-summary.json`（PR #163，**经 impl/backend 稳定分支直提**——分支治理新规首次实践；回执 `5000e1f` + 修正 `c86406c`）
> 实施：CoderClub PR #26（head `30b27a8`，7 commits；**本会话复核 + Code Review 通过后已合入 main `64fffaed`，R2 达成**）
> 审查方式：按 `/chinese-code-review` 技能流程（分级标注）；本批 0 Java/pom 变更，验证 = bash -n + dry-run 演练 + prune 模拟（Git Bash 实跑）

## 1. 人链核验：实施提交存在性与一致性

| 项 | 证据 | 结果 |
| --- | --- | --- |
| 提交对象 | `git cat-file -t 30b27a8` 成功（走 7892 代理 fetch `feat/backend-r2-backup`）；远端 PR #26 head 与本地对象一致 | ✅ |
| CI | PR #26 head `30b27a8`：build-and-test ✅（job 99931888539，run 33530426827，无 Java 变更快速通过 10s）+ sensitive-scan ✅（job 99931888139）——GitHub API 逐 job 核实 | ✅ |
| 提交数 | **7 commits**（spec + plan + 骨架/配置/cron + db + logs/prune + SOP + 审查修复）——与回执一致 | ✅ |
| summary 一致性 | `implementationCommitSha=30b27a8`、`receiptCommitSha=5000e1f`（修正 `c86406c`）、PR #26、openapi 75→75 无变更 | ✅ |
| 回执方式 | **经 `impl/backend` 稳定分支直提**（分支治理新规：不再创建一次性 `*-receipt` 分支），PR #163 已合入 main（merged 16:20:26） | ✅ |
| PR #26 合入 | 本会话独立复核（CI 双绿 + Code Review + 本地 bash 验证全过）后以 merge 方式合入 main（merge `64fffaed`，B-Review 授权合入人身份）——**R2 达成**（main tip 核验 `64fffaed`） | ✅ |

## 2. 代码级 Code Review（逐文件，附着 `30b27a8`）

### 2.1 `scripts/backup/backup.sh`（132 行 Bash 单脚本）

| 核对项 | 证据 | 结果 |
| --- | --- | --- |
| **骨架** | `set -euo pipefail`；`backup.env` 优先 source（SC1091 disable）；`: "${VAR:?未设置}"` 强制必填 + `:=` 缺省；`--dry-run` 前置解析 + shift；子命令分发 case；`run()` 包装（dry-run 打印 / 真实执行） | ✅ |
| **db 子命令** | 远程 `mysqldump --single-transaction --routines --triggers --skip-lock-tables --quick` 全库 → gzip/pigz（优先多核）→ 空产物守卫（`[[ -s ]] || fail`）→ `rclone copyto` → `rclone size` 校验（grep Bytes，`|| true` 兜底不门禁）；连接串全环境变量参数化（规则 8） | ✅ |
| **logs 子命令** | `LOG_DIRS` 逗号分隔循环；目录不存在跳过（容错）；目录名安全化（`tr '/:' '__'`）；tar 失败不阻塞整体（`continue`）；hostname+安全目录名+日期命名 | ✅ |
| **prune 子命令** | 按 mtime 排序保留 `BACKUP_KEEP_DB`（默认 3）份；`total` 计算 `|| true` 兜底（fix round 1：空目录无算术错误）；dry-run 打印 `rm -f` 不真删 | ✅ |
| **错误处理** | `fail()` stderr ERROR + exit 1；db 关键步骤 `|| fail`（dump 失败/gzip 空产物）；set -e 传播 | ✅ |
| **凭据合规** | `backup.env.example` 全占位符（change-me）；脚本不引用真实值；SOP 明确密钥交互输入加密落盘（rclone config） | ✅ |

### 2.2 其他交付物

| 文件 | 核对项 | 结果 |
| --- | --- | --- |
| `backup.env.example` | 全占位符模板（MYSQL_*/R2_BUCKET/BACKUP_DIR/LOG_DIRS/BACKUP_KEEP_DB/RCLONE_BIN），凭据不落盘 | ✅ |
| `backup.cron` | 每日 02:30 示例；`db && logs` 短路（DB 备份优先）；日志重定向 | ✅ |
| `docs/ops/backup-restore-sop.md` | 11 节完整：架构（MySQL 异机→gzip→rclone→R2 双链路）/前置（rclone + MySQL 最小权限账号 + R2 token）/rclone 配置（provider=Cloudflare + endpoint + acl=private）/强制 IPv4（gai.conf 优先 / sysctl 二选一，R2 实测 IPv6 不通）/部署（/opt/coderclub-backup + chmod 600）/cron 注册/R2 生命周期（db/ 30 天 + logs/ 7 天，二选一兜底 rclone --min-age）/验证/恢复演练（临时库隔离 + zcat 管道）/失败告警（MAILTO + webhook 思路）/Minio 扩展节（本批不做） | ✅ |
| spec/plan | `docs/superpowers/`（B-Impl 范围） | ✅ |

## 3. 独立复验（本底稿复核时执行，附着 `30b27a8`）

Git Bash（`D:\Program Files\Git\bin\bash.exe`）实跑：

| 命令/动作 | 结果 |
| --- | --- |
| `bash -n backup.sh` | **exit 0，语法通过** |
| `--dry-run db` | 打印 gzip + rclone copyto（⚠️ 见 §4 Code Review 意见 1：mysqldump 回显被重定向吞掉） |
| `--dry-run logs` | 打印 tar + rclone copyto ✅ |
| `--dry-run prune`（5 份假 dump） | 正确打印删除最旧 2 份（fake-2/fake-1，mtime 顺序正确）✅ |
| `prune` 空目录 | `0 ≤ 3，无需清理`，无算术错误 ✅ |
| `prune` 真实执行 | 删 2 保留 3，剩余 3 份 ✅ |
| openapi | 零变更（PR 文件清单无 openapi）✅ |

## 4. Code Review 意见（分级标注）

| 级别 | 项 | 说明 | 处置 |
| --- | --- | --- | --- |
| [建议修改] | **db 子命令 dry-run 回显丢失 + 空 .sql 残留** | `run mysqldump ... > "$BACKUP_DIR/db/$stamp"` 的重定向在 dry-run 下仍创建空 .sql 文件，且 `run()` 的 `[dry-run] mysqldump ...` echo 输出被重定向吞入文件（终端不可见）。回执 openFinding 记为"dry-run 回显落点取舍"，实为重定向副作用缺陷 | 不阻塞本批（dry-run 仅演练、空 .sql 无害、prune 不清理 .sql 残留）；建议下个批次：dry-run 时重定向目标改 `/dev/null` 或 `run()` echo 走 stderr 保持终端可见 |
| [建议修改] | **`-p"$MYSQL_PASSWORD"` 命令行凭据进程可见** | `ps` 可读到 mysqldump 参数中的密码。回执 openFinding 已登记"`-p` 凭据进程可见" | 不阻塞（SOP 明确 backup.env chmod 600 + 服务器单机管理面）；建议改用 `MYSQL_PWD` 环境变量（mysqldump 支持）消除进程列表泄露 |
| [仅供参考] | `cmd_logs` 注释"仅当日修改的文件"与实现不符 | `tar -czf` 打包整个目录（非按 mtime 过滤）；注释误导 | 后续可改注释或按 `--newer-mtime` 过滤，登记 |
| [仅供参考] | `rclone size` 校验 grep 解析脆弱（`|| true` 不门禁） | 校验失败仅 log unknown，不阻断（回执已登记"校验不门禁"） | 接受（备份主链路 rclone 本身失败已由 set -e 阻断） |

**无 [必须修复]。** 整体评价：运维脚本设计规范（set -euo pipefail、必填校验、dry-run 演练、规则 8 占位合规、SOP 完整），交付边界清晰（cron 部署/恢复演练由管理员执行）；实测三子命令 dry-run + prune 滚动语义正确。

## 5. 延后项核查（回执 openFindings，均不阻塞）

cron 部署/真实备份/恢复演练（交付边界，管理员按 SOP 执行）；dry-run 回显落点（§4 [建议修改] 1）；`-p` 凭据进程可见（§4 [建议修改] 2）；rclone size 校验不门禁；SOP 细节张力 ×2；全局 `:?` 校验依赖——全部登记，接受。

## 6. 复核结论

**通过，签署。** 回执声明（7 提交、S1-S5、bash -n + dry-run 验证、prune 模拟、openapi 零变更、impl/backend 直提）与人链核验、Code Review 实读、本地 bash 验证逐项一致；PR #26 已按授权合入 main（`64fffaed`），R2 达成。无 [必须修复]；[建议修改] 2 项（dry-run 重定向、-p 凭据）不阻塞，随下个批次。

## 7. 关联

- 任务书 · 交付边界裁定 · 回执 PR #163（impl/backend 直提，merge 已确认）· 实施 CoderClub PR #26（merged `64fffaed`）
- 后续：PM 验收 → 管理员按 SOP 执行 cron 部署/恢复演练 → Minio 快照扩展节（未来批次）→ 签署走 `review/backend` 稳定分支（分支治理新规）