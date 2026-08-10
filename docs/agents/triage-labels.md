# Triage 分类标签

本仓库使用 `triage` 技能的默认标签，不创建同义或重复标签。

| 标签 | 含义 | 转入条件 |
| --- | --- | --- |
| `needs-triage` | 新建后等待分诊 | 尚未确认范围、优先级或负责人 |
| `needs-info` | 等待补充信息 | 缺少复现条件、日志、提交哈希、契约或业务背景 |
| `ready-for-agent` | 可以交给 Agent 执行 | 范围、输入、约束和验收标准已明确 |
| `ready-for-human` | 等待人工决策 | 涉及产品取舍、权限、发布、凭据或不可逆操作 |
| `wontfix` | 确认不处理 | 不属于当前范围，或明确接受不修复 |

## 推荐流转

```text
needs-triage → needs-info → ready-for-agent
                    └──────→ ready-for-human
                    └──────→ wontfix
```

`ready-for-human` 和 `wontfix` 需要在 Issue 中记录决策依据。完成后的 Issue 应补充验证结果和相关提交哈希，再按团队现有关闭流程归档。
