# OutBugBro 项目记忆

## 项目概况
- **引擎**: Godot 4.5.1 (Mobile 渲染器)
- **类型**: 2D 肉鸽/弹幕射击游戏（最终目标 PVP 在线多人）
- **路径**: e:\HuaweiMoveData\Users\wudi1\Documents\out-bug-bro
- **工作区**: 中文 Windows，GDScript，数据驱动（.tres），组件化架构

## 核心架构
- **EventBus**（Autoload）: 字符串事件总线，`listen/dispatch`，松耦合通信
- **GameManager**（Autoload）: 全局状态（MENU/PLAYING/PAUSED）、暂停、场景切换
- **Component 基类**: 组合模式，`_setup()/_tick()` 覆写，`entity` 属性引用宿主
- **数据驱动**: 所有物品/效果/技能用 .tres（Resource）配置，DataRegistry 集中管理路径

## 目录结构（精简）
```
core/autoload/     → 全局单例（EventBus/GameManager/InventoryManager/EffectManager/CurrencyManager/ComboManager/SkillManager/SaveManager/MetaProgression/UITheme）
core/base/         → 基类（Component/ItemData/EffectData/DropTable/DropEntry/SkillData/PlayerConfig/WaveConfig）
core/components/   → 组件（HealthComponent/ShootingComponent/MoveComponent/AttackComponent/PlayerStats/TrailComponent/DashComponent）
core/ui_theme.gd   → iOS 暗色风格统一工具（半透明+12px圆角+赛博朋克边框）
data/              → .tres 数据资源（items/effects/skills/drop_tables/wave_config）
scenes/world/      → 世界（target/bullet/enemy_bullet/enemy_spawner/explosion_effect/game_world）
scenes/enemies/    → 敌人（enemy_a/fast_enemy/tank_enemy/ranged_enemy/boss + AI行为多样性）
scenes/ui/         → UI（InventoryUI/StatsPanel/WaveDisplay/WaveAnnounce/ComboDisplay/StatusEffectBar/DeathScreen/TargetHpBar/SkillBar/BossHpBar/PauseMenu/game_hud/TutorialOverlay/meta_upgrades）
scenes/challenge/  → 挑战模式（challenge_mode.gd/tscn — 独立Boss战）
scenes/main_menu.tscn → 主菜单（iOS暗色风+粒子雨+闪电+呼吸标题+挑战模式按钮）
scenes/main.tscn   → 纯组合场景（GameWorld + UILayer 实例）
assets/            → 美术资源
```

## 编码哲学
- 简洁优先，每脚本 < 150 行
- 数据用 .tres（Resource），逻辑用组件
- EventBus 解耦，避免硬引用
- 信号驱动，松耦合
- 命名 snake_case，中文注释
- 实体用组合模式：Component 子节点 + 宿主代理

## 最近更新（2026-05-28）
- **手动射击**: 去掉自动射击，改为鼠标左键射击/蓄力。AUTO模式自动瞄准但手动射击，MOUSE模式手动瞄准+手动射击
- **HUD元进度升级**: Tab键或按钮打开升级面板，金币可在游戏中直接升级元数据
- **方框限制区域**: ArenaBounds Autoload，2倍摄像机视角方框，玩家和敌人限制在方框内
- **挑战模式**: 主菜单进入，独立Boss战（222级大虫，限时300s，99血包，只能位移，评分=造成伤害/受到伤害，保存评分）
- **位移技能 (Dash)**: DashComponent，Q键触发，鼠标方向，10s CD，击杀减1s CD
- **金币经济重平衡**: 击杀金币15/级，元进度费用降低
- **CurrencyManager 信号修复**: `add()`/`spend()` 手动 emit `changed`

## 踩坑记录（最新）
- **手写 .tscn 不可靠**: Godot 4.5 手写 .tscn 极易解析失败。新 .tscn 必须参照已有的正确格式
- **.tscn 主题覆写**: 不能用 GDScript 方法语法，必须用属性语法（`theme_override_constants/separation = 16`）
- **StyleBoxFlat**: 没有 `corner_radius_all` 属性，只能用 `set_corner_radius_all()` 方法
- **GDScript setter 陷阱**: `var x: int = 0: set(v)` — 用 `x += 1` 不会触发 setter，必须 `x = x + 1` 或手动 emit 信号
- **暂停态 UI**: 所有需要在暂停时交互的面板必须设 `process_mode = Node.PROCESS_MODE_ALWAYS`
- **CharacterBody2D 移动**: 用 `velocity = dir * speed` + `move_and_slide()`
- **_ready() 中 add_child**: 可能触发 "busy setting up children" 错误，需 `call_deferred()`

## 待办事项
- [ ] 地图多样性/程序生成（目前方框区域）
- [ ] 武器系统（目前只有一种射击模式）
- [ ] 多人联网（最终目标，尚未开始）
- [ ] UI 进一步美化（毛玻璃 Shader 效果）
- [ ] 音效 + 音乐系统
- [ ] 成就系统
- [x] 挑战模式（已实现）
- [x] 位移技能（已实现）
- [x] 方框限制区域（已实现）
- [x] 手动射击（已实现）
