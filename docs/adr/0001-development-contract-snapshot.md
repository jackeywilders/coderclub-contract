# ADR-0001：批准开发契约快照作为跨项目开发权威

- 状态：Accepted
- 日期：2026-08-10
- 决策角色：PM / 跨项目协调 Codex

## 背景

后端运行时源文件为 `G:/Dev/backend/Club/CoderClub/docs/api/coderclub-openapi.json`，源提交为 `e80aaf697fecd350ad478d8fed67eb81fdf45325`，源 SHA-256 为 `44cbe709887e840174d1bdd02f32a423561013e0622b81e76c9346d2e87e265a`。

交接仓库的 `api/coderclub-openapi.json` 与源文件进行结构化比较后，发现 14 处差异，全部位于密码和 Token 示例值；路径、方法、字段、Schema、鉴权结构和操作数量没有差异。交接副本当前 SHA-256 为 `87e122b545ed529edc167b80279869205440be84e12c4407850dfa1d4ff2166b`，首次进入交接主线的提交为 `1a2aff823b3b941b6d9c0ccd8a29f40545d3eb17`。

## 决策

1. `api/coderclub-openapi.json` 经 PM 批准后，作为后续跨项目开发推进中的权威契约快照。
2. 后端项目源文件和真实服务实现仍是运行时权威来源。
3. 开发契约快照的更新必须记录来源提交、源 SHA-256、快照提交、快照 SHA-256、语义差异和验证结果。
4. Backend/Frontend/Claude Code 不得直接改写 `api/` 快照；契约变化先进入对应 `proposals/`，由 PM 评审和批准后更新。
5. 开发契约快照获批不代表 `releaseStatus` 或 `finalReleaseStatus` 已发布；发布仍需完成 Gate 0/1、M4 和 PM 发布验收。

## 影响

- Frontend 后续客户端生成和接口消费可以固定到快照提交及 SHA-256，不必复制文件或依赖未追踪的本地文件。
- 示例值脱敏属于允许的快照差异；路径、方法、字段、Schema 和鉴权结构差异必须重新进入契约评审。
- `apiContractCommit` 可指向开发契约快照提交，但不能替代 Backend 运行时源提交。

## 回滚条件

如果后续发现快照与运行时源存在未批准的结构性差异，PM 应立即冻结 Frontend 消费，回退开发契约批准状态，并要求 Backend 重新提交来源和交接证据。
