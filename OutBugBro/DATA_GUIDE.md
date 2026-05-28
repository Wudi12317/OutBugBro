# OutBugBro 策划数据修改指南

> **所有数值调整都在 .tres 文件中完成，无需修改代码！**
> 在 Godot 编辑器中双击 .tres 文件，即可在 Inspector 面板中直接编辑。

---

## 📁 数据文件总览

| 文件 | 路径 | 用途 |
|------|------|------|
| 玩家配置 | `data/player_config.tres` | 初始属性、升级加成、费用曲线 |
| 波次配置 | `data/wave_config.tres` | 怪物属性、生成节奏、掉落概率、休息期、清波奖励 |
| 掉落表 | `data/drop_tables/*.tres` | 不同怪物的物品掉落池与权重 |
| 效果数据 | `data/effects/*.tres` | 每种 Buff/Debuff 对属性的改变 |
| 物品数据 | `data/items/*.tres` | 物品名称/描述/品质/效果关联 |

---

## 1️⃣ 玩家配置 `data/player_config.tres`

### 基础属性（游戏开始时的初始值）

| 参数 | 当前值 | 说明 | 调大效果 |
|------|--------|------|----------|
| `max_hp` | 500 | 初始最大生命 | 更耐打 |
| `damage` | 25 | 初始攻击力 | 每发子弹伤害更高 |
| `defense` | 10 | 初始防御力 | 每10点防御减1受伤 |
| `crit_rate` | 0.05 | 初始暴击率 | 5%概率暴击 |
| `crit_damage` | 0.25 | 初始暴击伤害加成 | 暴击时伤害×1.25 |
| `fire_rate` | 1.0 | 初始射速（次/秒） | 每秒射击次数更多 |
| `move_speed` | 0.0 | 初始移动速度 | 0=固定炮台，>0可移动 |

### 各属性升级组

| 属性 | 每级增长 | 基础费用 | 说明 |
|------|----------|----------|------|
| 生命 max_hp | +50 | 30 | 每级+50最大HP |
| 攻击 damage | +5 | 40 | 每级+5攻击力 |
| 防御 defense | +3 | 50 | 每级+3防御（=减0.3伤） |
| 暴击 crit_rate | +0.03 | 60 | 每级+3%暴击率 |
| 爆伤 crit_damage | +0.15 | 50 | 每级+15%暴击伤害 |
| 射速 fire_rate | +0.3 | 80 | 每级+0.3射速 |
| 移速 move_speed | +15 | 60 | 每级+15移动速度 |

### 升级费用公式

```
第N级费用 = base_cost × cost_multiplier ^ N
```

| 参数 | 当前值 | 说明 |
|------|--------|------|
| `cost_multiplier` | 1.5 | 费用倍率（1.5 = 每级贵50%） |

**费用示例**（以HP为例，base_cost=30）：

| 等级 | 费用 |
|------|------|
| 0→1 | 30 |
| 1→2 | 45 |
| 2→3 | 67 |
| 3→4 | 101 |
| 4→5 | 151 |

---

## 2️⃣ 波次配置 `data/wave_config.tres`

### 波次节奏

| 参数 | 当前值 | 说明 |
|------|--------|------|
| `wave_duration` | 30.0 | 每波战斗持续时间（秒） |
| `break_duration` | 5.0 | 波次间休息时间（秒），可使用物品/升级 |
| `max_enemies` | 10 | 屏幕最大同时存活敌人数 |
| `wave_bonus_mult` | 100 | 清波奖励 = wave × 此值 |
| `spawn_margin` | 50.0 | 敌人在屏幕外生成的边距 |

**波次流程**：战斗30s → 休息5s → 战斗30s → ...

### 生成间隔（逐波递减）

| 参数 | 当前值 | 说明 |
|------|--------|------|
| `spawn_interval_base` | 4.0 | 第1波生成间隔（秒） |
| `spawn_interval_min` | 1.6 | 生成间隔下限（最快多快） |
| `spawn_easy_reduction` | 0.1 | 轻松期每波间隔减少量 |
| `spawn_mid_reduction` | 0.25 | 普通期每波间隔减少量 |
| `spawn_hard_reduction` | 0.4 | 困难期每波间隔减少量 |

### 难度阶段

| 参数 | 当前值 | 说明 |
|------|--------|------|
| `easy_wave_max` | 3 | 第1~3波为轻松期 |
| `hard_wave_start` | 11 | 第11波起为困难期 |

**阶段示意**：轻松(1-3) → 普通(4-10) → 困难(11+)

### 怪物属性（根据波次等级计算）

| 参数 | 当前值 | 公式 | 说明 |
|------|--------|------|------|
| `enemy_hp_base` | 25 | `base × level × 1.1` | 怪物基础HP |
| `enemy_hp_level_mult` | 1.1 | — | HP随等级倍率 |
| `enemy_atk_base` | 2 | 累加 | 怪物基础攻击 |
| `enemy_atk_easy` | 0.5 | +0.5/波 | 轻松期每波攻击增加 |
| `enemy_atk_mid` | 1.0 | +1.0/波 | 普通期每波攻击增加 |
| `enemy_atk_hard` | 2.0 | +2.0/波 | 困难期每波攻击增加 |
| `enemy_speed_base` | 40.0 | 累加 | 怪物基础速度 |
| `enemy_speed_easy` | 3.0 | +3/波 | 轻松期每波速度增加 |
| `enemy_speed_mid` | 6.0 | +6/波 | 普通期每波速度增加 |
| `enemy_speed_hard` | 10.0 | +10/波 | 困难期每波速度增加 |
| `enemy_interval_base` | 3.0 | 递减 | 怪物基础攻击间隔 |
| `enemy_interval_min` | 0.6 | — | 攻击间隔下限 |
| `enemy_interval_easy` | 0.05 | -0.05/波 | 轻松期间隔减少 |
| `enemy_interval_mid` | 0.12 | -0.12/波 | 普通期间隔减少 |
| `enemy_interval_hard` | 0.15 | -0.15/波 | 困难期间隔减少 |

### 掉落

| 参数 | 当前值 | 说明 |
|------|--------|------|
| `drop_base_chance` | 0.80 | 基础掉落概率（80%） |
| `drop_per_wave` | 0.06 | 每波增加的掉落概率 |
| `drop_cap` | 0.80 | 掉落概率上限 |
| `gold_per_level` | 50 | 每级金币掉落（怪物等级×50） |

**实际掉落概率** = `基础概率 + 连击加成(combo × 5%)`，上限50%额外加成

---

## 3️⃣ 掉落表 `data/drop_tables/*.tres`

### 掉落表结构

掉落表使用 `DropTable` Resource，包含若干 `DropEntry`（物品+权重）。

| 字段 | 类型 | 说明 |
|------|------|------|
| `entries` | Array[DropEntry] | 掉落条目列表 |

### DropEntry 字段

| 字段 | 类型 | 说明 |
|------|------|------|
| `item` | ItemData | 物品数据引用 |
| `weight` | int | 权重（越大越容易掉） |

### 默认掉落表 `default_drop_table.tres`

| 物品 | 权重 | 实际概率 | 品质 |
|------|------|----------|------|
| 铁矿石 | 50 | 38% | 普通(白) |
| 生命药水 | 30 | 23% | 精良(绿) |
| 古老硬币 | 25 | 19% | 精良(绿) |
| 速度药剂 | 15 | 12% | 稀有(青) |
| 力量药水 | 8 | 6% | 稀有(青) |
| 铁壁药水 | 6 | 5% | 稀有(青) |
| 魔法碎片 | 5 | 4% | 史诗(紫) |
| 幸运符 | 2 | 2% | 史诗(紫) |

### 新增掉落表

1. 复制 `default_drop_table.tres`
2. 修改 entries 中的物品和权重
3. 在 Enemy 子类中通过 `@export var drop_table` 引用

### 精英怪掉落规则

- 精英怪（10%概率生成，体型1.5倍，HP×3）
- **100%掉落**且**保证稀有(rarity≥2)以上**
- 只从掉落表中筛选 rarity ≥ 2 的物品

---

## 4️⃣ 效果数据 `data/effects/*.tres`

每个效果文件包含以下字段（默认0=无改变）：

| 字段 | 类型 | 说明 | 正值效果 |
|------|------|------|----------|
| `id` | String | 唯一标识符 | — |
| `icon` | Texture2D | 效果图标 | — |
| `heal_amount` | float | 即时回血量 | 回血 |
| `hp_change` | float | 改变最大生命上限 | 增加血量上限 |
| `fire_rate_change` | float | 改变射速 | 射速增加 |
| `damage_change` | float | 改变伤害（固定值） | 伤害增加 |
| `damage_mult_change` | float | 改变伤害倍率 | 伤害倍率增加 |
| `crit_rate_change` | float | 改变暴击率 | 暴击率增加 |
| `crit_damage_change` | float | 改变暴击伤害 | 暴击伤害增加 |
| `defense_change` | float | 改变防御力 | 防御增加 |
| `move_speed_change` | float | 改变移动速度 | 移速增加 |

### 当前效果

| 文件 | id | 效果 |
|------|-----|------|
| `heal_50.tres` | heal_50 | 即时回血50点 |
| `speed_30.tres` | speed_30 | 射速+0.3 |
| `power_up.tres` | power_up | 攻击+15 + 伤害倍率+20% |
| `crit_up.tres` | crit_up | 暴击率+15% + 暴击伤害+40% |
| `power_boost.tres` | power_boost | 攻击+10 + 伤害倍率+15% |
| `iron_wall.tres` | iron_wall | 血量上限+100 + 防御+15 |
| `lucky_aura.tres` | lucky_aura | 暴击率+10% + 暴击伤害+30% |

### 🆕 新增效果步骤

1. 右键 `data/effects/` → 新建资源 → 选择 `EffectData`
2. 设置 `id`（唯一！如 "freeze_all"）、`icon`
3. 设置属性改变值（只改需要改的字段，其余保持0）
4. 保存为 `data/effects/新效果名.tres`
5. 如果想让消耗品使用此效果，在对应物品的 `effect_ids` 中添加此 id

---

## 5️⃣ 物品数据 `data/items/*.tres`

### 公共字段（所有物品类型）

| 字段 | 类型 | 说明 |
|------|------|------|
| `id` | String | 唯一标识符 |
| `name` | String | 显示名称 |
| `icon` | Texture2D | 物品图标 |
| `desc` | String | 描述文字 |
| `rarity` | int | 品质等级 0=普通 1=精良 2=稀有 3=史诗 4=传说 |
| `value` | int | 出售价值（金币） |

### 消耗品额外字段（ConsumableItemData）

| 字段 | 类型 | 说明 |
|------|------|------|
| `effect_ids` | PackedStringArray | 效果ID列表（对应 effects/*.tres 的 id） |
| `effect_duration` | float | 增益持续时间（秒），即时效果忽略此值 |

### 材料额外字段（MaterialItemData）

| 字段 | 类型 | 说明 |
|------|------|------|
| `sources` | PackedStringArray | 获得途径描述列表 |

### 收藏品（CollectibleItemData）

无额外字段。

### 当前物品

| 物品 | 类型 | 品质 | 价值 | 效果 |
|------|------|------|------|------|
| 生命药水 | 消耗品 | 精良(1) | 30 | 回血50 |
| 速度药剂 | 消耗品 | 稀有(2) | 99 | 射速+0.3（10s） |
| 力量药水 | 消耗品 | 稀有(2) | 150 | 攻击+10 + 伤害倍率+15%（15s） |
| 铁壁药水 | 消耗品 | 稀有(2) | 180 | 血量上限+100 + 防御+15（12s） |
| 幸运符 | 消耗品 | 史诗(3) | 300 | 暴击率+10% + 暴击伤害+30%（10s） |
| 铁矿石 | 材料 | 普通(0) | 40 | — |
| 魔法碎片 | 材料 | 史诗(3) | 400 | — |
| 古老硬币 | 收藏品 | 精良(1) | 100 | — |

### 🆕 新增物品步骤

1. 右键 `data/items/` → 新建资源
2. 选择对应类型：`ConsumableItemData`/`MaterialItemData`/`CollectibleItemData`
3. 填写字段（**id 必须唯一！**）
4. 如是消耗品，在 `effect_ids` 中填写效果ID
5. 保存为 `data/items/新物品名.tres`
6. 在 `data/drop_tables/default_drop_table.tres` 的 entries 中添加新条目

### 🆕 新增物品完整示例："冰霜药水"

**步骤1**：创建效果 `data/effects/frost_shield.tres`
- id = "frost_shield"
- defense_change = 20.0
- move_speed_change = 50.0

**步骤2**：创建物品 `data/items/frost_potion.tres`
- 类型选择 ConsumableItemData
- id = "frost_potion", name = "冰霜药水"
- rarity = 2, value = 120
- effect_ids = ["frost_shield"]
- effect_duration = 8.0

**步骤3**：在掉落表中添加
- 打开 `data/drop_tables/default_drop_table.tres`
- 在 entries 末尾添加新条目：item=frost_potion, weight=10

---

## 6️⃣ 🆕 连击系统

- 2秒内连续击杀累计连击数
- 每级连击增加 5% 掉率加成（上限 50%）
- 连击数 ≥3 绿色，≥5 青色，≥10 金色
- 连击中断时掉率加成归零

---

## 7️⃣ 🆕 精英怪

- 每次生成怪物有 10% 概率成为精英
- 精英怪特征：HP×3、体型1.5倍、金色边框、等级显示★
- 掉落：100%且保证稀有以上
- 精英概率在 `EnemySpawner` 的 `elite_chance` 属性中调整

---

## 8️⃣ 🆕 波次公告

- 战斗阶段结束 → 休息期（5秒），屏幕中央"休息"提示
- 休息期结束 → 新波次开始，屏幕中央"第N波"大字提示
- 清波奖励：wave × 100 金币，在公告中显示
- 波次阶段（轻松/普通/困难）用颜色区分

---

## 9️⃣ 🆕 品质掉落视觉反馈

| 品质 | 视觉效果 |
|------|----------|
| 传说(4) | 金色光柱 + 大字 |
| 史诗(3) | 紫色脉冲扩散 |
| 稀有(2) | 青色闪烁 |
| 精良(1) | 绿色文字（默认大小） |
| 普通(0) | 无特效 |

---

## 🔟 🆕 新增怪物指南

### 创建怪物子类

1. 在 `scenes/enemies/` 下创建新脚本，继承 `Enemy`
2. 覆写需要的属性（如自定义 drop_table）
3. 创建对应的 .tscn 场景

### 示例：快速怪（FastEnemy）

```gdscript
## 快速怪 — 速度快但血量低
class_name FastEnemy
extends Enemy

func _ready() -> void:
	super._ready()
	# 覆写移动速度
	_move.move_speed *= 1.5
```

### 在 Spawner 中使用

修改 `enemy_spawner.gd` 的 `ENEMY_SCENE` 常量指向新怪物场景，或实现多类型随机生成。

---

## 🔢 快速调参参考

### 想让游戏更难？
- `wave_config.tres`: 降低 `wave_duration`、提高 `enemy_atk_*`、提高 `enemy_speed_*`
- `player_config.tres`: 降低 `max_hp`、提高 `*_base_cost`
- 降低连击加成：修改 `combo_manager.gd` 的 `COMBO_BONUS`

### 想让游戏更简单？
- `wave_config.tres`: 提高 `spawn_interval_min`、降低 `enemy_hp_base`
- `player_config.tres`: 提高 `max_hp`、提高 `*_per_level`
- 增加休息时间：提高 `break_duration`

### 想让掉落更多？
- `wave_config.tres`: 提高 `drop_base_chance` 和 `drop_cap`、提高 `gold_per_level`
- `drop_tables/default_drop_table.tres`: 增加物品权重
- 提高精英概率：修改 `EnemySpawner.elite_chance`

### 想让某个效果更强？
- 修改对应的 `data/effects/*.tres`

### 想让升级更便宜？
- `player_config.tres`: 降低 `*_base_cost`、降低 `cost_multiplier`

### 想调整波次节奏？
- 更短战斗：降低 `wave_duration`
- 更长休息：提高 `break_duration`
- 更多清波奖励：提高 `wave_bonus_mult`
