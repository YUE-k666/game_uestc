# Implementation Plan: 校园后勤管理模拟游戏 MVP 核心玩法

**Branch**: `001-mvp-core-systems` | **Date**: 2026-04-01 | **Spec**: [spec.md](spec.md)
**Input**: Feature specification from `/specs/001-mvp-core-systems/spec.md`

## Summary

为《重生之我在电子科大干后勤》开发基于 Godot 4 + GDScript 的 2D 像素风校园后勤管理模拟游戏 MVP。核心玩法包括：写实还原清水河校区的校园地图（学生实时移动）、9个真实餐厅的食堂管理系统（窗口级菜品/价格配置+排队模拟）、8个组团的宿舍管理系统（参数滑块+本硕区分）、以及满意度-经济双轴博弈的数值系统（加权满意度、多因素效用模型、学期评级循环）。所有游戏参数数据驱动（JSON），子系统模块化（信号总线通信）。

## Technical Context

**Language/Version**: GDScript (Godot 4.x LTS)
**Primary Dependencies**: Godot 4.x LTS 引擎, GUT (Godot Unit Testing) 测试框架
**Storage**: JSON 文件（游戏配置数据）+ JSON 文件（存档），Godot Resource 文件（瓦片集/精灵图等资源）
**Testing**: GUT (Godot Unit Testing) — 用于数值模型和核心逻辑的单元测试
**Target Platform**: 桌面端（Linux, Windows, macOS）
**Project Type**: Desktop game application (2D simulation/strategy)
**Performance Goals**: 500+ 移动实体同时运行时帧率不低于 30fps
**Constraints**: 单机离线运行，存档序列化为单个 JSON 文件，所有游戏参数外部化（无魔法数字）
**Scale/Scope**: ~50 个场景/脚本文件，~20 个 JSON 数据文件，9 个食堂×多窗口、8 个宿舍组团、500-1000 个学生实体

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

| 原则 | 状态 | 说明 |
| ---- | ---- | ---- |
| I. GDScript 优先 | ✅ 通过 | 全部逻辑使用 GDScript，无 C++/GDExtension |
| II. 像素风视觉标准 | ✅ 通过 | 统一 48×48 瓦片尺寸，开源素材或自制 |
| III. MVP 范围锁定 | ✅ 通过 | 仅校园地图 + 食堂 + 宿舍，特殊建筑（快递站/体育场馆/校医院）标记为后续扩展 |
| IV. 满意度-经济双轴 | ✅ 通过 | 加权满意度模型 + 预算绩效挂钩，不存在双赢策略 |
| V. 模块化架构 | ✅ 通过 | 各子系统通过 GameEvents 信号总线通信，无直接内部状态访问 |
| VI. 数据驱动配置 | ✅ 通过 | 所有可调参数存储在 JSON 文件中，运行时读取 |

**宪章偏差说明**：宪章"游戏设计约束"中写有"MVP 不采用实时模拟"，但 spec 澄清阶段明确选择了"实时推进，四档速度控制"和"学生实时移动"。本计划遵循 spec 澄清结果，因为 spec 是经过用户确认的最新需求表达。建议宪章更新此条以保持一致。

**Post-Phase 1 Re-check**: 待 Phase 1 设计完成后重新验证。

## Project Structure

### Documentation (this feature)

```text
specs/001-mvp-core-systems/
├── plan.md              # 本文件
├── research.md          # Phase 0 技术研究
├── data-model.md        # Phase 1 数据模型
├── quickstart.md        # Phase 1 快速上手指南
├── contracts/           # Phase 1 系统接口契约
└── tasks.md             # Phase 2 任务拆解（/speckit.tasks 生成）
```

### Source Code (Godot 4 Project)

```text
project.godot                        # Godot 项目配置文件
docs/
└── game-design.md                   # 游戏设计文档

# ---- 场景 ----
scenes/
├── main.tscn                        # 主场景入口
├── campus_map.tscn                  # 校园地图场景
├── buildings/
│   ├── cafeteria.tscn               # 食堂建筑场景（可复用9次）
│   ├── dormitory.tscn               # 宿舍楼场景（可复用28次）
│   ├── teaching_building.tscn       # 教学楼场景（不可交互背景建筑）
│   └── library.tscn                 # 图书馆场景（不可交互背景建筑）
├── ui/
│   ├── hud.tscn                     # 主界面 HUD（地图+侧边栏+控制栏）
│   ├── building_panel.tscn          # 建筑配置面板
│   ├── cafeteria_panel.tscn         # 食堂详细配置面板
│   ├── dormitory_panel.tscn         # 宿舍详细配置面板
│   ├── dashboard.tscn               # 数据仪表盘
│   ├── event_dialog.tscn            # 事件决策对话框
│   ├── semester_report.tscn         # 学期评级报告
│   └── game_over.tscn               # 游戏结束画面
└── menu/
    ├── main_menu.tscn               # 主菜单（新游戏/读档/设置）
    ├── difficulty_select.tscn       # 难度选择
    └── save_load.tscn               # 存档/读档界面

# ---- 脚本 ----
scripts/
├── autoload/                        # 自动加载单例
│   ├── game_events.gd               # 全局信号总线（子系统通信）
│   ├── time_manager.gd              # 时间系统（时段/日/周/学期/速度）
│   ├── economy_manager.gd           # 经济系统（收入/支出/预算）
│   ├── satisfaction_manager.gd      # 满意度系统（加权计算/预警）
│   ├── reputation_manager.gd        # 声望系统
│   ├── event_manager.gd             # 随机事件系统
│   ├── save_manager.gd              # 存档/读档系统
│   └── game_config.gd               # 游戏配置加载器（读取JSON）
├── core/                            # 核心游戏对象（Resource 子类）
│   ├── student.gd                   # 学生 Resource（属性定义）
│   ├── student_ai.gd                # 学生 AI 行为决策
│   ├── dish.gd                      # 菜品 Resource
│   ├── window_slot.gd               # 食堂窗口 Resource
│   ├── building.gd                  # 建筑 Resource（基类）
│   ├── cafeteria.gd                 # 食堂 Resource（Building 子类）
│   ├── dormitory.gd                 # 宿舍楼 Resource（Building 子类）
│   ├── dormitory_group.gd           # 宿舍组团 Resource
│   ├── staff.gd                     # 员工 Resource
│   ├── game_event.gd                # 事件 Resource
│   └── semester.gd                  # 学期 Resource
├── systems/                         # 子系统逻辑
│   ├── cafeteria_system.gd          # 食堂运营逻辑（排队/营收/成本）
│   ├── dormitory_system.gd          # 宿舍运营逻辑（参数→成本→满意度）
│   ├── student_manager.gd           # 学生生成/管理/批量更新
│   ├── upgrade_system.gd            # 升级逻辑
│   └── evaluation_system.gd         # 学期评级逻辑
├── map/                             # 地图相关
│   ├── campus_map_controller.gd     # 地图控制器（建筑实例化/学生渲染）
│   ├── student_renderer.gd          # 学生精灵管理（实例化/池化）
│   ├── building_controller.gd       # 建筑交互（点击/高亮）
│   └── pathfinding_helper.gd        # 寻路辅助
└── ui/                              # UI 逻辑
    ├── hud_controller.gd            # HUD 主控制器
    ├── time_controls.gd             # 速度控制按钮
    ├── building_panel_controller.gd # 建筑面板逻辑
    ├── dashboard_controller.gd      # 仪表盘数据绑定
    ├── event_log.gd                 # 事件日志滚播
    └── tutorial_system.gd           # 按需提示系统

# ---- 数据文件 ----
data/
├── balance/
│   ├── game_params.json             # 全局参数（效用权重、满意度权重、阈值等）
│   ├── time_config.json             # 时间配置（时段时长、速度倍率等）
│   └── semester_config.json         # 学期配置（周数、评级标准等）
├── buildings/
│   ├── campus_layout.json           # 校园布局（建筑位置、大小、类型）
│   ├── dormitory_groups.json        # 8个组团定义（楼栋列表、等级、默认参数）
│   └── building_types.json          # 建筑类型定义（开放时间模板等）
├── cafeterias/
│   ├── restaurant_defs.json         # 9个餐厅定义（名称、位置、窗口数、菜单范围）
│   └── window_templates.json        # 窗口模板（升级等级属性表）
├── dishes/
│   └── dish_database.json           # 菜品数据库（30-50道菜：成本、质量、口味）
├── events/
│   └── event_definitions.json       # 事件定义（类型、触发条件、效果、选项）
├── difficulty/
│   └── difficulty_presets.json      # 三档难度参数
├── students/
│   └── generation_config.json       # 学生生成配置（数量分布、钱包范围、口味分布）
└── upgrades/
    └── upgrade_definitions.json     # 升级定义（等级、成本、周期、属性提升）

# ---- 资源文件 ----
assets/
├── sprites/
│   ├── buildings/                   # 建筑精灵（48×48 或更大）
│   ├── students/                    # 学生行走精灵图
│   └── ui/                          # UI 图标/元素
├── tiles/
│   ├── campus_tileset.tres          # 校园瓦片集
│   └── campus_tilemap.tscn          # 校园瓦片地图
├── fonts/
│   └── default_font.tres            # 默认字体
└── audio/                           # 音效（后续添加）
```

**Structure Decision**: 采用 Godot 4 标准 MVC 变体架构。`scripts/core/` 定义数据 Resource（Model），`scripts/systems/` + `scripts/autoload/` 包含业务逻辑（Controller），`scenes/` + `scripts/ui/` 负责渲染和交互（View）。自动加载单例作为全局服务层，子系统通过 `GameEvents` 信号总线解耦通信。

## Architecture Overview

### 场景树结构

```
Main (Node)
├── CampusMap (Node2D)               # 校园地图
│   ├── TileMapLayer                 # 瓦片地面层
│   ├── Buildings (Node2D)           # 建筑容器
│   │   ├── [Cafeteria instances]    # 9个餐厅实例
│   │   ├── [Dormitory instances]    # 28栋宿舍实例
│   │   └── [Background instances]   # 教学楼/图书馆等
│   ├── Students (Node2D)            # 学生精灵容器
│   └── NavigationRegion2D           # A* 寻路区域
├── UI (CanvasLayer)
│   ├── HUD                          # 主界面框架
│   │   ├── TimeControls             # 速度控制栏
│   │   ├── MiniDashboard            # 顶部迷你仪表盘
│   │   └── SidePanel                # 可折叠侧边栏
│   │       ├── DashboardTab         # 详细数据面板
│   │       └── EventLogTab          # 事件日志
│   ├── BuildingPanel                # 建筑配置弹窗（动态切换食堂/宿舍面板）
│   ├── EventDialog                  # 事件决策弹窗
│   ├── SemesterReport               # 学期评级弹窗
│   └── GameOver                     # 游戏结束画面
└── Managers (通过 Autoload 注入，不在场景树中)
```

### 子系统通信架构（事件总线）

```
┌──────────────┐    signal     ┌──────────────┐
│ TimeManager  │─────────────→│ 所有子系统    │
│ (time_period │  _changed()   │ CampusMap    │
│  _changed)   │              │ StudentAI    │
└──────────────┘              │ CafeteriaSys │
                              └──────────────┘

┌──────────────┐    signal     ┌──────────────┐
│StudentAI    │─────────────→│CafeteriaSys  │
│ (window_     │  _chosen()    │(add_to_queue │
│  selected)   │              │ _remove())   │
└──────────────┘              └──────────────┘

┌──────────────┐    signal     ┌──────────────┐
│任何满意度    │─────────────→│Satisfaction  │
│相关系统      │  _changed()   │Manager      │
│              │              │(recalculate) │
└──────────────┘              └──────┬───────┘
                                     │ signal
                                     │ _below_threshold
                              ┌──────▼───────┐
                              │ UIManager    │
                              │(show warning)│
                              └──────────────┘
```

### 学生 AI 决策流程

```
时段变更触发 → TimeManager.period_changed(period)
  → StudentAI.evaluate_schedule(student, period)
    → 根据时段决定目标建筑（食堂/教学楼/宿舍）
    → 如果是就餐时段：
      → 遍历所有开放餐厅窗口
      → 对每个窗口计算效用值（从 game_params.json 读取权重）
      → 效用值 = w1×口味匹配 + w2×(1/价格) + w3×(1/距离) + w4×(1/排队) + w5×质量
      → 选效用最高的窗口（学生有概率选择次优，增加自然感）
      → 如果最高效用 < 阈值 → 放弃就餐，满意度 -X
    → 启动寻路移动到目标建筑
```

## Complexity Tracking

| 偏差 | 原因 | 被拒的简单替代方案 |
| ---- | ---- | ----------------- |
| 9个独立食堂场景（而非3个合并） | 用户要求完全写实还原清水河校区9个餐厅 | 合并为3个区域会丢失真实感和策略深度 |
| 个体学生模拟（500-1000个） | 核心玩法要求学生个体可见且有属性 | 纯统计数据模型无法支持地图实时移动和个体效用计算 |
| 信号总线通信模式 | 宪章原则V要求子系统解耦 | 直接函数调用更简单但违反模块化原则，后续扩展困难 |
