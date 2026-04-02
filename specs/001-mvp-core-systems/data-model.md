# Data Model: 校园后勤管理模拟游戏 MVP

**Feature Branch**: `001-mvp-core-systems`
**Date**: 2026-04-01

## 核心实体

### 1. Student（学生）

| 字段 | 类型 | 说明 | 示例 |
| ---- | ---- | ---- | ---- |
| id | int | 唯一标识 | 1001 |
| name | String | 中文姓名 | "张三" |
| student_type | enum | 本科/研究生 | "undergraduate" |
| assigned_group | int | 所属宿舍组团ID | 3 |
| assigned_building | int | 所属宿舍楼栋ID | 15 |
| wallet_balance | float | 钱包余额（元） | 1500.0 |
| taste_preference | String | 口味偏好 | "spicy" / "mild" / "sweet" / "salty" |
| personality_tag | String | 性格标签 | "foodie" / "scholar" / "frugal" / "athlete" |
| satisfaction | float | 个人满意度 (0-100) | 72.5 |
| satisfaction_cafeteria | float | 食堂维度满意度 | 70.0 |
| satisfaction_dormitory | float | 宿舍维度满意度 | 80.0 |
| grid_position | Vector2i | 当前地图格子坐标 | (45, 32) |
| target_building | String | 当前目标建筑ID | "yinxing_yinhua" |
| state | enum | 当前状态 | "idle" / "moving" / "queuing_cafeteria" / "queuing_facility" / "eating" / "studying" / "sleeping" / "returning_late" / "exercising" |
| meals_today | int | 今日已就餐次数 | 2 |
| curfew_violated | bool | 今日是否门禁超时 | false |

**状态机**:
```
idle → moving → [到达目标] → queuing_cafeteria/queuing_facility/eating/studying/sleeping → idle
                               ↑ 超时放弃 → idle (满意度-)
                               ↑ 门禁超时 → returning_late → idle (满意度-)
                               ↑ 文娱活动 → exercising → idle
```

**状态说明**:
- `queuing_cafeteria`: 食堂窗口排队
- `queuing_facility`: 其他设施排队（如浴室、图书馆等）
- `returning_late`: 门禁超时返回中
- `exercising`: 文娱活动（体育馆、运动场）

**关系**: Student N:1 DormitoryGroup, Student N:1 Building

### 2. Building（建筑）— 基类

| 字段 | 类型 | 说明 | 示例 |
| ---- | ---- | ---- | ---- |
| id | String | 唯一标识 | "pinxue_a" |
| name | String | 建筑名称 | "品学楼A区" |
| type | enum | 建筑类型 | "cafeteria" / "dormitory" / "teaching" / "library" / "other" |
| grid_position | Vector2i | 地图格子坐标 | (60, 20) |
| grid_size | Vector2i | 占地格数 | (8, 6) |
| is_interactable | bool | 玩家是否可交互 | true / false |
| open_periods | Array[int] | 开放时段列表 | [0, 2, 4] (早晨/中午/傍晚) |
| upgrade_level | int | 当前升级等级 (1-5) | 1 |
| is_under_construction | bool | 是否施工中 | false |
| construction_remaining_days | int | 施工剩余天数 | 0 |

### 3. Cafeteria（食堂）— Building 子类

| 字段 | 类型 | 说明 | 示例 |
| ---- | ---- | ---- | ---- |
| restaurant_id | String | 餐厅ID | "chaoyang" |
| restaurant_name | String | 餐厅名称 | "朝阳餐厅" |
| area | String | 所属食堂区域 | "银杏苑" / "思学苑" / "春晖苑" |
| floors | Array[int] | 楼层列表（如[1,2]表示1楼和2楼） | [1] 或 [1, 2] |
| menu_scope | Array[String] | 可用菜品标签范围 | ["general", "sichuan"] |
| windows | Array[WindowSlot] | 窗口列表（按楼层分组） | [见下] |
| daily_revenue | float | 当日营收 | 8500.0 |
| daily_customer_count | int | 当日客流量 | 420 |
| total_revenue_semester | float | 本学期总营收 | 120000.0 |
| satisfaction_score | float | 食堂满意度 | 72.0 |

**餐厅列表**（9个）: 银桦、紫荆、芙蓉、学子、思源、家园、西北、朝阳（1楼+2楼）、清真

### 4. WindowSlot（食堂窗口）

| 字段 | 类型 | 说明 | 示例 |
| ---- | ---- | ---- | ---- |
| window_id | String | 窗口ID | "yinxing_yinhua_w1" |
| dish_id | String | 当前菜品ID（引用 Dish） | "hongshaorou" |
| price | float | 售价（元） | 15.0 |
| markup_rate | float | 加成率（0.0表示手动定价） | 0.0 |
| service_speed | float | 服务速度（人/时段） | 30 |
| staff_skill_level | int | 厨师技能等级 (1-5) | 2 |
| queue | Array[int] | 排队学生ID列表 | [1001, 1045, 1089] |
| queue_max_length | int | 排队上限（逻辑+UI限制，达到后新学生自动放弃该窗口） | 20 |
| daily_customers | int | 当日服务人数 | 85 |
| is_active | bool | 是否开放 | true |
| is_under_construction | bool | 是否施工中 | false |

**关系**: WindowSlot N:1 Cafeteria, WindowSlot 1:1 Dish (当前)

### 5. Dish（菜品）

| 字段 | 类型 | 说明 | 示例 |
| ---- | ---- | ---- | ---- |
| id | String | 菜品ID | "hongshaorou" |
| name | String | 菜品名称 | "红烧肉" |
| category | String | 菜品分类 | "meat" / "vegetable" / "noodle" / "staple" |
| taste_tag | String | 口味标签 | "spicy" / "mild" / "sweet" / "salty" / "halal" |
| base_cost | float | 食材成本（元） | 6.0 |
| quality_level | int | 质量等级 (1-5) | 4 |
| quality_score | float | 质量评分 (0-100) | 78.0 |
| available_for | Array[String] | 可供应的餐厅ID列表 | ["yinxing_yinhua", "sixue_furong"] |
| is_halal | bool | 是否清真 | false |

### 6. DormitoryGroup（宿舍组团）

| 字段 | 类型 | 说明 | 示例 |
| ---- | ---- | ---- | ---- |
| group_id | int | 组团ID | 1 |
| group_name | String | 组团名称 | "硕丰苑一组团" |
| student_type | enum | 本科/研究生 | "graduate" |
| buildings | Array[int] | 包含的楼栋ID列表 | [1, 2, 3, 4] |
| hot_water_start | int | 热水开始时段 | 2 (中午) |
| hot_water_end | int | 热水结束时段 | 6 (晚上) |
| electricity_price | float | 电费单价（元/度） | 0.55 |
| maintenance_frequency | int | 维修频率等级 (1-5) | 3 |
| cleanliness_level | int | 清洁等级 (1-5) | 3 |
| curfew_period | int | 门禁时段 | 5 (晚上, 表示23:00) |
| upgrade_level | int | 组团升级等级 (1-5) | 1 |
| is_under_construction | bool | 是否施工中 | false |

**组团运营成本计算**:
```
燃气费 = 基础值 × (热水结束时段 - 热水开始时段) × 楼栋数
维修费 = 基础值 × 维修频率 × 楼栋数
保洁费 = 基础值 × 清洁等级 × 楼栋数
```

### 7. DormitoryBuilding（宿舍楼栋）

| 字段 | 类型 | 说明 | 示例 |
| ---- | ---- | ---- | ---- |
| building_id | int | 楼栋ID | 1 |
| group_id | int | 所属组团ID | 1 |
| has_ac | bool | 是否有空调 | true |
| has_private_bath | bool | 是否独立卫浴 | true |
| capacity | int | 容纳学生数 | 200 |
| base_satisfaction_bonus | float | 基础满意度加成 | 5.0 |
| upgrade_level | int | 楼栋升级等级 | 1 |

### 8. Staff（员工）

| 字段 | 类型 | 说明 | 示例 |
| ---- | ---- | ---- | ---- |
| staff_id | int | 员工ID | 1001 |
| staff_type | enum | 岗位类型 | "chef" / "maintenance" / "cleaning" / "dorm_manager" |
| skill_level | int | 技能等级 (1-5, MVP固定不可培训) | 2 |
| assigned_building | String | 所属建筑ID | "yinxing_yinhua" |
| monthly_salary | float | 月薪（元，从game_params.json读取基础值） | 3500.0 |

**MVP 简化**: 员工系统自动配齐（根据建筑类型和规模自动生成员工），技能等级为固定初始值，不提供培训机制。

### 9. GameEvent（游戏事件）

| 字段 | 类型 | 说明 | 示例 |
| ---- | ---- | ---- | ---- |
| event_id | String | 事件ID | "health_inspection" |
| event_type | enum | 事件类型 | "inspection" / "breakdown" / "periodic" / "price_shock" |
| name | String | 事件名称 | "卫生检查" |
| description | String | 事件描述 | "市卫生局对食堂进行突击检查" |
| trigger_conditions | Dictionary | 触发条件 | {"min_day": 5, "probability": 0.3} |
| effects | Array[Dictionary] | 效果列表 | [{"target": "satisfaction_cafeteria", "change": -5}] |
| choices | Array[Dictionary] | 玩家选项 | [{"text": "加强清洁", "cost": 2000, "effect": {...}}] |
| is_periodic | bool | 是否周期性 | false |
| period_trigger | Dictionary | 周期触发条件 | {"semester_week": [17, 18], "name": "考试周"} |

### 9. Semester（学期）

| 字段 | 类型 | 说明 | 示例 |
| ---- | ---- | ---- | ---- |
| semester_number | int | 学期序号 | 2 |
| current_week | int | 当前周（从 TimeManager 同步） | 5 |
| current_day | int | 当前天 1-7（从 TimeManager 同步） | 3 (周三) |
| current_period | int | 当前时段 0-6（从 TimeManager 同步） | 2 (中午) |
| budget_allocated | float | 本学期拨付预算 | 500000.0 |
| budget_spent | float | 已支出 | 180000.0 |
| revenue_total | float | 总收入 | 250000.0 |
| rating | String | 上学期评级 | "B" |
| start_date | String | 开始日期 | "2026-09-01" |

**说明**: current_week/current_day/current_period 由 TimeManager 每帧同步更新，TimeManager 是运行时权威来源。Semester Resource 作为可序列化视图用于存档和 UI 绑定。

### 10. SaveSlot（存档位）

| 字段 | 类型 | 说明 | 示例 |
| ---- | ---- | ---- | ---- |
| slot_id | int | 存档位ID (1-5) | 1 |
| created_at | String | 创建时间（ISO 8601） | "2026-04-01T10:30:00" |
| updated_at | String | 更新时间（ISO 8601） | "2026-04-01T15:45:00" |
| semester_number | int | 学期序号 | 2 |
| current_week | int | 当前周 | 5 |
| overall_satisfaction | float | 综合满意度 | 72.5 |
| latest_rating | String | 最近评级 | "B" |
| game_state_snapshot | Dictionary | 完整游戏状态快照 | {见下方结构} |

**game_state_snapshot 结构**:
```json
{
  "time": {
    "semester_number": 2,
    "current_week": 5,
    "current_day": 3,
    "current_period": 2
  },
  "budget": {
    "balance": 125000.0,
    "semester_allocated": 500000.0,
    "semester_spent": 180000.0
  },
  "satisfaction": {
    "overall": 72.5,
    "cafeteria": 70.0,
    "dormitory": 80.0,
    "teaching": 68.0,
    "entertainment": 65.0
  },
  "reputation": 75.0,
  "students": [/* Student 数组序列化 */],
  "cafeterias": [/* Cafeteria 数组序列化 */],
  "dormitory_groups": [/* DormitoryGroup 数组序列化 */],
  "events_triggered": [/* 已触发事件ID列表 */],
  "save_version": "1.0"
}
```

### 11. DifficultyPreset（难度预设）

| 字段 | 类型 | 说明 | 示例 |
| ---- | ---- | ---- | ---- |
| id | String | 难度ID | "normal" |
| initial_budget | float | 初始预算 | 500000.0 |
| wallet_replenish_base | float | 新学期钱包重置基础金额 | 1500.0 |
| wallet_replenish_variance | float | 钱包重置随机波动比例 | 0.2 |
| student_tolerance | float | 学生宽容度系数（影响满意度下降速度） | 1.0 |
| event_frequency | float | 事件频率倍率 | 1.0 |
| performance_coefficient | float | 绩效系数（影响预算变化率） | 1.0 |
| utility_abandon_threshold | float | 效用放弃阈值（归一化后0-1） | 0.3 |

**难度参数影响说明**:
- `student_tolerance`: 满意度下降时的衰减系数，tolerance=0.8 时满意度下降幅度 ×0.8
- `performance_coefficient`: 预算变化率的乘数，系数=1.2 时预算增长快 20%
- `wallet_replenish_base`: 新学期学生钱包重置的基础金额（简单2000、普通1500、困难1000）
- `wallet_replenish_variance`: 随机波动比例（0.2 表示 ±20%）

## 实体关系图

```
Semester 1──* Student
               │
               │ N:1
               ▼
DormitoryGroup 1──* DormitoryBuilding
       │
       │ (参数影响)
       ▼
  SatisfactionManager ◄── CafeteriaSystem
       │                         │
       │ (加权计算)              │ 1──* WindowSlot
       ▼                         │
  OverallSatisfaction            ▼
                              Dish (菜品库)
```
