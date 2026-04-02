# Quickstart: 校园后勤管理模拟游戏 MVP 开发指南

**Feature Branch**: `001-mvp-core-systems`
**Date**: 2026-04-01

## 环境准备

### 1. 安装 Godot 4

从 https://godotengine.org/download/windows/ 下载最新 Godot 4.x LTS 标准版（非 .NET 版），解压到本地文件夹，双击 `godot.exe` 启动。

### 2. 克隆项目

```bash
git clone <仓库地址> game
cd game
git checkout 001-mvp-core-systems
```

### 3. 在 Godot 中打开项目

1. 启动 Godot 4
2. 点击"导入"（Import）
3. 选择项目根目录下的 `project.godot` 文件
4. 点击"导入并编辑"

### 4. 验证项目结构

项目打开后，左侧 FileSystem 面板应显示以下目录：
- `scenes/` — 场景文件
- `scripts/` — GDScript 脚本
- `data/` — JSON 配置数据
- `assets/` — 美术资源

## 核心概念

### 项目架构

```
Autoload 单例（全局服务）     场景（可视化）
┌──────────────────┐        ┌──────────────────┐
│ game_events.gd   │◄──────►│ campus_map.tscn  │
│ time_manager.gd  │        │ (地图+学生移动)  │
│ economy_manager  │        └──────────────────┘
│ satisfaction_mgr │
│ event_manager    │        ┌──────────────────┐
│ save_manager     │◄──────►│ hud.tscn         │
│ game_config.gd   │        │ (侧边栏+仪表盘)  │
└──────────────────┘        └──────────────────┘
```

### 数据驱动原则

所有可调参数在 `data/` 目录的 JSON 文件中。修改 JSON 即可调整游戏平衡，无需改代码：
- `data/balance/game_params.json` — 效用权重、满意度阈值等
- `data/dishes/dish_database.json` — 菜品数据
- `data/buildings/campus_layout.json` — 校园布局

### 信号总线通信

子系统之间通过 `GameEvents` 单例的 signal 通信，不直接调用其他子系统的方法：
```
# 发送方
GameEvents.satisfaction_changed.emit("cafeteria", new_value)

# 接收方
GameEvents.satisfaction_changed.connect(_on_satisfaction_changed)
```

## 开发流程

### 运行游戏

在 Godot 编辑器中按 **F5**（或点击右上角播放按钮）运行主场景。

### 调试技巧

- **实时参数调整**: 修改 `data/` 下的 JSON 文件后，重新运行游戏即可生效
- **学生行为观察**: 在 HUD 中打开详细仪表盘，查看学生选择分布
- **时间加速**: 点击 HUD 右上角的速度按钮（⏸ ▶ ⏩ ⏩⏩）控制游戏速度

### 添加新菜品

在 `data/dishes/dish_database.json` 中添加条目：
```json
{
  "id": "mapo_tofu",
  "name": "麻婆豆腐",
  "category": "vegetable",
  "taste_tag": "spicy",
  "base_cost": 3.0,
  "quality_level": 3,
  "quality_score": 65.0,
  "available_for": ["yinxing_yinhua", "sixue_furong", "chunhui_zijing"],
  "is_halal": false
}
```

### 添加新事件

在 `data/events/event_definitions.json` 中添加条目：
```json
{
  "event_id": "power_outage_dorm",
  "event_type": "breakdown",
  "name": "宿舍停电",
  "description": "硕丰苑三组团突发停电，学生怨声载道",
  "trigger_conditions": {"min_day": 10, "probability": 0.15},
  "effects": [{"target": "satisfaction_dormitory", "change": -8}],
  "choices": [
    {"text": "紧急抢修（花费5000元）", "cost": 5000, "satisfaction_recovery": 8},
    {"text": "等待明天自然恢复", "cost": 0, "satisfaction_recovery": -5}
  ]
}
```

## 文件约定

| 约定 | 说明 |
| ---- | ---- |
| 文件命名 | GDScript: snake_case.gd, 场景: snake_case.tscn, 数据: snake_case.json |
| 脚本编码 | UTF-8 |
| 代码注释 | 中文 |
| 缩进 | Tab（Godot GDScript 标准） |
| 静态分析 | 提交前运行 `gdformat` 格式化 |

## 常见问题

**Q: 修改了 JSON 文件但游戏没变化？**
A: 重新运行游戏（F5）。JSON 在游戏启动时加载，运行时修改不会自动刷新。

**Q: 学生不动？**
A: 检查 TimeManager 是否运行（未被暂停），以及 NavigationRegion2D 是否正确配置了可行走区域。

**Q: 满意度一直降？**
A: 检查食堂窗口是否配置了菜品，以及菜品价格是否合理。打开数据仪表盘查看满意度各维度的明细。
