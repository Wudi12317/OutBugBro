# 架构说明

> 系统架构、Autoload 单例、基类、组件体系详解。
> 引擎：Godot 4.5.1 | 语言：GDScript | 渲染器：Mobile

---

## 节点层级

```
World (Node2D)
├── Target (StaticBody2D) ← targets/player 组
│   ├── HealthComponent
│   ├── ShootingComponent
│   ├── PlayerStats
│   ├── DashComponent
│   ├── ArenaBounds
│   ├── ShieldRing / ChargeFX (动态创建)
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
    ├── BossHpBar
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

**枚举 State**: `MENU`, `PLAYING`, `PAUSED`

### InventoryManager (`core/autoload/inventory_manager.gd`)

背包数据层，与 UI 完全解耦。

| 函数 | 签名 | 用途 |
|------|------|------|
| `add_item` | `(data: ItemData, amount: int = 1)` | 添加物品，同 id 自动堆叠 |
| `remove_item` | `(data: ItemData, amount: int = 1)` | 移除物品，数量归零删除条目 |
| `use_item` | `(data: ItemData) -> bool` | 使用消耗品 |
| `get_items` | `() -> Array[Dictionary]` | 获取所有物品（只读副本） |
| `get_item_count` | `() -> int` | 物品种类数 |
| `clear_all` | `()` | 清空背包 |
| `set_consumable_binding` | `(slot_idx: int, item_id: String)` | 设置快捷栏绑定 |
| `get_consumable_at_slot` | `(slot_idx: int) -> ItemData` | 获取快捷栏物品 |
| `get_consumable_count_at_slot` | `(slot_idx: int) -> int` | 快捷栏物品数量 |

**信号**: `changed`, `bindings_changed`
**属性**: `consumable_bindings: PackedStringArray` — 5 个快捷栏槽位

### EffectManager (`core/autoload/effect_manager.gd`)

管理角色身上激活的效果 + 效果注册表。

| 函数 | 签名 | 用途 |
|------|------|------|
| `get_effect_by_id` | `(id: String) -> EffectData` | 通过 ID 查找效果数据 |
| `add_effect` | `(effect: EffectData, duration: float = -1.0)` | 添加效果，同 id 刷新时长 |
| `remove_effect` | `(id: String)` | 移除效果 |
| `has_effect` | `(id: String) -> bool` | 是否拥有某效果 |
| `get_active` | `() -> Array[Dictionary]` | 获取所有激活效果 |
| `clear_all` | `()` | 清空所有效果 |

**信号**: `changed`

### CurrencyManager (`core/autoload/currency_manager.gd`)

全局货币管理。

| 函数 | 签名 | 用途 |
|------|------|------|
| `add` | `(amount: int)` | 增加货币 |
| `spend` | `(amount: int) -> bool` | 花费货币，不够返回 false |
| `has_enough` | `(amount: int) -> bool` | 是否足够 |

**属性**: `currency: int`

### ComboManager (`core/autoload/combo_manager.gd`)

2 秒窗口连击系统。

| 函数 | 签名 | 用途 |
|------|------|------|
| `on_kill` | `()` | 击杀时调用，combo+1，重置 2 秒窗口 |
| `get_drop_bonus` | `() -> float` | 当前掉率加成（0~0.5），每级+5% |

**信号**: `combo_changed(combo)`, `combo_expired`

### SkillManager (`core/autoload/skill_manager.gd`)

技能解锁、购买、激活、冷却。

| 函数 | 签名 | 用途 |
|------|------|------|
| `get_skills` | `() -> Array[SkillData]` | 获取所有技能 |
| `is_unlocked` | `(id: String) -> bool` | 是否已购买 |
| `can_purchase` | `(id: String) -> bool` | 是否可购买 |
| `purchase` | `(id: String) -> bool` | 购买技能 |
| `activate` | `(id: String) -> bool` | 激活技能 |
| `is_active` | `(id: String) -> bool` | 效果是否激活中 |
| `is_on_cooldown` | `(id: String) -> bool` | 是否在冷却 |
| `get_cooldown_remaining` | `(id: String) -> float` | 冷却剩余秒 |
| `get_cooldown_total` | `(id: String) -> float` | 冷却总时长 |
| `get_active_remaining` | `(id: String) -> float` | 激活剩余秒 |
| `activate_by_index` | `(idx: int) -> bool` | 按索引激活（1-5 键） |
| `purchase_by_index` | `(idx: int) -> bool` | 按索引购买 |

**信号**: `changed`, `skill_activated(skill_id)`, `skill_expired(skill_id)`, `skill_purchased(skill_id)`

### SaveManager (`core/autoload/save_manager.gd`)

JSON 存档管理。

| 函数 | 签名 | 用途 |
|------|------|------|
| `has_save` | `() -> bool` | 是否有存档 |
| `save_run` | `()` | 保存当前运行状态 |
| `load_run` | `()` | 读档恢复状态 |
| `get_saved_wave` | `() -> int` | 获取存档波次 |
| `reset_run` | `()` | 重置本次运行 |
| `full_reset` | `()` | 完全重置 |
| `clear_runtime` | `()` | 清除运行时状态 |
| `update_high_score` | `(waves: int, kills: int)` | 更新最高评分 |
| `get_high_score` | `() -> Dictionary` | 获取最高评分 |
| `get_high_score_text` | `() -> String` | 最高评分显示文本 |
| `calculate_grade` | `(waves: int) -> Dictionary` | 评分等级计算 |

**属性**: `run_kills: int`

### MetaProgression (`core/autoload/meta_progression.gd`)

元进度升级系统。管理各属性等级、费用计算、金币倍率加成。

---

## 基类 (`core/base/`)

### Component (`core/base/component.gd`)

组件基类，组合模式核心。

| 函数 | 签名 | 用途 |
|------|------|------|
| `_setup` | `()` | 子类覆写：初始化逻辑（`_ready` 时调用） |
| `_tick` | `(_delta: float)` | 子类覆写：每帧逻辑（`_process` 时调用） |

**属性**: `enabled: bool`, `entity: Node`（=get_parent()）

### ItemData (`core/base/item_data.gd`)

物品数据基类。

| 函数 | 签名 | 用途 |
|------|------|------|
| `get_rarity_color` | `() -> Color` | 品质颜色 |

**属性**: `id`, `name`, `icon`, `desc`, `rarity`(0-4), `value`, `type`
**枚举 ItemType**: `CONSUMABLE`, `MATERIAL`, `COLLECTIBLE`

### ConsumableItemData (`core/base/consumable_item_data.gd`)
继承 ItemData。**属性**: `effect_ids: PackedStringArray`, `effect_duration: float`

### MaterialItemData (`core/base/material_item_data.gd`)
继承 ItemData。**属性**: `sources: PackedStringArray`

### CollectibleItemData (`core/base/collectible_item_data.gd`)
继承 ItemData。无额外属性。

### EffectData (`core/base/effect_data.gd`)

| 函数 | 签名 | 用途 |
|------|------|------|
| `get_active_effects` | `() -> Dictionary` | 返回所有非零效果 |

**属性**: `id`, `icon`, `heal_amount`, `hp_change`, `fire_rate_change`, `damage_change`, `damage_mult_change`, `crit_rate_change`, `crit_damage_change`, `defense_change`, `move_speed_change`

### SkillData (`core/base/skill_data.gd`)

**属性**: `id`, `skill_name`, `desc`, `icon`, `unlock_wave`, `cost`, `cooldown`, `duration`, `key_index`

### DropEntry (`core/base/drop_entry.gd`)
**属性**: `item: ItemData`, `weight: float`

### DropTable (`core/base/drop_table.gd`)

| 函数 | 签名 | 用途 |
|------|------|------|
| `roll` | `() -> ItemData` | 加权随机掉落 |
| `get_chance_for` | `(item_id: String) -> float` | 某物品掉落概率 |
| `get_all_chances` | `() -> Array[Dictionary]` | 所有条目概率信息 |

**属性**: `entries: Array[DropEntry]`

### DataRegistry (`core/base/data_registry.gd`)

集中管理所有资源路径。**属性**: `item_paths`, `effect_paths`, `skill_paths`

### WaveConfig (`core/base/wave_config.gd`)

| 函数 | 签名 | 用途 |
|------|------|------|
| `get_phase_name` | `(wave: int) -> String` | 难度阶段名 |
| `get_phase_color` | `(wave: int) -> Color` | 阶段颜色 |
| `get_spawn_interval` | `(wave: int) -> float` | 生成间隔 |
| `get_enemy_hp` | `(level: int) -> int` | 怪物 HP |
| `get_enemy_atk` | `(level: int) -> int` | 怪物 ATK |
| `get_enemy_speed` | `(level: int) -> float` | 怪物速度 |
| `get_enemy_attack_interval` | `(level: int) -> float` | 怪物攻击间隔 |
| `get_drop_chance` | `(wave: int) -> float` | 掉落概率 |

### PlayerConfig (`core/base/player_config.gd`)

玩家属性配置。基础属性、各项升级曲线（每级增量+基础费用）、费用倍率。

---

## 组件 (`core/components/`)

### HealthComponent (`core/components/health_component.gd`)

血量管理。

| 函数 | 签名 | 用途 |
|------|------|------|
| `set_max_hp` | `(new_max: int)` | 设置血量上限 |
| `take_damage` | `(amount: int)` | 受击扣血 |
| `heal` | `(amount: int)` | 回血 |
| `set_hp` | `(new_hp: int)` | 直接设置 hp |
| `get_ratio` | `() -> float` | 血量比例 0~1 |

**信号**: `health_changed(current, maximum)`, `died`

### MoveComponent (`core/components/move_component.gd`)

移动+击退+减速。

| 函数 | 签名 | 用途 |
|------|------|------|
| `apply_knockback` | `(vel: Vector2)` | 施加击退速度 |
| `apply_slow` | `(mult: float, duration: float)` | 施加减速 |

**属性**: `move_speed`, `stop_distance`, `target_node`, `is_in_range`

### AttackComponent (`core/components/attack_component.gd`)

定时攻击。

| 函数 | 签名 | 用途 |
|------|------|------|
| `try_attack` | `(target: Node) -> bool` | 尝试攻击 |

**属性**: `attack_damage`, `attack_rate`

### ShootingComponent (`core/components/shooting_component.gd`)

瞄准+射击+蓄力+穿透+溅射+技能交互。

| 函数 | 签名 | 用途 |
|------|------|------|
| `start_charge` | `()` | 开始蓄力（仅 MOUSE 模式） |
| `release_charge` | `()` | 释放蓄力 |
| `get_charge_progress` | `() -> float` | 蓄力进度 0~1 普通, 1~2 重蓄力 |

**枚举 AimMode**: `AUTO`, `MOUSE`

**蓄力等级**: 0=普通(0.3-1.5s, 2-3倍伤+3穿透), 1=重蓄力(1.5-5.0s, W7+, 5-7倍伤+5穿透)

### PlayerStats (`core/components/player_stats.gd`)

属性系统+升级+效果加成。

| 函数 | 签名 | 用途 |
|------|------|------|
| `get_max_hp` | `() -> int` | 基础HP + 效果加成 |
| `get_damage` | `() -> int` | 攻击力 |
| `get_crit_rate` | `() -> float` | 暴击率 |
| `get_crit_damage` | `() -> float` | 暴击伤害倍率 |
| `get_defense` | `() -> int` | 防御力 |
| `get_fire_rate` | `() -> float` | 射速 |
| `get_move_speed` | `() -> float` | 移速 |
| `calc_damage_taken` | `(raw: int) -> int` | 防御减伤 |
| `is_crit` | `() -> bool` | 暴击判定 |
| `calc_damage_dealt` | `() -> int` | 最终伤害 |
| `get_upgrade_cost` | `(stat: String) -> int` | 升级费用 |
| `upgrade` | `(stat: String) -> bool` | 执行升级 |
| `get_next_value` | `(stat: String) -> float` | 下一级数值预览 |

**信号**: `stats_changed`

### DashComponent (`core/components/dash_component.gd`)

位移技能。**属性**: `dash_speed(800)`, `dash_duration(0.15)`, `dash_cooldown(10.0)`, `kill_cd_reduction(1.0)`
**信号**: `dash_started`, `dash_ended`

### TrailComponent (`core/components/trail_component.gd`)

拖尾粒子效果，对象池复用。**属性**: `trail_color`, `trail_radius`, `spawn_interval`, `fade_time`, `min_speed`

### ArenaBounds (`core/components/arena_bounds.gd`)

战斗区域边界限制。防止玩家/怪物移出屏幕范围。
