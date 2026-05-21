# OUTBUGBRO — 项目总结

> Godot 4.5.1 · Mobile 渲染器 · 2D 俯视角生存射击

---

## 🎮 游戏概述

玩家操控一个固定炮台，面对无尽波次的怪物。通过拾取掉落物品、升级属性、购买技能来提升战斗力，尽可能撑到更高波次获得更高评分。

**核心循环：** 击杀怪物 → 获得金币 + 物品 → 升级/购买技能 → 挑战更高波次

---

## 🏗️ 架构总览

### Autoload 全局单例

| 单例 | 功能 |
|------|------|
| `EventBus` | 字符串事件总线，`listen/unlisten/dispatch`，松耦合通信 |
| `GameManager` | 全局状态机（MENU/PLAYING/PAUSED），暂停/恢复，场景切换 |
| `InventoryManager` | 背包数据层，7×5网格，同id堆叠，消耗品快捷槽绑定 |
| `EffectManager` | 状态效果管理，倒计时/永久，同id刷新不叠加 |
| `CurrencyManager` | 全局金币管理，`add/spend/has_enough`，changed信号 |
| `ComboManager` | 2秒连击窗口，每级+5%掉率，上限50% |
| `SkillManager` | 技能解锁/激活/冷却管理，skill_activated信号 |
| `SaveManager` | JSON存档，`save_run/load_run/reset_run/full_reset/clear_runtime`，评分计算 |

### 组件体系（core/components/）

| 组件 | 功能 |
|------|------|
| `Component` | 基类，`entity` 宿主引用，`_setup/_tick` 虚方法 |
| `HealthComponent` | HP管理，`take_damage/heal/set_max_hp/set_hp`，`health_changed/died` 信号 |
| `ShootingComponent` | 瞄准（AUTO/MOUSE）+ 射击，蓄力系统（普通/重蓄力），磁力效果 |
| `MoveComponent` | 向目标移动，`apply_knockback/apply_slow` |
| `AttackComponent` | 定时攻击，`try_attack(target)` |
| `TrailComponent` | 对象池拖尾粒子（全局60个ColorRect复用） |
| `PlayerStats` | 属性系统，HP/ATK/DEF/CRIT/CD/SPD，效果加成，暴击计算 |

### 数据资源（data/）

| 目录 | 内容 |
|------|------|
| `data/effects/` | 10个效果 .tres（heal_50/speed_30/power_up等） |
| `data/items/` | 11个物品 .tres（普通/稀有/史诗/传说各级别） |
| `data/skills/` | 7个技能 .tres（shield/reflect/repair/missile/head_oil/double_shot/magnet） |
| `data/wave_config.tres` | 波次参数（怪物HP/ATK/速度/生成间隔/掉落率等） |
| `data/player_config.tres` | 玩家属性升级配置（各属性初始值/升级费用/升级量） |

---

## ⚔️ 核心系统

### 射击系统
- **AUTO模式**：自动瞄准最近敌人，lerp旋转
- **MOUSE模式**（Shift切换）：鼠标瞄准，瞬间朝向
  - 左键/右键均可触发蓄力
  - 0.3~1.5s：普通蓄力（2-3x伤害，穿透3目标）
  - 1.5~5.0s：重蓄力（5-7x伤害，穿透5目标，W7+解锁）
  - 蓄力弹 W5+ 有爆炸溅射
  - 重蓄力触发屏幕轻微抖动

### 波次系统
- **FIGHTING → BREAK → FIGHTING** 状态机
- 每波60秒，5秒休息期，清波金币奖励
- 精英怪：10%概率，HP×3，体型1.5倍，金色外观，必掉稀有+物品
- 生成间隔随波次加快（最快0.3秒），最多30只同屏

### 掉落系统
- 加权随机掉落表（程序化构建，11种物品）
- 品质视觉反馈：传说→金色光柱，史诗→紫色脉冲，稀有→青色闪烁
- 连击加成最高+50%掉率

### 技能系统（共7个）

| 技能 | 解锁条件 | 费用 | CD | 效果 |
|------|---------|------|-----|------|
| 临时护盾 | W3 | 1000g | 20s | 5s免疫伤害 |
| 主动防御 | W7 | 1500g | 80s | 8s内75%反伤+80%减伤 |
| 应急修理 | W10 | 4500g | 120s | 回血90%+10s极大属性增幅 |
| 制导导弹 | W15 | 18000g | 200s | 全屏清怪+20s即死光环 |
| 头油 | 免费 | - | 30s | 击退+减速附近敌人 |
| 双发 | W10 | 10000g | 60s | 60s内蓄力弹双发 |
| 磁力拉拽 | W8 | 5000g | 30s | 15s内蓄力时间减半+敌人聚拢 |

### 存档系统
- 自动存档（每波休息期）
- 存档内容：波次/金币/背包/技能解锁/属性升级/最高分
- 死亡只更新最高分，其余清零
- 主菜单支持继续游戏/新游戏/取消

### 评分系统

| 评分 | 条件（波次） |
|------|------------|
| C | < 6波 |
| B | 6波 |
| A | 7-8波 |
| S | 9-11波 |
| SS | 12波 |
| SSS | 13波 |
| SSS+ | 14波 |
| SSS+⭐×N | ≥15波（每多1波+1星） |

---

## 🖥️ UI 系统

| 界面 | 说明 |
|------|------|
| 主菜单 | iOS暗色风，粒子雨背景，闪电特效，呼吸标题，毛玻璃按钮 |
| 背包（B键） | 7×5格子，点击查看详情，hover显示名称，消耗品快捷绑定，售卖功能 |
| 技能栏 | 底部7技能+5消耗品格子，CD进度遮罩，数字键激活 |
| 属性面板 | 右下角实时显示HP/ATK/DEF/CRIT/CD/SPD |
| 波次显示 | 当前波次/倒计时/存活敌人/连击/掉率加成 |
| 效果栏 | 右上角激活效果图标+倒计时+点击详情 |
| 死亡界面 | 评分+彩虹SSS+动效+本局统计+重开/返回菜单 |
| 暂停菜单 | ESC触发，暂停时锁定技能/背包操作 |
| 血条 | 左下角Target血量，信号驱动无轮询 |

---

## ⚡ 性能优化

| 优化项 | 方法 |
|--------|------|
| 子弹拖尾 | 静态对象池（80个ColorRect复用），间隔0.05s（减少60%节点） |
| 伤害数字 | 静态对象池（20个Label复用），限制3个同时显示 |
| 拖尾组件 | 全局静态池60个，ACTIVE_MAX=15限制每实体同时存在数 |
| 存活计数 | `_enemies_alive` 计数器替代每帧 `get_nodes_in_group()` |

---

## 📁 目录结构

```
core/
  autoload/     → 8个全局单例
  base/         → 基类（Component/ItemData/EffectData/DropTable等）
  components/   → 6个组件
data/
  effects/      → 10个效果.tres
  items/        → 11个物品.tres
  skills/       → 7个技能.tres
  drop_tables/  → 默认掉落表
scenes/
  world/        → 核心游戏场景（target/bullet/enemy_spawner等）
  enemies/      → 敌人场景
  ui/           → 所有UI场景
  main_menu.tscn
assets/         → SVG图标
```

---

## 🔧 常见踩坑

- **`class_name` vs Autoload**：Autoload单例自动注册全局名，脚本里不能再写 `class_name`
- **`:=` 三元表达式**：Godot无法推断三元/复杂表达式类型，必须显式 `: Type =`
- **Container `mouse_filter`**：`HBoxContainer` 等默认 `STOP`，全屏容器会挡住所有点击，必须设 `IGNORE`
- **`set_deferred` 时序**：`add_child()` 立即触发 `_ready()`，数据要在 `add_child` 前赋值
- **`Resource.name`**：Resource没有 `.name` 属性（那是Node的），用自定义字段如 `skill_name`
- **手写 `.tres` 不可靠**：含嵌套数组的资源用程序化构建更稳定
- **`ShootingComponent.enabled`**：Node没有该属性，禁用用 `set_physics_process(false)`
- **子弹方向**：`bullet.rotation` 只控制朝向，移动方向需 `direction = Vector2.RIGHT.rotated(rotation)`
