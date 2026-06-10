# 数据修改指南

> **所有数值调整都在 .tres 文件中完成，无需修改代码！**
> 在 Godot 编辑器中双击 .tres 文件，即可在 Inspector 面板中直接编辑。

---

## 数据文件总览

| 文件 | 路径 | 用途 |
|------|------|------|
| 玩家配置 | `data/player_config.tres` | 初始属性、升级加成、费用曲线 |
| 波次配置 | `data/wave_config.tres` | 怪物属性、生成节奏、掉落概率 |
| 掉落表 | `data/drop_tables/*.tres` | 物品掉落池与权重 |
| 效果数据 | `data/effects/*.tres` | Buff/Debuff 属性改变 |
| 物品数据 | `data/items/*.tres` | 物品名称/描述/品质/效果关联 |
| 技能数据 | `data/skills/*.tres` | 技能参数 |

---

## 玩家配置 `data/player_config.tres`

### 基础属性

| 参数 | 当前值 | 说明 |
|------|--------|------|
| `max_hp` | 500 | 初始最大生命 |
| `damage` | 25 | 初始攻击力 |
| `defense` | 10 | 初始防御力（每10点减1受伤） |
| `crit_rate` | 0.05 | 初始暴击率（5%） |
| `crit_damage` | 0.25 | 初始暴击伤害加成 |
| `fire_rate` | 1.0 | 初始射速（次/秒） |
| `move_speed` | 0.0 | 初始移动速度（0=固定炮台） |

### 升级参数

| 属性 | 每级增长 | 基础费用 |
|------|----------|----------|
| 生命 max_hp | +50 | 30 |
| 攻击 damage | +5 | 40 |
| 防御 defense | +3 | 50 |
| 暴击 crit_rate | +0.03 | 60 |
| 爆伤 crit_damage | +0.15 | 50 |
| 射速 fire_rate | +0.3 | 80 |
| 移速 move_speed | +15 | 60 |

**费用公式**: 第 N 级费用 = `base_cost × cost_multiplier^N`（当前 `cost_multiplier=1.5`）

---

## 波次配置 `data/wave_config.tres`

### 波次节奏

| 参数 | 当前值 | 说明 |
|------|--------|------|
| `wave_duration` | 30.0 | 每波战斗时间（秒） |
| `break_duration` | 5.0 | 休息时间（秒） |
| `max_enemies` | 10 | 同屏最大敌人数 |
| `wave_bonus_mult` | 100 | 清波奖励倍率 |
| `spawn_margin` | 50.0 | 屏幕外生成边距 |

### 生成间隔

| 参数 | 当前值 | 说明 |
|------|--------|------|
| `spawn_interval_base` | 4.0 | 第1波生成间隔（秒） |
| `spawn_interval_min` | 1.6 | 间隔下限 |
| `spawn_easy_reduction` | 0.1 | 轻松期每波减少 |
| `spawn_mid_reduction` | 0.25 | 普通期每波减少 |
| `spawn_hard_reduction` | 0.4 | 困难期每波减少 |

### 难度阶段

| 参数 | 值 | 说明 |
|------|-----|------|
| `easy_wave_max` | 3 | 第1~3波轻松期 |
| `hard_wave_start` | 11 | 第11波起困难期 |

### 怪物属性曲线

| 参数 | 值 | 公式 |
|------|-----|------|
| `enemy_hp_base` | 25 | `base × level × 1.1` |
| `enemy_atk_easy` | 0.5 | +0.5/波 |
| `enemy_atk_mid` | 1.0 | +1.0/波 |
| `enemy_atk_hard` | 2.0 | +2.0/波 |
| `enemy_speed_base` | 40.0 | 累加 |
| `enemy_speed_easy` | 3.0 | +3/波 |
| `enemy_speed_mid` | 6.0 | +6/波 |
| `enemy_speed_hard` | 10.0 | +10/波 |

### 掉落参数

| 参数 | 值 | 说明 |
|------|-----|------|
| `drop_base_chance` | 0.80 | 基础掉落概率 |
| `drop_per_wave` | 0.06 | 每波增加掉落概率 |
| `drop_cap` | 0.80 | 掉落概率上限 |
| `gold_per_level` | 50 | 金币倍率 |

---

## 掉落表 `data/drop_tables/*.tres`

### 默认掉落表

| 物品 | 权重 | 概率 | 品质 |
|------|------|------|------|
| 铁矿石 | 50 | 38% | 普通(白) |
| 生命药水 | 30 | 23% | 精良(绿) |
| 古老硬币 | 25 | 19% | 精良(绿) |
| 速度药剂 | 15 | 12% | 稀有(青) |
| 力量药水 | 8 | 6% | 稀有(青) |
| 铁壁药水 | 6 | 5% | 稀有(青) |
| 魔法碎片 | 5 | 4% | 史诗(紫) |
| 幸运符 | 2 | 2% | 史诗(紫) |

### 精英怪掉落规则
- 10% 概率生成，HP×3，体型 1.5 倍
- **100% 掉落**且保证稀有(rarity≥2)以上

---

## 效果数据 `data/effects/*.tres`

| 字段 | 类型 | 说明 |
|------|------|------|
| `id` | String | 唯一标识符 |
| `icon` | Texture2D | 效果图标 |
| `heal_amount` | float | 即时回血量 |
| `hp_change` | float | 改变血量上限 |
| `fire_rate_change` | float | 改变射速 |
| `damage_change` | float | 改变伤害(固定值) |
| `damage_mult_change` | float | 改变伤害倍率 |
| `crit_rate_change` | float | 改变暴击率 |
| `crit_damage_change` | float | 改变暴击伤害 |
| `defense_change` | float | 改变防御力 |
| `move_speed_change` | float | 改变移速 |

### 当前效果列表

| id | 效果 |
|-----|------|
| heal_50 | 即时回血 50 点 |
| speed_30 | 射速+0.3 |
| power_up | 攻击+15 + 伤害倍率+20% |
| crit_up | 暴击率+15% + 暴击伤害+40% |
| power_boost | 攻击+10 + 伤害倍率+15% |
| iron_wall | 血量上限+100 + 防御+15 |
| lucky_aura | 暴击率+10% + 暴击伤害+30% |

---

## 物品数据 `data/items/*.tres`

### 当前物品列表

| 物品 | 类型 | 品质 | 价值 | 效果 |
|------|------|------|------|------|
| 生命药水 | 消耗品 | 精良(1) | 30 | 回血50 |
| 速度药剂 | 消耗品 | 稀有(2) | 99 | 射速+0.3(10s) |
| 力量药水 | 消耗品 | 稀有(2) | 150 | 攻击+10+倍率+15%(15s) |
| 铁壁药水 | 消耗品 | 稀有(2) | 180 | 血量+100+防御+15(12s) |
| 幸运符 | 消耗品 | 史诗(3) | 300 | 暴击率+10%+爆伤+30%(10s) |
| 铁矿石 | 材料 | 普通(0) | 40 | — |
| 魔法碎片 | 材料 | 史诗(3) | 400 | — |
| 古老硬币 | 收藏品 | 精良(1) | 100 | — |
| (更多物品见 `data/items/` 目录) |

---

## 新增内容指南

### 新增消耗品（零代码）

1. 在 `data/effects/` 创建新效果 `.tres`（EffectData 资源）
2. 在 `data/items/` 创建新物品 `.tres`（ConsumableItemData）
3. 在 `assets/` 添加图标
4. 在 `data/data_registry.tres` 中添加路径
5. 在 `data/drop_tables/` 中添加 DropEntry

### 新增技能

1. 在 `data/skills/` 创建 `.tres`（SkillData）
2. 在 `data/data_registry.tres` 的 `skill_paths` 添加路径
3. ⚠️ 技能效果逻辑需在 `target.gd` 的 `_on_skill_activated` 中添加代码

### 新增怪物类型

1. 创建新场景继承 `enemy.gd`
2. 设置不同的 `drop_table`
3. 修改 `enemy_spawner.gd` 的生成逻辑

### 完整示例：新增冰霜药水

1. 创建 `data/effects/frost_shield.tres`：id=frost_shield, defense_change=20
2. 创建 `data/items/frost_potion.tres`：ConsumableItemData, id=frost_potion, effect_ids=["frost_shield"]
3. 在 `default_drop_table.tres` 添加 weight=10

---

## 快速调参参考

| 目标 | 修改方式 |
|------|----------|
| 游戏更难 | 降低 `wave_duration`、提高 `enemy_atk_*`、降低 `max_hp` |
| 游戏更简单 | 提高 `spawn_interval_min`、降低 `enemy_hp_base`、提高 `max_hp` |
| 掉落更多 | 提高 `drop_base_chance`、提高 `gold_per_level`、增加物品权重 |
| 升级更便宜 | 降低 `*_base_cost`、降低 `cost_multiplier` |
| 效果更强 | 修改对应的 `data/effects/*.tres` |
| 调整波次节奏 | 修改 `wave_duration` / `break_duration` / `wave_bonus_mult` |
