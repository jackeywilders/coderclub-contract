# 任务书：R2 备份/归档实施（B-Impl）

> 派发角色：协调 PM
> 派发日期：2026-08-31
> 执行角色：后端实现（B-Impl）
> 决策依据：存储方案评估结论（2026-08-31）——**A 方案：Minio 保留为主存储（国内快、零流量费），Cloudflare R2 作备份/归档**（零出口带宽费、免运维）；R2 实测：IPv4 稳定（握手 0.6s、复用后更快）、上传 3.3s/MB——**低频备份场景完全可承受**，IPv6 不可用需强制 IPv4
> 批次：阶段四配套（与 interview/搜索升级/Redis 化/数据落地同批）

## 1. 任务明细

### S1 备份范围
- **MySQL 数据库备份**：`mysqldump --single-transaction --routines --triggers`（全库）→ gzip 压缩 → 上传 R2。
- **应用日志归档**：各服务日志目录（如 `/app/*/logs`）按日打包（tar.gz）→ 上传 R2（保留最近 N 天本地）。
- **Minio 数据快照（可选）**：Minio bucket 数据经 `rclone sync`/`minio mirror` 到 R2（低频全量同步，防磁盘故障）。

### S2 工具与配置（rclone，S3 兼容）
- 采用 **rclone**（S3 兼容 + 支持 R2 端点 + 并发/分片/压缩 + 官方维护）。
- R2 remote 配置：`type=s3`、`endpoint=https://<ACCOUNT_ID>.r2.cloudflarestorage.com`、`access_key_id/secret_access_key`（**占位符，凭据由用户持有、不落盘/不入库/不入提交**）。
- **强制 IPv4**：rclone/系统网络禁用 IPv6 解析（R2 实测 IPv6 不通）——配置层强制 IPv4。
- **multipart 并发 + 压缩**：rclone 默认分片并发；备份产物已 gzip/tar.gz 压缩。

### S3 调度与保留
- 服务器 **cron 每日**（如 02:30）：MySQL dump → gzip → rclone copyto R2；日志日归档。
- **R2 生命周期规则**：备份目录保留 N 天（如 7 天日志、30 天 DB dump，按用户裁定），超期自动清理（R2 生命周期策略）。
- 本地保留策略：DB dump 本地保留 3 份滚动。

### S4 验证
- 备份成功校验：rclone 上传后校验对象存在 + 大小；cron 日志留痕。
- **恢复演练**：首次实施后做一次 dump 恢复演练（恢复至临时库验证可读），文档化恢复步骤（降级文档 `docs/` 登记）。
- 失败告警：备份失败发通知（日志 + 可选 webhook）。

### S5 质量门禁
- 备份脚本（PowerShell/Bash）本地测试通过（dry-run + 真实上传小样本验证）；文档（备份/恢复 SOP）落后端 `docs/`。
- 回执双轨（`handoff/backend-to-frontend/` 按创建日期，含 `receiptCommitSha`）+ 四字段。

## 2. 约束

- **Minio 业务链零改动**（主存储不动）；R2 仅承载备份/归档，不承载业务读写。
- R2 凭据/endpoint 占位（规则 8）；强制 IPv4（IPv6 实测不通）；不引入新业务依赖（rclone 为运维工具，脚本层）。
- 不改 `api/` 快照与 `status/`；Conventional Commits。

## 3. 关联

- 存储方案评估（2026-08-31：A 方案 Minio 主 + R2 备份）· R2 实测（IPv4 稳定/IPv6 不通/上传 3.3sMB）· 阶段四配套批次
