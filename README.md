# OutBugBro (逃离虫哥)

> 2D 俯视角生存射击 · Godot 4.5.1 · GDScript

玩家操控固定炮台，面对无尽波次怪物，通过拾取掉落、升级属性、购买技能提升战力，挑战更高波次。

## 快速开始

1. 克隆仓库
2. 用 **Godot 4.5.1** 打开 `OutBugBro/` 目录
3. 运行主场景 `res://scenes/main.tscn`

## 文档

| 文档 | 说明 |
|------|------|
| [项目总览](OutBugBro/docs/01-game-design.md) | 游戏概述与设计 |
| [架构说明](OutBugBro/docs/02-architecture.md) | 系统架构与模块 |
| [数据修改指南](OutBugBro/docs/03-data-guide.md) | 策划数值调整 |
| [开发参考手册](OutBugBro/docs/04-developer-reference.md) | 全部函数参考 |
| [更新日志](OutBugBro/docs/05-changelog.md) | 版本历史 |

## 技术栈

- **引擎**: Godot 4.5.1 (Mobile 渲染器)
- **语言**: GDScript
- **架构**: 组件组合 + Autoload 单例 + EventBus 解耦
- **数据**: 数据驱动 (.tres Resource)，新增内容无需代码
- **存储**: JSON 存档 (`user://save_data.json`)
- **目标平台**: Windows Desktop

## 分支规范

- `main` — 稳定版本，勿直接提交
- 功能开发请在独立分支进行

---

关注遐蝶rz谢谢喵
