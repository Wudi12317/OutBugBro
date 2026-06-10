# 开发参考手册

> 完整函数签名与用途速查，供接手程序员快速定位和修改。

---

**目录**

1. [场景脚本](#场景脚本-scenes)
2. [UI 脚本](#ui-脚本-scenesui)
3. [数据驱动指南](#数据驱动指南如何不加代码添加新内容)
4. [踩坑速查](#踩坑速查)
5. [位移技能](#位移技能-dash)
6. [新手引导](#如何修改新手引导)
7. [金币经济](#金币经济数值速查)
8. [挑战模式](#挑战模式)
9. [射击系统](#射击系统)

> 架构总览、Autoload、基类、组件等详见 [02-architecture.md](02-architecture.md)

---

## 场景脚本 (`scenes/`)

### Target (`scenes/world/target.gd`)

玩家控制的目标，挂载组件 + 技能特效。

| 函数 | 签名 | 用途 |
|------|------|------|
| `take_damage` | `(amount: int, attacker: Node = null)` | 受击（护盾免疫/反伤/普通） |
| `_on_skill_activated` | `(skill_id: String)` | 技能激活回调 |

**技能特效**:
- `shield` → 青色光环
- `reflect` → 紫色光环 + 80% 减伤 + 75% 反伤
- `repair` → 回血 90% + emergency_buff
- `missile` → 全屏清怪
- `head_oil` → 200px 击退+减速
- `double_shot` → 青色爆发
- `magnet` → 紫色爆发

### Enemy (`scenes/enemies/enemy.gd`)

怪物基类。

| 函数 | 签名 | 用途 |
|------|------|------|
| `take_damage` | `(amount: int, _attacker = null, is_crit: bool = false)` | 受击+闪烁+伤害数字 |
| `_on_died` | `()` | 死亡回调（防重入） |
| `_drop_random_item` | `() -> ItemData` | 加权随机掉落 |
| `_drop_rare_item` | `() -> ItemData` | 精英掉落（rarity≥2） |

**精英怪**: `is_elite=true` → HP×3, 体型 1.5 倍, 金色边框

### Bullet (`scenes/world/bullet.gd`)

子弹，支持穿透/溅射/蓄力弹/拖尾。

| 函数 | 签名 | 用途 |
|------|------|------|
| `set_damage_mult` | `(mult: float)` | 设置伤害倍率（≥3 标记为蓄力弹） |
| `set_pierce` | `(count: int)` | 设置穿透数 |

### EnemySpawner (`scenes/world/enemy_spawner.gd`)

波次状态机生成器。

| 函数 | 签名 | 用途 |
|------|------|------|
| `get_wave_time_remaining` | `() -> float` | 当前波次/休息剩余时间 |
| `get_enemies_alive` | `() -> int` | 存活敌人数 |

**信号**: `wave_changed(wave)`, `wave_break(secs)`, `wave_bonus(gold)`

### DropIndicator (`scenes/world/drop_indicator.gd`)

浮动掉落提示。静态工厂方法 `spawn(parent, pos, gold, item)`

### ExplosionEffect (`scenes/world/explosion_effect.gd`)

爆裂弹爆炸特效。**属性**: `radius`, `color`, `_lifetime`(0.3s)

---

## UI 脚本 (`scenes/ui/`)

### InventoryUI (`scenes/ui/inventory_ui.gd`)

背包界面。B 键开关，7 列网格。

| 函数 | 用途 |
|------|------|
| `_show_info(data)` | 显示物品详情 |
| `_describe_effects(ids)` | 消耗品效果中文描述 |
| `_on_use` | 使用消耗品 |
| `_on_sell` | 售卖物品 |
| `_get_drop_chance(id)` | 查询掉落概率 |

### SkillBar (`scenes/ui/skill_bar.gd`)

底部技能栏+消耗品栏。

| 函数 | 用途 |
|------|------|
| `_create_slot(idx, is_skill)` | 创建统一风格格子 |
| `_refresh` | 技能槽刷新 |
| `_update_cd_display` | 每帧更新 CD/激活倒计时 |
| `_on_skill_pressed(idx)` | 点击技能（购买/激活） |
| `_use_consumable_at(idx)` | 使用消耗品 |

**按键**: 技能 1-7 键，消耗品 8/9/0/F1/F2

### StatsPanel (`scenes/ui/stats_panel.gd`)

右下角属性面板+升级按钮。

| 函数 | 用途 |
|------|------|
| `_try_upgrade(stat)` | 尝试升级属性 |
| `_refresh` | 刷新显示 |

### DeathScreen (`scenes/ui/death_screen.gd`)

死亡界面，评分+统计+重开/菜单。

### PauseMenu (`scenes/ui/pause_menu.gd`)

ESC 暂停，毛玻璃弹窗。

### WaveDisplay (`scenes/ui/wave_display.gd`)

左上角波次信息+倒计时+难度阶段+敌人数+掉率。

### WaveAnnounce (`scenes/ui/wave_announce.gd`)

屏幕中央波次公告（淡入→停留→淡出）。

### ComboDisplay (`scenes/ui/combo_display.gd`)

连击数字+掉率加成（≥3绿 ≥5青 ≥10金）。

### StatusEffectBar (`scenes/ui/status_effect_bar.gd`)

右上角效果栏。

### EffectSlot (`scenes/ui/effect_slot.gd`)

效果格子，<3s 红色闪烁。

### TargetHpBar (`scenes/ui/target_hp_bar.gd`)

左下角血条，EventBus 解耦。

### BossHpBar (`scenes/ui/boss_hp_bar.gd`)

Boss 血条。

### InventorySlot (`scenes/ui/inventory_slot.gd`)

背包格子。

### MainMenu (`scenes/main_menu.gd`)

主菜单，粒子雨+闪电+呼吸标题。

### GameOver (`scenes/ui/game_over.gd`)

旧版游戏结束（已被 DeathScreen 替代）。

### TutorialOverlay (`scenes/ui/tutorial_overlay.gd`)

新手引导覆盖层。

### DevPanel (`scenes/ui/dev_panel.gd`)

开发调试面板。

### ChallengeMode (`scenes/challenge/challenge_mode.gd`)

挑战模式主逻辑。常亮：`BOSS_LEVEL(222)`, `TIME_LIMIT(300)`, `HEALTH_PACK_COUNT(99)`, `DROP_CHANCE(0.03)`

---

## 数据驱动指南：如何不加代码添加新内容

### 添加新消耗品（零代码）

1. 在 `data/effects/` 创建新效果 `.tres`（EffectData 资源）
2. 在 `data/items/` 创建新物品 `.tres`（ConsumableItemData）
3. 在 `assets/` 添加图标 SVG
4. 在 `data/data_registry.tres` 中添加路径：
   - `item_paths` 加 `"res://data/items/new_potion.tres"`
   - `effect_paths` 加 `"res://data/effects/new_buff.tres"`
5. 在 `data/drop_tables/` 中添加 DropEntry

**零代码！** EffectManager/SkillManager/SaveManager 都从 DataRegistry 读取路径。

### 添加新技能

1. 在 `data/skills/` 创建 `.tres`（SkillData）
2. 在 `data/data_registry.tres` 的 `skill_paths` 添加路径
3. ⚠️ **技能效果逻辑需要代码**：在 `target.gd` 的 `_on_skill_activated` 中添加 match 分支

### 添加新怪物类型

1. 创建新场景（继承或复制 enemy.tscn）
2. 在编辑器中设置不同的 `drop_table`
3. 修改 `enemy_spawner.gd` 的 `ENEMY_SCENE` 为随机选择

### 调整数值

全部在 .tres 文件中调整，零代码：
- 怪物属性曲线 → `data/wave_config.tres`
- 玩家属性/升级 → `data/player_config.tres`
- 掉落概率/权重 → `data/drop_tables/*.tres`
- 物品属性 → `data/items/*.tres`
- 效果属性 → `data/effects/*.tres`
- 技能参数 → `data/skills/*.tres`

---

## 踩坑速查

| 坑 | 解法 |
|----|------|
| `GDScript.new()` 导出崩溃 | 禁用，改用 ColorRect 等内置节点 |
| `DirAccess.open()` 扫不到 PCK | 用 DataRegistry 硬编码路径列表 |
| `set_script(preload())` 导出崩溃 | 改用 `.tscn` 场景 instantiate |
| `class_name` 与 Autoload 冲突 | Autoload 自动注册全局名，删掉 class_name |
| `add_child()` 立即触发 `_ready` | 数据在 add_child 前赋值 |
| 暂停时输入不响应 | `process_mode=ALWAYS` + `_input` |
| mouse_filter 遮挡 | 非交互 Control 设 `MOUSE_FILTER_IGNORE` |
| 手写 .tres 不可靠 | 用编辑器创建或程序化构建 |
| Resource 没有 `name` 属性 | 自定义 Resource 用 `skill_name` 等字段 |
| 双重 queue_free | 死亡回调加 `has_meta("dead")` 防重入 |
| Container 遮挡点击 | HBoxContainer/VBoxContainer 设 mouse_filter=IGNORE |
| .tscn 覆盖子节点属性 | 子实例化场景时父 .tscn 会覆盖子节点属性 |
| `:=` 三元表达式类型推断 | 必须显式 `: Type =` |
| `set_deferred` 时序 | `add_child()` 立即触发 `_ready()` |
| 子弹方向 | `bullet.rotation` 只控制朝向，移动方向需 `direction = Vector2.RIGHT.rotated(rotation)` |

---

## 位移技能 (Dash)

独立组件，不经过 SkillManager，自动挂载到玩家。

```
Target (CharacterBody2D)
├── DashComponent ← 免费，自动挂载
├── HealthComponent
├── ShootingComponent
└── ...
```

### DashComponent (`core/components/dash_component.gd`)

| 属性 | 默认值 | 说明 |
|------|--------|------|
| `dash_speed` | 800.0 | 位移速度 |
| `dash_duration` | 0.15 | 位移持续时间 |
| `dash_cooldown` | 10.0 | 冷却时间 |
| `kill_cd_reduction` | 1.0 | 击杀减 CD |

| 函数 | 说明 |
|------|------|
| `can_dash()` | 是否可位移 |
| `trigger_dash()` | 触发位移 |
| `get_cd_ratio()` | CD 进度 0~1 |
| `get_cd_remaining()` | CD 剩余秒 |

**信号**: `dash_started`, `dash_ended`

### 修改位移数值

**方法 1**: 修改 `core/components/dash_component.gd` 顶部的 `@export` 变量

**方法 2**: 在 `target.gd` 的 `_ready()` 中覆写

**方法 3**: 改为 `.tres` 数据驱动（参照其他技能）

---

## 如何修改新手引导

### 教程步骤

`scenes/ui/tutorial_overlay.gd` 顶部的 `STEPS` 常量：

```gdscript
const STEPS := [
    { "text": "逃离虫哥", "icon": "😡" },
    { "text": "WASD 或方向键移动角色", "icon": "🎮" },
    { "text": "鼠标左键射击，按住蓄力", "icon": "🖱️" },
    { "text": "Q 键位移（鼠标方向），击杀减CD", "icon": "💨" },
    { "text": "B 键打开/关闭背包", "icon": "🎒" },
    { "text": "1-5 键使用技能，Shift 切换瞄准", "icon": "⚡" },
    { "text": "击杀敌人，坚持更多波次！", "icon": "💀" },
]
```

### 触发条件

- **首次运行**: `MetaProgression.total_levels() == 0`
- **手动重看**: 按 `F1` 键

### 重置教程

删除 `tutorial_seen.cfg` 文件：`%APPDATA%/Godot/app_userdata/OutBugBro/tutorial_seen.cfg`

---

## 金币经济数值速查

### 收入

| 来源 | 公式 |
|------|------|
| 击杀 | `gold_per_level × level × gold_mult` |
| 清波奖励 | `wave × wave_bonus_mult` |
| 售卖 | `item.value × 0.5` |

### 升级费用

| 升级项 | 基础费用 | 倍率 |
|--------|---------|------|
| 生命强化 | 50 | ×1.30 |
| 力量强化 | 60 | ×1.35 |
| 防御强化 | 50 | ×1.30 |
| 敏捷强化 | 40 | ×1.25 |
| 幸运强化 | 80 | ×1.40 |
| 财运强化 | 60 | ×1.35 |
| 伤害强化 | 100 | ×1.45 |
| 精准强化 | 90 | ×1.40 |
| 生命回复 | 100 | ×1.50 |

### 修改经济数值

- **击杀金币**: `data/wave_config.tres` → `gold_per_level`
- **清波奖励**: `data/wave_config.tres` → `wave_bonus_mult`
- **升级费用**: `core/autoload/meta_progression.gd` → `upgrades`
- **金币倍率加成**: `meta_progression.gd` → `get_gold_mult_bonus()`

---

## 挑战模式

独立 Boss 战模式，从主菜单进入。

| 项目 | 设置 |
|------|------|
| Boss | 222 级大虫 |
| 限时 | 300 秒 |
| 特供血包 | 99 个 |
| 技能 | 仅位移（Q 键） |
| 属性升级 | 禁用 |
| 消耗品掉落 | 对 Boss 造成伤害 3% 概率 |
| 评分 | `造成伤害 / max(受到伤害, 1)`，击杀 Boss×2 |
| 存档 | `user://challenge_score.json` |

**文件**: `scenes/challenge/challenge_mode.gd`

### 修改挑战模式数值

编辑 `scenes/challenge/challenge_mode.gd` 顶部常量：

```gdscript
const BOSS_LEVEL: int = 222
const TIME_LIMIT: float = 300.0
const HEALTH_PACK_COUNT: int = 99
const DROP_CHANCE: float = 0.03
```

---

## 射击系统

### 模式

| 模式 | 瞄准 | 射击 |
|------|------|------|
| AUTO | 自动瞄准最近敌人 | 左键射击/蓄力 |
| MOUSE | 鼠标方向 | 左键射击/蓄力 |

- Shift 切换模式
- 左键点击 = 普通射击，按住 = 蓄力（松开释放）

### 修改射击参数

编辑 `core/components/shooting_component.gd`：

```gdscript
@export var fire_rate: float = 0.5
@export var rotate_speed: float = 5.0  # AUTO 模式炮塔转速
```
