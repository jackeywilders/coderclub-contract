# 任务书：GitHub Actions + SSH 云端 CI/CD 部署（CoderClub 后端 + 前端）

> 派发角色：协调 PM
> 派发日期：2026-08-31
> 执行角色：后端实现（B-Impl 起草 workflow/systemd/脚本模板）+ 用户（服务器一次性准备，A1 模式）
> 决策依据：grill 共识（Q1-Q4 + 登记项 Q5-Q11，2026-08-31 逐项确认）+ brainstorming 分节设计批准
> 方案选型（权威源调研）：GitHub Actions（托管，0 元/2000 分钟/月，零服务器占用）+ SSH 部署——低成本便携，替代 Jenkins；自托管 runner 2026-03 起按分钟计费且占服务器资源（排除）；国内镜像（Gitee/CODING）备选登记
> 依据手册：`.dsh-filess/.../GitHub-Actions-CI-CD-部署手册.md`（架构/安全/回滚模式）

## 1. 整体架构

```
GitHub（云构建，0 元）                       火山云服务器（仅 SSH 22 入站）
├─ 后端 workflow（单 workflow 聚合 7 服务）      ├─ deploy 用户 + sudoers 白名单
│   mvn package → scp app.jar.new              ├─ /opt/coderclub/{service}/app.jar
├─ 前端 workflow（独立）                        ├─ systemd unit × 7（JVM 参数内嵌）
│   npm ci → lint/build/api:check → rsync      ├─ nginx（前端 dist + 反代 :5000 网关）
触发：workflow_dispatch 手动为主 + push main 可开关（paths 过滤）└─ Nacos（dev 命名空间，配置下发）
```

## 2. 后端 workflow（`CoderClub/.github/workflows/deploy.yml`，B-Impl 起草）

- **触发**：`workflow_dispatch` + `push: main`（**`paths` 白名单 + `paths-ignore` 黑名单**，防文档/脚本/本地配置误触发浪费分钟）：
  - `paths: ['coder-club-*/**', 'pom.xml']`
  - `paths-ignore: ['docs/**', '**/*.md', 'start-*.ps1', '**/application*.yml', '.github/**']`
  - 手动 `workflow_dispatch` 不受 paths 限制
- **步骤**：`actions/checkout@v4` → `actions/setup-java@v4`（temurin 17 + `cache: maven`）→ `mvn -B -DskipTests package`（根聚合，jar 名 = artifactId）→ 设 SSH（`SSH_KNOWN_HOSTS`/`SSH_PRIVATE_KEY` Secrets）→ 逐服务 `scp target/<service>.jar → /opt/coderclub/<service>/app.jar.new` → `ssh … sudo /usr/local/bin/deploy-backend.sh <service>`
- 仅官方 actions（`actions/*`），不引入第三方部署 Action（供应链安全）

## 3. 服务器准备（一次性，用户执行 A1 模式；B-Impl 提供模板）

1. `deploy` 低权限用户；目录 `/opt/coderclub/{auth,subject,practice,circle,oss,gateway,interview}` + `/var/www/frontend`（owner deploy）
2. 部署 SSH 密钥：本机 `ssh-keygen -t ed25519` → 公钥 `ssh-copy-id` 服务器 → 私钥存 GitHub Secrets（不入库）；`ssh-keyscan -H` 存 `SSH_KNOWN_HOSTS`
3. systemd unit × 7（模板见 §4）+ nginx（前端 `try_files` history 回退 + 静态长缓存 + `proxy_pass http://127.0.0.1:5000` 反代网关）
4. SSH 加固（确认密钥可用后：禁密码登录/禁 root）+ 安全组仅 22/80/443

## 4. systemd 单元 + 部署脚本（热替换机制）

**systemd（`/etc/systemd/system/coderclub-<service>.service`，JVM 预算内嵌）**
```ini
[Service]
User=deploy
WorkingDirectory=/opt/coderclub/<service>
ExecStart=/usr/bin/java -Xms128m -Xmx256m -XX:MaxMetaspaceSize=256m -jar app.jar --spring.profiles.active=dev
Restart=on-failure
RestartSec=5
NoNewPrivileges=true ProtectSystem=full ProtectHome=true PrivateTmp=true
```
- JVM 预算：gateway/auth/oss `-Xmx256m`；subject/practice/circle/interview `-Xmx384m`（代码评估定案，不影响正常运作）
- 配置：Nacos（dev 命名空间）下发，unit 不内置敏感值

**`deploy-backend.sh <service>`（root 所有，deploy 经 sudoers 白名单执行）——jar 热替换防冲突**
1. `cp app.jar app.jar.bak`（保留旧版回滚）
2. `mv app.jar.new app.jar`（**原子替换**，临时名上传不直接覆盖运行中文件）
3. `systemctl restart coderclub-<service>`
4. `is-active` 校验 + 端口健康检查；**失败自动回滚**（还原 `.bak` + restart）
5. 输出 MainPID；失败让 workflow 显示部署失败

## 5. 前端 workflow（`CoderClubFront/.github/workflows/deploy.yml`，独立仓库）

- 触发：`workflow_dispatch` + `push: main`（`paths: ['src/**', 'package.json', 'package-lock.json', 'index.html', 'vite.config.*', 'tsconfig*.json', 'public/**']` + `paths-ignore: ['docs/**', '**/*.md', '.github/**']`）
- 步骤：`checkout@v4` → `setup-node@v4`（node 20 + `cache: npm`）→ `npm ci` → **门禁**：`npm run lint` + `npm run build` + `npm run api:check`（基于仓库 local spec，基线 75/后续 83）→ 设 SSH → `rsync --delete -e "ssh -i ~/.ssh/deploy_key" dist/ deploy@<host>:/var/www/frontend/` → `nginx -s reload`
- 回滚：重跑历史 commit

## 6. Secrets（两仓库各配）

`SSH_HOST` / `SSH_USER`(deploy) / `SSH_PRIVATE_KEY`（完整私钥含尾换行）/ `SSH_KNOWN_HOSTS`（固定指纹防中间人）

## 7. 质量门禁与验证

- workflow YAML 语法校验；`mvn package` 本地先行验证产物名；deploy 脚本 dry-run + 首次真实部署验证（后端服务注册 Nacos + 网关联调；前端 nginx 访问）
- 文档/启动脚本/本地配置变更**不触发**（paths 过滤验证）；手动 dispatch 不受限
- 回滚演练（部署后 `cp .bak` 回滚验证）；安全清单逐项勾选（照手册 §7）
- 回执双轨（含 `receiptCommitSha`）+ 四字段

## 8. 关联

- grill 共识（Q1-Q11）· 手册（架构/安全/回滚）· JVM 预算（database-init-landing L5）· Nacos 配置前置（interview）· 阶段四配套批次
