# OUTBUGBRO 程序员参考手册

> 本文档描述项目中每个脚本的每个函数的用途，供接手的程序员快速定位和修改。
> 引擎：Godot 4.5.1 | 语言：GDScript | 渲染器：Mobile

---

## 目录

1. [架构概览](#架构概览)
2. [Autoload 全局单例](#autoload-全局单例)
3. [基类 (core/base/)](#基类-corebase)
4. [组件 (core/components/)](#组件-corecomponents)
5. [场景脚本 (scenes/)](#场景脚本-scenes)
6. [数据驱动指南：如何不加代码添加新内容](#数据驱动指南如何不加代码添加新内容)
7. [踩坑速查](#踩坑速查)

---

## 架构概览

```
核心原则:
- EventBus 解耦通信，禁止硬引用跨模块
- Component 组合模式，实体用组件子节点，不用继承
- 数据用 .tres (Resource)，逻辑用组件
- DataRegistry 统一管理资源路径，加新内容零代码
- 命名 snake_case，中文注释

节点层级:
World (Node2D)
├── Target (StaticBody2D) ← targets/player 组
│   ├── HealthComponent
│   ├── ShootingComponent
│   ├── PlayerStats
│   └── ShieldRing / ChargeFX (动态创建)
├── EnemySpawner (Node2D) ← spawners 组
├── Enemy (CharacterBody2D) ← enemies 组 [动态生成]
│   ├── HealthComponent
│   ├── MoveComponent
│   ├── AttackComponent
│   └── TrailComponent
└── UILayer (CanvasLayer)
	├── InventoryUI
	├── StatsPanel
	├── SkillBar
	├── WaveDisplay / WaveAnnounce
	├── ComboDisplay
	├── StatusEffectBar
	├── TargetHpBar
	├── DeathScreen
	└── PauseMenu
```

---

## Autoload 全局单例

### EventBus (`core/autoload/event_bus.gd`)
全局事件总线，松耦合通信核心。

| 函数 | 签名 | 用途 |
|------|------|------|
| `listen` | `(event: StringName, callback: Callable)` | 订阅事件，回调接收一个 Variant 参数 |
| `unlisten` | `(event: StringName, callback: Callable)` | 取消订阅 |
| `dispatch` | `(event: StringName, data: Variant = null)` | 触发事件，data 为 null 时不传参 |

**已注册事件**:
- `"game_over"` — Target 死亡
- `"game_state_changed"` — GameManager 状态切换
- `"target_hp_changed"` — Target 血量变化，data={hp, max_hp}
- `"player_heal"` — 消耗品回血，data=回血量(float)

### GameManager (`core/autoload/game_manager.gd`)
全局状态管理。

| 函数 | 签名 | 用途 |
|------|------|------|
| `play` | `()` | 恢复游戏，取消暂停 |
| `pause` | `()` | 暂停游戏 |
| `change_scene` | `(path: String)` | 切换场景 |

**枚举 `State`**: `MENU`, `PLAYING`, `PAUSED`

### InventoryManager (`core/autoload/inventory_manager.gd`)
背包数据层，与 UI 完全解耦。

| 函数 | 签名 | 用途 |
|------|------|------|
| `add_item` | `(data: ItemData, amount: int = 1)` | 添加物品，同 id 自动堆叠 |
| `remove_item` | `(data: ItemData, amount: int = 1)` | 移除物品，数量归零删除条目 |
| `use_item` | `(data: ItemData) -> bool` | 使用消耗品：解析 effect_ids，触发即时回血+持续增益 |
| `get_items` | `() -> Array[Dictionary]` | 获取所有物品（只读副本），每项 {data, count} |
| `get_item_count` | `() -> int` | 物品种类数 |
| `clear_all` | `()` | 清空背包 |
| `set_consumable_binding` | `(slot_idx: int, item_id: String)` | 设置快捷栏绑定 |
| `get_consumable_at_slot` | `(slot_idx: int) -> ItemData` | 获取快捷栏物品（已绑定→返回，未绑定→自动填充） |
| `get_consumable_count_at_slot` | `(slot_idx: int) -> int` | 快捷栏物品数量 |

**信号**: `changed`, `bindings_changed`

**属性**: `consumable_bindings: PackedStringArray` — 5个快捷栏槽位

### EffectManager (`core/autoload/effect_manager.gd`)
管理角色身上激活的效果 + 效果注册表。从 DataRegistry 读取路径。

| 函数 | 签名 | 用途 |
|------|------|------|
| `get_effect_by_id` | `(id: String) -> EffectData` | 通过 ID 查找效果数据 |
| `add_effect` | `(effect: EffectData, duration: float = -1.0)` | 添加效果，同 id 刷新时长 |
| `remove_effect` | `(id: String)` | 移除效果 |
| `has_effect` | `(id: String) -> bool` | 是否拥有某效果 |
| `get_active` | `() -> Array[Dictionary]` | 获取所有激活效果（只读），每项 {effect, remaining} |
| `clear_all` | `()` | 清空所有效果 |

**信号**: `changed`

### CurrencyManager (`core/autoload/currency_manager.gd`)
全局货币管理。

| 函数 | 签名 | 用途 |
|------|------|------|
| `add` | `(amount: int)` | 增加货币 |
| `spend` | `(amount: int) -> bool` | 花费货币，不够返回 false |
| `has_enough` | `(amount: int) -> bool` | 是否足够 |

**属性**: `currency: int` — setter 自动 emit changed

### ComboManager (`core/autoload/combo_manager.gd`)
2秒窗口连击系统。

| 函数 | 签名 | 用途 |
|------|------|------|
| `on_kill` | `()` | 击杀时调用，combo+1，重置2秒窗口 |
| `get_drop_bonus` | `() -> float` | 当前掉率加成（0~0.5），每级+5% |

**信号**: `combo_changed(combo)`, `combo_expired`

### SkillManager (`core/autoload/skill_manager.gd`)
技能解锁、购买、激活、冷却。从 DataRegistry 读取路径。

| 函数 | 签名 | 用途 |
|------|------|------|
| `get_skills` | `() -> Array[SkillData]` | 获取所有技能（按 key_index 排序） |
| `is_unlocked` | `(id: String) -> bool` | 是否已购买 |
| `can_purchase` | `(id: String) -> bool` | 是否可购买（波次达标+未购买） |
| `purchase` | `(id: String) -> bool` | 购买技能，扣金币 |
| `activate` | `(id: String) -> bool` | 激活技能（未购买/冷却中/已激活返回 false） |
| `is_active` | `(id: String) -> bool` | 效果是否激活中 |
| `is_on_cooldown` | `(id: String) -> bool` | 是否在冷却 |
| `get_cooldown_remaining` | `(id: String) -> float` | 冷却剩余秒 |
| `get_cooldown_total` | `(id: String) -> float` | 冷却总时长 |
| `get_active_remaining` | `(id: String) -> float` | 激活剩余秒 |
| `activate_by_index` | `(idx: int) -> bool` | 按索引激活（1-5键） |
| `purchase_by_index` | `(idx: int) -> bool` | 按索引购买 |

**信号**: `changed`, `skill_activated(skill_id)`, `skill_expired(skill_id)`, `skill_purchased(skill_id)`

### SaveManager (`core/autoload/save_manager.gd`)
存档管理。JSON 文件存储于 `user://save_data.json`。

| 函数 | 签名 | 用途 |
|------|------|------|
| `has_save` | `() -> bool` | 是否有存档 |
| `save_run` | `()` | 保存当前运行状态（货币/波次/升级/技能/消耗品/背包） |
| `load_run` | `()` | 读档恢复状态 |
| `get_saved_wave` | `() -> int` | 获取存档波次 |
| `reset_run` | `()` | 重置本次运行（保留最高记录） |
| `full_reset` | `()` | 完全重置（包括最高记录） |
| `clear_runtime` | `()` | 清除所有运行时状态 |
| `update_high_score` | `(waves: int, kills: int)` | 更新最高评分 |
| `get_high_score` | `() -> Dictionary` | 获取最高评分信息 |
| `get_high_score_text` | `() -> String` | 最高评分显示文本 |
| `calculate_grade` | `(waves: int) -> Dictionary` | 评分等级计算，返回 {grade, color, stars, waves} |

**属性**: `run_kills: int` — 本次运行击杀数

---

## 基类 (core/base/)

### Component (`core/base/component.gd`)
组件基类，组合模式核心。

| 函数 | 签名 | 用途 |
|------|------|------|
| `_setup` | `()` | 子类覆写：初始化逻辑（`_ready` 时调用） |
| `_tick` | `(_delta: float)` | 子类覆写：每帧逻辑（`_process` 时调用） |

**属性**: `enabled: bool` — 禁用时跳过 `_tick`；`entity: Node` — 宿主（=get_parent()）

### ItemData (`core/base/item_data.gd`)
物品数据基类。

| 函数 | 签名 | 用途 |
|------|------|------|
| `get_rarity_color` | `() -> Color` | 品质颜色：0白 1绿 2青 3紫 4金 |

**属性**: `id`, `name`, `icon`, `desc`, `rarity`(0-4), `value`, `type`

**枚举 `ItemType`**: `CONSUMABLE`, `MATERIAL`, `COLLECTIBLE`

### ConsumableItemData (`core/base/consumable_item_data.gd`)
消耗品，继承 ItemData。

**属性**: `effect_ids: PackedStringArray` — 效果编号列表；`effect_duration: float` — 增益持续时间

### MaterialItemData (`core/base/material_item_data.gd`)
材料，继承 ItemData。

**属性**: `sources: PackedStringArray` — 获得途径列表

### CollectibleItemData (`core/base/collectible_item_data.gd`)
收藏品，继承 ItemData。无额外属性。

### EffectData (`core/base/effect_data.gd`)
效果数据。

| 函数 | 签名 | 用途 |
|------|------|------|
| `get_active_effects` | `() -> Dictionary` | 返回所有非零效果 {属性名: 值} |

**属性**: `id`, `icon`, `heal_amount`, `hp_change`, `fire_rate_change`, `damage_change`, `damage_mult_change`, `crit_rate_change`, `crit_damage_change`, `defense_change`, `move_speed_change`

### SkillData (`core/base/skill_data.gd`)
技能数据。

**属性**: `id`, `skill_name`, `desc`, `icon`, `unlock_wave`, `cost`, `cooldown`, `duration`, `key_index`

### DropEntry (`core/base/drop_entry.gd`)
掉落条目。

**属性**: `item: ItemData`, `weight: float` — 权重（支持小数）

### DropTable (`core/base/drop_table.gd`)
掉落表。

| 函数 | 签名 | 用途 |
|------|------|------|
| `roll` | `() -> ItemData` | 加权随机掉落（可能返回 null） |
| `get_chance_for` | `(item_id: String) -> float` | 某物品掉落概率 0~1 |
| `get_all_chances` | `() -> Array[Dictionary]` | 所有条目概率信息 |

**属性**: `entries: Array[DropEntry]`

### DataRegistry (`core/base/data_registry.gd`)
数据注册表，集中管理所有资源路径。

**属性**: `item_paths: Array[String]`, `effect_paths: Array[String]`, `skill_paths: Array[String]`

### WaveConfig (`core/base/wave_config.gd`)
波次配置，所有数值可在编辑器 .tres 中调整。

| 函数 | 签名 | 用途 |
|------|------|------|
| `get_phase_name` | `(wave: int) -> String` | 难度阶段名：轻松/普通/困难/地狱 |
| `get_phase_color` | `(wave: int) -> Color` | 阶段颜色 |
| `get_spawn_interval` | `(wave: int) -> float` | 生成间隔（逐波递减） |
| `get_enemy_hp` | `(level: int) -> int` | 怪物HP：base × √level × mult |
| `get_enemy_atk` | `(level: int) -> int` | 怪物ATK（逐波累加） |
| `get_enemy_speed` | `(level: int) -> float` | 怪物速度 |
| `get_enemy_attack_interval` | `(level: int) -> float` | 怪物攻击间隔 |
| `get_drop_chance` | `(wave: int) -> float` | 掉落概率 |

### PlayerConfig (`core/base/player_config.gd`)
玩家属性配置，编辑器中调整初始属性和升级曲线。

**属性组**: 基础属性、生命/攻击/防御/暴击/爆伤/射速/移动升级（每级增量+基础费用）、费用倍率

---

## 组件 (core/components/)

### HealthComponent (`core/components/health_component.gd`)
血量管理。

| 函数 | 签名 | 用途 |
|------|------|------|
| `set_max_hp` | `(new_max: int)` | 设置血量上限，按比例调整当前血量 |
| `take_damage` | `(amount: int)` | 受击扣血，hp≤0 时 emit died |
| `heal` | `(amount: int)` | 回血（不超过上限） |
| `set_hp` | `(new_hp: int)` | 直接设置 hp（钳制到合法范围） |
| `get_ratio` | `() -> float` | 血量比例 0~1 |

**信号**: `health_changed(current, maximum)`, `died`

### MoveComponent (`core/components/move_component.gd`)
移动+击退+减速。

| 函数 | 签名 | 用途 |
|------|------|------|
| `apply_knockback` | `(vel: Vector2)` | 施加击退速度 |
| `apply_slow` | `(mult: float, duration: float)` | 施加减速（1.0=正常, 0.85=减速15%） |

**属性**: `move_speed`, `stop_distance`, `target_node`, `is_in_range`

### AttackComponent (`core/components/attack_component.gd`)
定时攻击。

| 函数 | 签名 | 用途 |
|------|------|------|
| `try_attack` | `(target: Node) -> bool` | 尝试攻击，冷却中返回 false，攻击时将 entity 作为 attacker 传入 |

**属性**: `attack_damage`, `attack_rate`

### ShootingComponent (`core/components/shooting_component.gd`)
瞄准+射击+蓄力+穿透+溅射+技能交互。

| 函数 | 签名 | 用途 |
|------|------|------|
| `start_charge` | `()` | 开始蓄力（仅 MOUSE 模式） |
| `release_charge` | `()` | 释放蓄力，计算蓄力等级发射子弹 |
| `get_charge_progress` | `() -> float` | 蓄力进度 0~1 普通, 1~2 重蓄力 |

**枚举 `AimMode`**: `AUTO`(自动瞄准最近敌人), `MOUSE`(鼠标瞄准+蓄力)

**蓄力等级**: 0=普通(0.3-1.5s, 2-3倍伤+3穿透), 1=重蓄力(1.5-5.0s, W7+, 5-7倍伤+5穿透)

**技能交互**: `double_shot`→双发, `magnet`→磁力吸引+蓄力减半, W5+手动模式爆裂弹

### PlayerStats (`core/components/player_stats.gd`)
属性系统+升级+效果加成。

| 函数 | 签名 | 用途 |
|------|------|------|
| `get_max_hp` | `() -> int` | 基础HP + 效果加成 |
| `get_damage` | `() -> int` | 基础ATK + flat加成 × (1+倍率加成) |
| `get_crit_rate` | `() -> float` | 暴击率（钳制 0~1） |
| `get_crit_damage` | `() -> float` | 暴击伤害倍率 |
| `get_defense` | `() -> int` | 防御力 |
| `get_fire_rate` | `() -> float` | 射速（下限 0.05） |
| `get_move_speed` | `() -> float` | 移速 |
| `calc_damage_taken` | `(raw: int) -> int` | 防御减伤：每8点防御-1伤害 |
| `is_crit` | `() -> bool` | 暴击判定（结果缓存到 last_attack_was_crit） |
| `calc_damage_dealt` | `() -> int` | 最终伤害（含暴击） |
| `get_upgrade_cost` | `(stat: String) -> int` | 升级费用 = base_cost × 1.45^当前等级 |
| `upgrade` | `(stat: String) -> bool` | 执行升级，扣金币 |
| `get_next_value` | `(stat: String) -> float` | 下一级数值预览 |

**信号**: `stats_changed`

### TrailComponent (`core/components/trail_component.gd`)
拖尾粒子效果，对象池复用。

**属性**: `trail_color`, `trail_radius`, `spawn_interval`, `fade_time`, `min_speed`

---

## 场景脚本 (scenes/)

### Target (`scenes/world/target.gd`)
玩家控制的目标，挂载组件 + 技能特效。

| 函数 | 签名 | 用途 |
|------|------|------|
| `take_damage` | `(amount: int, attacker: Node = null)` | 受击（护盾免疫/反伤/普通），代理到 HealthComponent |
| `_on_skill_activated` | `(skill_id: String)` | 技能激活回调（护盾光环/反伤/修理/导弹/头油/双发/磁力） |

**技能特效**:
- `shield` → 青色光环（`_update_shield_ring`）
- `reflect` → 紫色光环 + 80%减伤 + 75%反伤
- `repair` → 血回90% + 10s emergency_buff + 金色爆发
- `missile` → 清屏（所有敌人立即死亡）+ 红色爆发
- `head_oil` → 200px内击退+减速 + 黄绿爆发
- `double_shot` → 青色爆发
- `magnet` → 紫色爆发

### Enemy (`scenes/enemies/enemy.gd`)
怪物基类。

| 函数 | 签名 | 用途 |
|------|------|------|
| `take_damage` | `(amount: int, _attacker = null, is_crit: bool = false)` | 受击+白色闪烁+伤害数字 |
| `_on_died` | `()` | 死亡回调（防重入：has_meta("dead")） |
| `_drop_random_item` | `() -> ItemData` | 加权随机掉落 |
| `_drop_rare_item` | `() -> ItemData` | 精英掉落（rarity≥2） |

**精英怪**: `is_elite=true` → HP×3, 体型1.5倍, 金色边框, 100%掉落稀有以上

### Bullet (`scenes/world/bullet.gd`)
子弹，支持穿透/溅射/蓄力弹/拖尾。

| 函数 | 签名 | 用途 |
|------|------|------|
| `set_damage_mult` | `(mult: float)` | 设置伤害倍率（≥3 标记为蓄力弹） |
| `set_pierce` | `(count: int)` | 设置穿透数 |

**溅射**: W5+手动模式蓄力弹自动带溅射，范围50-60px

### EnemySpawner (`scenes/world/enemy_spawner.gd`)
波次状态机生成器。

| 函数 | 签名 | 用途 |
|------|------|------|
| `get_wave_time_remaining` | `() -> float` | 当前波次/休息剩余时间 |
| `get_enemies_alive` | `() -> int` | 存活敌人数 |

**状态机**: `FIGHTING`(25s) → `BREAK`(5s) → `FIGHTING`...  
**信号**: `wave_changed(wave)`, `wave_break(secs)`, `wave_bonus(gold)`

### DropIndicator (`scenes/world/drop_indicator.gd`)
浮动掉落提示。

| 函数 | 签名 | 用途 |
|------|------|------|
| `spawn` | `(parent, pos, gold, item) [static]` | 静态工厂，在指定位置生成掉落指示 |

**品质视觉**: 传说→金色光柱, 史诗→紫色脉冲, 稀有→青色闪烁

### ExplosionEffect (`scenes/world/explosion_effect.gd`)
爆裂弹爆炸特效。

**属性**: `radius`, `color`, `_lifetime`(0.3s)

---

## UI 脚本 (scenes/ui/)

### InventoryUI (`scenes/ui/inventory_ui.gd`)
背包界面。B键开关，7列网格，右侧物品详情+售卖+快捷栏绑定。

| 函数 | 签名 | 用途 |
|------|------|------|
| `_show_info` | `(data: ItemData)` | 显示物品详情（类型/品质/价值/描述/效果/掉落率） |
| `_describe_effects` | `(effect_ids) -> String` | 消耗品效果中文描述 |
| `_on_use` | `()` | 使用消耗品 |
| `_on_sell` | `()` | 售卖物品 |
| `_show_bind_section` | `(data)` | 显示快捷栏绑定按钮 |
| `_get_drop_chance` | `(item_id) -> float` | 从场上敌人掉落表查询概率 |

### SkillBar (`scenes/ui/skill_bar.gd`)
底部技能栏+消耗品栏。每帧更新CD/激活显示。

| 函数 | 签名 | 用途 |
|------|------|------|
| `_create_slot` | `(idx, is_skill) -> Control` | 创建统一风格格子（品质色背景+图标+CD遮罩+快捷键角标） |
| `_refresh` | `()` | 技能槽刷新（未解锁/已解锁/可用三种状态） |
| `_update_cd_display` | `()` | 每帧更新CD/激活倒计时 |
| `_refresh_items` | `()` | 消耗品槽刷新 |
| `_on_skill_pressed` | `(idx)` | 点击技能（未解锁→购买，已解锁→激活） |
| `_use_consumable_at` | `(idx)` | 使用消耗品 |

**按键**: 技能1-7键，消耗品8/9/0/F1/F2键

### StatsPanel (`scenes/ui/stats_panel.gd`)
右下角属性面板+升级按钮。

| 函数 | 签名 | 用途 |
|------|------|------|
| `_try_upgrade` | `(stat: String)` | 尝试升级属性 |
| `_refresh` | `()` | 刷新显示（应急buff时属性金色） |

### DeathScreen (`scenes/ui/death_screen.gd`)
死亡界面，评分+统计+重开/菜单。

### PauseMenu (`scenes/ui/pause_menu.gd`)
ESC暂停，毛玻璃弹窗，继续/菜单。

### WaveDisplay (`scenes/ui/wave_display.gd`)
左上角波次信息+倒计时+难度阶段+敌人数+掉率。

### WaveAnnounce (`scenes/ui/wave_announce.gd`)
屏幕中央波次公告（淡入→停留→淡出）。

### ComboDisplay (`scenes/ui/combo_display.gd`)
中偏右连击数字+掉率加成（≥3绿≥5青≥10金）。

### StatusEffectBar (`scenes/ui/status_effect_bar.gd`)
右上角效果栏，动态增减格子，点击查看详情。

### EffectSlot (`scenes/ui/effect_slot.gd`)
效果格子，品质色背景+贴图+倒计时，<3s红色闪烁。

### TargetHpBar (`scenes/ui/target_hp_bar.gd`)
左下角血条，EventBus 解耦。

### InventorySlot (`scenes/ui/inventory_slot.gd`)
背包格子，品质色背景+贴图+数量+白色闪动。

### MainMenu (`scenes/main_menu.gd`)
主菜单，iOS暗色风+粒子雨+闪电+呼吸标题+弹窗。

### GameOver (`scenes/ui/game_over.gd`)
旧版游戏结束（R键重开），已被 DeathScreen 替代但仍保留。

---

## 数据驱动指南：如何不加代码添加新内容

### 1. 添加新消耗品

**步骤**:
1. 在 `data/effects/` 创建新效果 `.tres`（如 `new_buff.tres`），在 Godot 编辑器中新建 EffectData 资源
2. 在 `data/items/` 创建新物品 `.tres`（如 `new_potion.tres`），新建 ConsumableItemData，填好 effect_ids
3. 在 `assets/` 添加图标 SVG
4. **在 `data/data_registry.tres` 中添加路径**:
   - `item_paths` 里加 `"res://data/items/new_potion.tres"`
   - `effect_paths` 里加 `"res://data/effects/new_buff.tres"`
5. 在 `data/drop_tables/default_drop_table.tres` 中添加 DropEntry（编辑器中操作）

**零代码！** EffectManager/SkillManager/SaveManager 都从 DataRegistry 读取路径。

### 2. 添加新技能

**步骤**:
1. 在 `data/skills/` 创建 `.tres`（如 `new_skill.tres`），新建 SkillData
2. 在 `data/data_registry.tres` 的 `skill_paths` 添加路径
3. ⚠️ **技能效果逻辑需要代码**：在 `target.gd` 的 `_on_skill_activated` 中添加 match 分支

### 3. 添加新怪物类型

**步骤**:
1. 创建新场景 `enemy_b.tscn`（继承或复制 enemy_a.tscn）
2. 在编辑器中设置不同的 `drop_table`（可创建新 .tres）
3. 修改 `enemy_spawner.gd` 的 `ENEMY_SCENE` 为随机选择

### 4. 调整数值

全部在 .tres 文件中调整，零代码：
- 怪物属性曲线 → `data/wave_config.tres`
- 玩家初始属性/升级 → `data/player_config.tres`
- 掉落概率/权重 → `data/drop_tables/default_drop_table.tres`
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
| `add_child()` 立即触发 `_ready` | 数据在 add_child 前赋值，别用 set_deferred |
| 暂停时输入不响应 | `process_mode=ALWAYS` + `_input`（不是 _unhandled_input） |
| mouse_filter 遮挡 | 非交互 Control 设 MOUSE_FILTER_IGNORE |
| 手写 .tres 不可靠 | 用编辑器创建或程序化构建 |
| Resource 没有 `name` 属性 | 自定义 Resource 用 `skill_name` 等字段 |
| 双重 queue_free | 死亡回调加 `has_meta("dead")` 防重入 |
| Container 遮挡点击 | HBoxContainer/VBoxContainer 设 mouse_filter=IGNORE |
| .tscn 覆盖子节点属性 | 子实例化场景时父 .tscn 会覆盖子节点属性 |

---

## 位移技能 (Dash)

### 架构

位移技能不走 SkillManager 购买体系，而是独立的 `DashComponent`，自动挂载到玩家。

```
Target (CharacterBody2D)
├── DashComponent ← 免费，无购买，自动挂载
├── HealthComponent
├── ShootingComponent
└── ...
```

### DashComponent (`core/components/dash_component.gd`)

| 属性 | 默认值 | 说明 |
|------|--------|------|
| `dash_speed` | 800.0 | 位移速度 |
| `dash_duration` | 0.15 | 位移持续时间（秒） |
| `dash_cooldown` | 10.0 | 冷却时间（秒） |
| `kill_cd_reduction` | 1.0 | 击杀减 CD（秒） |

| 信号 | 说明 |
|------|------|
| `dash_started` | 位移开始 |
| `dash_ended` | 位移结束 |

| 函数 | 说明 |
|------|------|
| `can_dash()` | 是否可位移 |
| `trigger_dash()` | 外部触发位移 |
| `get_cd_ratio()` | CD 进度 0~1（1=可用） |
| `get_cd_remaining()` | CD 剩余秒 |

### 如何修改位移技能数值

**方法 1：修改默认值（代码）**

编辑 `core/components/dash_component.gd` 顶部的 `@export` 变量：

```gdscript
@export var dash_speed: float = 800.0       # 位移速度（越大越快）
@export var dash_duration: float = 0.15     # 位移时间（秒，越大越远）
@export var dash_cooldown: float = 10.0     # CD 时间（秒，越小越频繁）
@export var kill_cd_reduction: float = 1.0  # 击杀减 CD（秒，越大减越多）
```

**方法 2：在 target.gd 中挂载时覆写**

编辑 `scenes/world/target.gd` 的 `_ready()` 中挂载部分：

```gdscript
_dash = DashComponent.new()
_dash._entity = self
_dash.dash_speed = 1000.0        # 更快
_dash.dash_cooldown = 8.0        # 更短 CD
_dash.kill_cd_reduction = 1.5    # 击杀减更多
_dash.name = "DashComponent"
add_child(_dash)
```

**方法 3：改为 .tres 数据驱动**

如果希望像其他技能一样用 .tres 配置：
1. 在 `core/base/skill_data.gd` 添加位移相关字段
2. 创建 `data/skills/dash.tres`
3. 修改 `DashComponent._ready()` 从 SkillData 读取参数

---

## 如何修改新手引导

### 教程文件

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

### 修改步骤

1. **增加步骤**：在 `STEPS` 数组中追加新的 `{ "text": "...", "icon": "..." }` 项
2. **删除步骤**：从数组中移除对应项
3. **修改文本**：直接改 `text` 字段
4. **修改图标**：改 `icon` 字段（用 emoji 即可）

### 触发条件

教程在两种情况触发：
- **首次运行**：`MetaProgression.total_levels() == 0` 且未看过
- **手动重看**：按 `F1` 键

### 重置教程（让已看过的用户重新看到）

删除 Godot 用户数据目录下的 `tutorial_seen.cfg` 文件：
- Windows: `%APPDATA%/Godot/app_userdata/OutBugBro/tutorial_seen.cfg`
- 或在代码中调用：`TutorialOverlay.show_tutorial()`

---

## 金币经济数值速查

### 收入

| 来源 | 公式 | 示例（W1） | 示例（W10） |
|------|------|-----------|------------|
| 击杀 | `gold_per_level × level × gold_mult` | 15×1×1.0=15 | 15×10×1.0=150 |
| 清波奖励 | `wave × wave_bonus_mult` | 1×100=100 | 10×100=1000 |
| 售卖物品 | `item.value × 0.5` | — | — |

### 支出（元进度升级）

| 升级项 | 基础费用 | 倍率 | 5级费用 | 10级费用 |
|--------|---------|------|---------|---------|
| 生命强化 | 50 | ×1.30 | 186 | 689 |
| 力量强化 | 60 | ×1.35 | 242 | 972 |
| 防御强化 | 50 | ×1.30 | 186 | 689 |
| 敏捷强化 | 40 | ×1.25 | 122 | 373 |
| 幸运强化 | 80 | ×1.40 | 430 | 2315 |
| 财运强化 | 60 | ×1.35 | 242 | 972 |
| 伤害强化 | 100 | ×1.45 | 640 | 4107 |
| 精准强化 | 90 | ×1.40 | 484 | 2605 |
| 生命回复 | 100 | ×1.50 | 759 | 5767 |

### 修改经济数值

- **击杀金币**: `data/wave_config.tres` → `gold_per_level`
- **清波奖励**: `data/wave_config.tres` → `wave_bonus_mult`
- **升级费用**: `core/autoload/meta_progression.gd` → `upgrades` 字典中的 `base_cost` / `cost_mult`
- **金币倍率加成**: `meta_progression.gd` → `get_gold_mult_bonus()` 中 `0.15` 为每级百分比

---

## 挑战模式

### 概述

挑战模式是独立于正常游戏的 Boss 战模式，从主菜单进入。

### 规则

| 项目 | 设置 |
|------|------|
| Boss | 222级大虫 |
| 限时 | 300秒 |
| 血包 | 99个 |
| 技能 | 只能用位移（Q键） |
| 属性升级 | 禁用 |
| 消耗品掉落 | 对Boss造成伤害3%概率 |
| 评分 | 造成伤害/受到伤害(最小1)，击杀Boss×2 |
| 评分保存 | `user://challenge_score.json` |

### 文件结构

```
scenes/challenge/
├── challenge_mode.gd    # 挑战模式主逻辑
└── challenge_mode.tscn  # 挑战模式场景
```

### ChallengeMode 关键属性

| 属性 | 默认值 | 说明 |
|------|--------|------|
| `BOSS_LEVEL` | 222 | Boss等级 |
| `TIME_LIMIT` | 300.0 | 限时(秒) |
| `HEALTH_PACK_COUNT` | 99 | 血包数量 |
| `DROP_CHANCE` | 0.03 | 消耗品掉落概率 |

### 如何修改挑战模式数值

编辑 `scenes/challenge/challenge_mode.gd` 顶部的常量：

```gdscript
const BOSS_LEVEL: int = 222          # Boss等级（影响HP/ATK）
const TIME_LIMIT: float = 300.0      # 限时(秒)
const HEALTH_PACK_COUNT: int = 99    # 初始血包数量
const DROP_CHANCE: float = 0.03      # 对Boss造成伤害时掉消耗品概率
```

### 评分公式

```
score = 造成伤害 / max(受到伤害, 1)
if Boss被击杀: score *= 2
保留一位小数
```

---

## 射击系统

### 模式说明

| 模式 | 瞄准 | 射击方式 |
|------|------|---------|
| AUTO | 自动瞄准最近敌人 | 鼠标左键射击/蓄力 |
| MOUSE | 跟随鼠标方向 | 鼠标左键射击/蓄力 |

- Shift 键切换模式
- 鼠标左键点击 = 普通射击
- 鼠标左键按住 = 蓄力（松开释放蓄力弹）

### 修改射击参数

编辑 `core/components/shooting_component.gd`：

```gdscript
@export var fire_rate: float = 0.5       # 射击间隔(秒)
@export var rotate_speed: float = 5.0    # AUTO模式炮塔转速
```
