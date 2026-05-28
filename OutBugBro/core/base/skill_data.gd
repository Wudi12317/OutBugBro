## 技能数据 — 定义一个主动技能的所有属性，外部 .tres 可配置
class_name SkillData
extends Resource

@export var id: String = ""               ## 技能编号（唯一标识）
@export var skill_name: String = ""       ## 显示名
@export var desc: String = ""            ## 描述
@export var icon: Texture2D             ## 图标（可选）
@export var unlock_wave: int = 1         ## 解锁波次
@export var cost: int = 0                ## 购买金币
@export var cooldown: float = 20.0       ## 冷却时间（秒）
@export var duration: float = 5.0       ## 持续时间（秒）
@export var key_index: int = 0           ## 对应按键序号 0-6（显示用）
