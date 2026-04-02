# System Contracts: 校园后勤管理模拟游戏 MVP

**Feature Branch**: `001-mvp-core-systems`
**Date**: 2026-04-01

## 1. GameEvents 信号总线接口

`game_events.gd` 作为 Autoload 单例，定义所有跨子系统通信的信号。

### 时间信号

| 信号名 | 参数 | 触发时机 | 订阅者 |
| ---- | ---- | ---- | ---- |
| time_speed_changed | speed: int | 玩家切换速度档 | StudentAI, CampusMap |
| time_period_changed | period: int, day: int, day_of_week: int | 时段变更 | StudentAI, CafeteriaSystem, 所有建筑 |
| day_started | day: int, day_of_week: int | 新的一天开始 | EconomyManager, EventManager |
| week_started | week: int | 新的一周开始 | CafeteriaSystem (菜单轮换提示), EventManager |
| semester_started | semester: int | 新学期开始 | EvaluationSystem, EconomyManager (预算) |
| semester_ended | semester: int, rating: String | 学期结束 | UI (显示评级报告) |

### 满意度信号

| 信号名 | 参数 | 触发时机 | 订阅者 |
| ---- | ---- | ---- | ---- |
| satisfaction_category_changed | category: String, value: float | 某维度满意度变化 | SatisfactionManager |
| satisfaction_overall_changed | value: float | 综合满意度变化 | UI (仪表盘更新) |
| satisfaction_below_threshold | value: float | 综合满意度 < 60 | UI (预警), 或触发游戏结束 |

### 经济信号

| 信号名 | 参数 | 触发时机 | 订阅者 |
| ---- | ---- | ---- | ---- |
| budget_balance_changed | balance: float, delta: float | 预算余额变化 | UI (仪表盘) |
| daily_revenue_updated | restaurant_id: String, revenue: float | 餐厅每日营收更新 | UI (食堂详情) |

### 事件信号

| 信号名 | 参数 | 触发时机 | 订阅者 |
| ---- | ---- | ---- | ---- |
| event_triggered | event: GameEvent | 随机/周期事件触发 | UI (弹窗), 相关系统 |
| event_resolved | event_id: String, choice_index: int | 玩家做出决策 | 相关系统 (执行效果) |

### 建筑交互信号

| 信号名 | 参数 | 触发时机 | 订阅者 |
| ---- | ---- | ---- | ---- |
| building_clicked | building_id: String, building_type: String | 玩家点击建筑 | UI (打开配置面板) |
| building_config_changed | building_id: String | 建筑配置修改 | SatisfactionManager, EconomyManager |
| upgrade_started | building_id: String, duration_days: int | 升级开始 | BuildingController (标记施工) |
| upgrade_completed | building_id: String | 升级完成 | BuildingController (恢复服务) |

## 2. 子系统接口契约

### TimeManager → 所有子系统

**提供**:
- `current_period: int` (0-6, 只读)
- `current_day: int` (1-7, 只读)
- `current_week: int` (1-18, 只读)
- `current_semester: int` (只读)
- `set_speed(speed: int)` (0=暂停, 1=正常, 2=快进, 3=极速)
- `is_weekend() -> bool`

**契约**: TimeManager 不会调用其他子系统的任何方法，仅通过信号广播时间变更。

### CafeteriaSystem → SatisfactionManager, EconomyManager

**提供**:
- `get_restaurant(restaurant_id: String) -> Cafeteria`
- `get_window_utility(window: WindowSlot, student: Student) -> float`
- `add_student_to_queue(window_id: String, student_id: int)`
- `remove_student_from_queue(window_id: String, student_id: int)`
- `update_dish(window_id: String, dish_id: String)`
- `update_price(window_id: String, price: float)`
- `set_markup_rate(restaurant_id: String, rate: float)`

**契约**: CafeteriaSystem 不直接修改满意度数值，而是通过 GameEvents.satisfaction_category_changed 通知 SatisfactionManager。

### DormitorySystem → SatisfactionManager, EconomyManager

**提供**:
- `get_group(group_id: int) -> DormitoryGroup`
- `update_hot_water(group_id: int, start_period: int, end_period: int)`
- `update_electricity_price(group_id: int, price: float)`
- `update_maintenance(group_id: int, level: int)`
- `update_cleanliness(group_id: int, level: int)`
- `update_curfew(group_id: int, period: int)`
- `calculate_group_cost(group_id: int) -> Dictionary`

**契约**: 同上，通过信号通知其他系统。

### StudentAI → TimeManager, GameEvents

**提供**:
- `evaluate_schedule(student: Student)`
- `choose_cafeteria_window(student: Student) -> WindowSlot`
- `move_to_building(student: Student, building_id: String)`

**契约**: StudentAI 读取 GameConfig 中的效用权重参数，通过 NavigationAgent2D 寻路。通过信号通知 CafeteriaSystem 排队变化。

## 3. JSON 数据文件契约

### 数据文件加载规范

- 所有 JSON 文件使用 UTF-8 编码
- 由 `game_config.gd` 在游戏启动时统一加载
- 运行时不修改 JSON 文件（只读）
- 存档数据写入独立目录 `user://saves/`

### 数据文件清单

| 文件路径 | 内容 | 加载时机 |
| -------- | ---- | -------- |
| data/balance/game_params.json | 效用权重、满意度权重、难度系数 | 游戏启动 |
| data/balance/time_config.json | 时段时长、速度倍率 | 游戏启动 |
| data/balance/semester_config.json | 学期周数、评级标准 | 游戏启动 |
| data/buildings/campus_layout.json | 建筑位置、大小、类型 | 游戏启动 |
| data/buildings/dormitory_groups.json | 8个组团定义 | 游戏启动 |
| data/buildings/building_types.json | 建筑类型模板 | 游戏启动 |
| data/cafeterias/restaurant_defs.json | 9个餐厅定义 | 游戏启动 |
| data/cafeterias/window_templates.json | 窗口升级模板 | 游戏启动 |
| data/dishes/dish_database.json | 菜品数据库 | 游戏启动 |
| data/events/event_definitions.json | 事件模板 | 游戏启动 |
| data/difficulty/difficulty_presets.json | 难度预设 | 游戏启动 |
| data/students/generation_config.json | 学生生成配置 | 新游戏时 |
| data/upgrades/upgrade_definitions.json | 升级定义 | 游戏启动 |
