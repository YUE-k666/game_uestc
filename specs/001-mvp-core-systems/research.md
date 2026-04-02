# Research: 校园后勤管理模拟游戏 MVP 核心玩法

**Feature Branch**: `001-mvp-core-systems`
**Date**: 2026-04-01

## 1. Godot 4 场景树架构与性能优化

### 决策：使用 Node2D + 对象池管理大量学生实体

**方案**: 学生精灵使用 `Sprite2D` 或 `AnimatedSprite2D`，通过对象池（预创建/回收）管理而非每帧动态实例化/销毁。500-1000 个学生精灵在 Godot 4 中使用 Node2D 性能足够（Godot 4 的 2D 渲染器基于 Vulkan/Skia，可轻松处理数千个 2D 节点）。

**替代方案**:
- 使用 `MultiMeshInstance2D` 批量渲染 → 更高性能但单个学生无法独立交互/点击，不适合本游戏
- 使用 `CharacterBody2D` → 物理体开销大，学生不需要碰撞物理，过于重量级

**结论**: 使用 `Sprite2D` + 对象池 + `NavigationAgent2D`（仅寻路，非物理碰撞）。学生不使用物理引擎，移动通过直接设置 position 实现。

## 2. 寻路方案

### 决策：Godot 内置 NavigationRegion2D + NavigationAgent2D

**方案**: 使用 Godot 4 内置的 `NavigationRegion2D` 定义可行走区域（道路/广场），`NavigationAgent2D` 为每个学生提供 A* 寻路。地图为固定布局，寻路网格只需初始化一次。

**替代方案**:
- 手写 A* 算法 → 不必要，Godot 内置方案性能足够且维护成本低
- 简单直线移动 → 学生会穿墙，不可接受

**注意**: `NavigationAgent2D` 在大量 Agent 时有性能开销。优化策略：仅当学生处于"移动中"状态时激活 Agent，静止时禁用。

## 3. 瓦片地图方案

### 决策：TileMapLayer + 自定义瓦片集

**方案**: 使用 Godot 4 的 `TileMapLayer`（替代旧版 TileMap）绘制校园地面（草地、道路、广场）。建筑使用独立 `Sprite2D` 或 `StaticBody2D` 放置在瓦片地图上方，方便独立交互。

**替代方案**:
- 所有内容都在 TileMap 中 → 建筑无法独立作为交互节点，限制太大
- 纯代码生成地图 → 不可视化编辑，开发效率低

**结论**: 地面层用 TileMapLayer，建筑层用独立节点。

## 4. UI 框架方案

### 决策：Godot 内置 Control 节点系统

**方案**: 使用 Godot 4 内置的 `Control` 节点体系（VBoxContainer, HBoxContainer, Panel, Label, Slider, Button 等）构建所有 UI。侧边栏使用 `PanelContainer` + 可折叠 `Panel`。

**替代方案**:
- Godot 社区 UI 框架（如 Silk, Godot UI Builder） → 增加依赖，违反宪章原则
- 外部 UI 库 → 同上

**结论**: 纯内置 Control 节点，符合宪章"UI 框架：使用 Godot 内置的 Control 节点"的约束。

## 5. 数据文件格式

### 决策：JSON 作为主要数据格式

**方案**: 所有可调参数使用 JSON 文件存储，通过 `JSON.parse_string()` 加载。菜品数据库、建筑定义、事件模板等使用独立 JSON 文件。

**替代方案**:
- Godot `.tres`/`.tscn` Resource 文件 → 适合引擎内置类型，但数据驱动原则要求非程序员可编辑（JSON 更通用）
- CSV → 适合表格数据但不支持嵌套结构

**结论**: JSON 格式，运行时通过 `game_config.gd` 自动加载单例统一管理。

## 6. 存档系统方案

### 决策：JSON 序列化 + FileAccess

**方案**: 将整个游戏状态序列化为单个 JSON 文件。Godot 4 的 `JSON.stringify()` 可处理字典和数组。存档路径使用 `OS.get_user_data_dir()` 获取系统标准存档目录。

**存档结构**:
```json
{
  "metadata": {"version": "1.0", "difficulty": "normal", "timestamp": "..."},
  "time": {"day": 15, "week": 3, "semester": 1, "period": 2},
  "budget": {"balance": 50000, "total_income": 120000, "total_expense": 70000},
  "satisfaction": {"overall": 75.5, "cafeteria": 72.0, "dormitory": 80.0, "teaching": 75.0, "entertainment": 73.0},
  "reputation": 65,
  "cafeterias": [...],
  "dormitory_groups": [...],
  "students": [...],
  "events_triggered": [...]
}
```

## 7. 事件系统架构

### 决策：基于 Autoload 的全局信号总线

**方案**: 创建 `game_events.gd` 作为 Autoload 单例，使用 Godot 的 `signal` 机制作为事件总线。各子系统 emit 信号，其他系统 connect 响应。

**优势**:
- 符合宪章原则 V（模块化解耦）
- Godot signal 是类型安全的
- 无需第三方库

**信号定义示例**:
```
signal time_period_changed(new_period: int)
signal day_started(day: int, day_of_week: int)
signal week_started(week: int)
signal semester_started(semester: int)
signal satisfaction_changed(category: String, value: float)
signal satisfaction_below_threshold(value: float)
signal budget_changed(balance: float, delta: float)
signal event_triggered(event: GameEvent)
signal building_clicked(building: Building)
signal window_config_changed(restaurant_id: String, window_id: String)
signal dormitory_config_changed(group_id: String)
```

## 8. 满意度计算细节

### 决策：加权平均 + 累积移动平均

**方案**:
- 综合满意度 = 食堂满意度×30% + 宿舍满意度×30% + 教学环境×20% + 文娱×20%
- 各维度满意度 = 所有学生该维度满意度的算术平均值
- 教学环境和文娱维度在 MVP 中为固定基准值（受随机事件影响可临时变化）
- 每日汇总一次，而非实时计算（性能优化）

## 9. 学生生成策略

### 决策：基于配置的概率分布生成

**方案**: 游戏开始时根据 `generation_config.json` 批量生成学生。配置文件定义：
- 总人数（按难度调整）
- 口味分布（辣/清淡/甜/咸 各占比例）
- 性格分布（吃货/学霸/抠门/运动健将 各占比例）
- 钱包范围（本科/研究生 分别定义）

每个学生使用伪随机数生成器确保可复现。

## 10. 排队模拟算法

### 决策：简单 FIFO 队列 + 服务时间模型

**方案**: 每个窗口维护一个学生队列数组。服务时间 = 基础时间 / (1 + 厨师技能等级×系数)。每个游戏 tick（时段推进），队列头的学生的等待时间递减，减至0时完成就餐离开。

**替代方案**:
- 完整排队论模型（M/M/c） → 过于学术化，玩家感知不到区别
- 无排队（瞬时服务） → 失去排队这一策略维度

**结论**: FIFO + 线性服务时间模型，简单有效。
