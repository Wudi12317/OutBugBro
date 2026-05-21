# OutBugBro 项目记忆

## 项目概况
- **引擎**: Godot 4.5.1 (Mobile 渲染器)
- **类型**: 2D 游戏（待定具体类型）
- **路径**: e:\HuaweiMoveData\Users\wudi1\Documents\out-bug-bro

## 架构决策
- **2026-05-10**: 建立核心框架
  - EventBus（Autoload）: 字符串事件总线，`listen/unlisten/dispatch`，松耦合通信
  - GameManager（Autoload）: 全局状态（MENU/PLAYING/PAUSED）、暂停、场景切换
  - Component 基类: 组合模式，`_setup()/_tick()` 覆写，`entity` 属性引用宿主
- **2026-05-10**: 物品数据体系
  - ItemData（Resource 基类）: name/icon/desc/rarity/value/type + get_rarity_color()
  - ConsumableItemData: effect_ids（效果编号列表，待 EffectData 定义）
  - MaterialItemData: sources（获得途径列表）
  - CollectibleItemData: 无额外属性
  - 子类 _init() 自动设置 type，编辑器中创建对应 .tres 即可
- **2026-05-10**: 效果数据体系
  - EffectData（Resource）: id + 9 个属性改变字段（hp/fire_rate/item_prob/damage/damage_mult/crit_rate/crit_damage/defense/hp_regen），默认 0
  - get_active_effects() 返回非零效果字典
  - ItemData 增加 id 字段（唯一标识符）
- **2026-05-10**: 背包系统
  - InventoryManager（Autoload）: 数据层，add_item/remove_item，同 id 自动堆叠
  - InventoryUI: 左 10 列格子（GridContainer + ScrollContainer）+ 右物品信息面板
  - InventorySlot: 格子控件，品质色背景 + 贴图 + 数量
  - B 键开关，% 唯一节点引用
- **2026-05-13**: 状态效果系统
  - EffectManager（Autoload）: 管理激活效果，支持倒计时/永久，同id刷新时长
  - StatusEffectBar: 右上角效果栏（.tscn + .gd），HFlowContainer 排列图标
  - EffectSlot: 40×40 效果格子，品质色背景 + 贴图 + 倒计时，点击查看详情
  - 详情面板：效果名 + 属性改变 + 剩余时间
  - E 键测试添加随机效果（5-15秒）
  - 4 个测试效果: heal_50 / speed_30 / power_up / crit_up
- **2026-05-13**: 战斗系统
  - Enemy: 向 Target 移动，到达30px内停下攻击，有血条+白色闪烁
  - Target: 蓝色方块，可射击（AUTO/MOUSE模式，Tab切换），有血量(500)
  - Bullet: 黄色小子弹，碰撞层分离(layer=4,mask=2)，2秒生命周期
  - EnemySpawner: 屏幕外生成怪物，每2秒一只，最多20只
  - GameOver: Target 死亡后显示，按 R 重开
  - TargetHpBar: 左下角血条，EventBus 解耦
  - 碰撞层: Target=1, Enemy=2, Bullet=4; 子弹只检测敌人(layer2)
- **2026-05-14**: 货币系统 + 组件化重构 + 属性系统
  - CurrencyManager（Autoload）: 全局货币管理，add/spend/has_enough，changed 信号
  - 组件化（core/components/）: 从 Target/Enemy 提取逻辑为独立组件
    - HealthComponent: hp/max_hp/take_damage/heal/get_ratio，信号 health_changed + died
    - ShootingComponent: 瞄准(AUTO/MOUSE) + 射击逻辑，fire_rate/rotate_speed/bullet_scene
    - MoveComponent: 向目标移动，move_speed/stop_distance/is_in_range
    - AttackComponent: 定时攻击，attack_damage/attack_rate，try_attack()
    - PlayerStats: 属性系统，初始值 750HP/20ATK/25%CRIT/50%CD/10DEF，效果加成计算，防御公式(每10DEF减1伤)
  - Target 重构: 挂载 HealthComponent + ShootingComponent + PlayerStats
    - take_damage 经 calc_damage_taken（防御减伤）
    - stats_changed 同步血量上限/射速
    - 子弹伤害由 PlayerStats.calc_damage_dealt()（含暴击）驱动
  - Enemy 重构: 挂载 HealthComponent + MoveComponent + AttackComponent，代理 take_damage
  - InventoryUI: 居中窗口式，售卖内嵌（HSlider拉条 + 确认按钮）
  - StatsPanel: 右下角属性面板（HP/ATK/DEF/CRIT/CD/SPD）
  - GameOver 修复: process_mode=ALWAYS + _input（暂停时仍接收R键）

- **2026-05-15**: 项目复盘修复 + 数据指南
  - 移除 EffectData 死字段 item_prob_change / hp_regen_change（无消费方）
  - 新增 move_speed_change 字段 + PlayerStats.get_move_speed()
  - PlayerConfig 新增 move_speed 升级组（初始0，每级+15，费用60）
  - TargetHpBar .tscn 硬编码500修正为0
  - 创建 DATA_GUIDE.md 策划数据修改指南

- **2026-05-16**: 掉落系统 + 波次系统 + 可玩性大更新
  - 修复 DropIndicator.set_deferred 时序 bug（add_child 立即触发 _ready，不能 deferred）
  - 品质掉落视觉反馈: 传说→金色光柱, 史诗→紫色脉冲, 稀有→青色闪烁
  - DropTable Resource: 提取 enemy.gd 硬编码掉落表为 .tres 配置，支持不同怪物不同表
  - DropEntry: item + weight 子资源
  - WaveConfig 新增: break_duration(5s)/wave_bonus_mult(100)
  - EnemySpawner 重构为状态机: FIGHTING → BREAK → FIGHTING
  - 休息期暂停生成，清波奖励(wave×100金币)
  - WaveAnnounce: 屏幕中央大字公告（新波次/休息/奖励）
  - WaveDisplay 增强: 休息倒计时/敌人数/掉落率
  - ComboManager（Autoload）: 2秒窗口连击系统，每级+5%掉率(上限50%)
  - ComboDisplay: 连击数字 + 掉率加成显示（≥3绿≥5青≥10金）
  - 精英怪: 10%概率, HP×3, 体型1.5倍, 金色边框, 100%掉落且稀有以上
  - enemy.gd: is_elite 标记 + _drop_rare_item() 精英掉落
  - 新增3效果: power_boost/iron_wall/lucky_aura
  - 新增3物品: 力量药水/铁壁药水/幸运符
  - 掉落表含8种物品（新增3种权重8/6/2）
  - InventoryUI 效果描述翻译为中文（_describe_effects + _attr_label）
  - DATA_GUIDE.md 全面重写，含新增怪物/物品/效果教程

- **2026-05-16**: 技能系统 + 游戏节奏 + 掉落修复
  - 修复掉落不工作：default_drop_table.tres 手写格式不可靠，改为 _build_default_drop_table() 程序化构建
  - 技能系统: SkillData(Resource) + SkillManager(Autoload) + SkillBar UI
  - 5个主动技能:
    1. 临时护盾(W3, 1000g, 5s免疫, 20sCD)
    2. 主动防御(W7, 1500g, 75%反伤+80%减伤8s, 80sCD)
    3. 应急修理(W10, 4500g, 血回90%+10s极大增幅, 120sCD)
    4. 制导导弹(W15, 18000g, 清怪+20s即死, 200sCD)
    5. 头油(免费, 弹开+减速15%5s, 30sCD)
  - emergency_buff效果: +100ATK/+100%倍率/+50%暴击/+100%爆伤/+30DEF
  - Target技能交互: 护盾免疫/反伤(传attacker)/修理回血+buff
  - MoveComponent增强: apply_knockback() + apply_slow()
  - AttackComponent: try_attack()传入entity作为attacker参数
  - SkillBar: 底部10格(5技能1-5键+5消耗品6-0键)，点击购买/激活
  - 游戏节奏加快: max_enemies=30, spawn_base=2.5s→min=0.3s, speed_base=60
  - StatsPanel: emergency_buff激活时属性金色字体
  - InventoryUI: 物品详情显示掉落率, 移除F/E测试键
  - 掉落概率: DropTable.get_chance_for(id) + inventory_ui调用

- **2026-05-18**: 数据驱动架构重构 + 掉落表修复 + 全面审计 + 程序员文档
  - DataRegistry(Resource): 集中管理 item_paths/effect_paths/skill_paths，三个 Manager 改为从注册表读取
  - 添加新消耗品/效果：创建 .tres + 在 data_registry.tres 添加路径 + 在掉落表添加条目 → 零代码
  - 添加新技能：.tres + data_registry + target.gd 的 match 分支（效果逻辑需代码）
  - enemy.gd drop_table 优先 load .tres，失败才程序化构建
  - 修复 stats_panel 防御显示 /10→/8（实际公式每8DEF减1伤）
  - 全面审计47个 .gd 文件，无严重 bug
  - 创建 DEV_GUIDE.md 程序员参考手册（函数级说明+数据驱动指南+踩坑速查）

## 踩坑记录
- **mouse_filter**: UILayer 中非交互 Control 必须设 mouse_filter=2(IGNORE)，否则遮挡下层按钮
- **stop_distance**: 必须大于碰撞体半径之和，否则物理碰撞弹开导致永远达不到
- **暂停时输入**: `_unhandled_input` 暂停时不触发，需 `process_mode=ALWAYS` + `_input`
- **.tscn 覆盖**: 子实例化场景时，父 .tscn 会覆盖子节点的属性（如 anchors_preset），导致布局异常

## 编码哲学
- 简洁优先，每脚本 < 150 行
- 数据用 .tres（Resource），逻辑用组件
- EventBus 解耦，避免硬引用
- 信号驱动，松耦合
- 命名 snake_case，中文注释
- 实体用组合模式：Component 子节点 + 宿主代理

## 目录结构
```
core/autoload/     → 全局单例（EventBus/GameManager/InventoryManager/EffectManager/CurrencyManager/ComboManager/SkillManager/SaveManager）
core/base/         → 基类（Component/ItemData/EffectData/DropTable/DropEntry/SkillData 等）
core/components/   → 组件（HealthComponent/ShootingComponent/MoveComponent/AttackComponent/PlayerStats）
data/              → .tres 数据资源
data/effects/      → 效果数据（heal_50/speed_30/power_up/crit_up/power_boost/iron_wall/lucky_aura/emergency_buff/dragon_fury/phoenix_revive）
data/items/        → 物品数据（health_potion/speed_potion/power_potion/iron_wall_potion/lucky_charm/iron_ore/magic_shard/coin/dragon_heart/phoenix_feather/meteor_core/castorice）
data/skills/       → 技能数据（shield/reflect/repair/missile/head_oil）
data/drop_tables/  → 掉落表（default_drop_table.tres）
scenes/            → 功能模块场景
scenes/enemies/    → 敌人（enemy_a/fast_enemy/tank_enemy/ranged_enemy/boss）
scenes/world/      → 世界（target/bullet/enemy_bullet/enemy_spawner/explosion_effect）
scenes/ui/         → UI（InventoryUI/StatsPanel/WaveDisplay/WaveAnnounce/ComboDisplay/StatusEffectBar/DeathScreen/TargetHpBar/SkillBar/BossHpBar/PauseMenu）
scenes/main_menu.tscn → 主菜单（iOS暗色风+粒子雨+闪电+呼吸标题）
assets/            → 美术资源
```

## 踩坑记录
- **mouse_filter**: UILayer 中非交互 Control 必须设 mouse_filter=2(IGNORE)，否则遮挡下层按钮
- **stop_distance**: 必须大于碰撞体半径之和，否则物理碰撞弹开导致永远达不到
- **暂停时输入**: `_unhandled_input` 暂停时不触发，需 `process_mode=ALWAYS` + `_input`
- **.tscn 覆盖**: 子实例化场景时，父 .tscn 会覆盖子节点的属性（如 anchors_preset），导致布局异常
- **set_deferred 时序**: `add_child()` 会立即触发 `_ready()`，如果用 `set_deferred` 设置数据，`_ready()` 中读取到的是旧值。应在 `add_child` 之前直接赋值
- **show() 冲突**: 自定义静态方法不要叫 `show`，会和 `CanvasItem.show()` 冲突导致编译错误，改名 `spawn`
- **手写 .tscn 不可靠**: 与 .tres 同理，Godot 4.5 手写 .tscn 极易解析失败。原因多样：`#` 注释被当颜色代码、uid 缺失、ext_resource id 格式不匹配等。**新敌人/子弹/UI 一律程序化构建，不再手写 .tscn**
- **preload vs load**: 手写 .tres 用 `preload` 编译时严格解析容易失败，改 `load` 运行时加载更宽容
- **.tres PackedStringArray 格式**: 手写 .tres 中 `effect_ids = PackedStringArray(["xxx"])` 会报 "Expected string" 解析错误，必须用 `effect_ids = ["xxx"]` 这种普通数组语法
- **Container mouse_filter**: HBoxContainer/VBoxContainer 默认 mouse_filter=STOP(0)，全屏底栏/顶栏会遮挡后面所有UI元素，必须设 IGNORE(2)
- **class_name vs autoload**: Autoload 单例自动注册为全局类名，脚本里再写 `class_name` 会冲突报错，删掉即可
- **Resource.name**: Resource 没有 `name` 属性（那是 Node 的），自定义 Resource 用 `skill_name` 等字段
- **class_name vs autoload**: Autoload 单例自动注册为全局类名，脚本里再写 `class_name` 会冲突报错，删掉即可
- **Button覆盖点击**: 用 flat=true 的 Button 覆盖整个格子做点击检测，比 `gui_input` 信号更可靠（不会被子节点拦截）
