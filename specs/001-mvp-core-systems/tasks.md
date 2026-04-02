# Tasks: 校园后勤管理模拟游戏 MVP 核心玩法

**Input**: Design documents from `/specs/001-mvp-core-systems/`
**Prerequisites**: plan.md (required), spec.md (required), research.md, data-model.md, contracts/

**Organization**: Tasks are grouped by user story to enable independent implementation and testing of each story.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependencies)
- **[Story]**: Which user story this task belongs to (e.g., US1, US2, US3)
- Include exact file paths in descriptions

## Path Conventions

Godot 4 项目结构，所有路径相对于项目根目录：
- `project.godot` — Godot 项目文件
- `scenes/` — .tscn 场景文件
- `scripts/` — GDScript 脚本
- `data/` — JSON 配置数据
- `assets/` — 美术资源

---

## Phase 1: 项目初始化

**Purpose**: 创建 Godot 4 项目，搭建目录结构，配置基础文件

- [ ] T001 创建 Godot 4 项目文件 project.godot（窗口标题"重生之我在电子科大干后勤"，分辨率 1280×720，像素风渲染设置）
- [ ] T002 创建目录结构：scenes/、scripts/autoload/、scripts/core/、scripts/systems/、scripts/map/、scripts/ui/、data/、assets/（含子目录）
- [ ] T003 [P] 创建 data/balance/game_params.json（效用权重 w1-w5、满意度权重、放弃阈值、效用归一化参数 max_price/max_distance/queue_max、等待惩罚系数 wait_penalty_coefficient、米饭成本 rice_cost_per_meal 等全局参数）
- [ ] T004 [P] 创建 data/balance/time_config.json（7个时段定义、时长、速度倍率 0/1/2/4）
- [ ] T005 [P] 创建 data/balance/semester_config.json（18周结构、评级阈值矩阵：S/A/B/C/F 双指标独立门槛——满意度和利润达成率各自最低阈值，基准预算、满意度贡献系数、声望贡献系数）
- [ ] T006 [P] 创建 data/difficulty/difficulty_presets.json（简单/普通/困难三档：初始预算、钱包重置基础金额 wallet_replenish_base、钱包重置波动 variance、宽容度 student_tolerance、事件频率、绩效系数 performance_coefficient）
- [ ] T007 [P] 创建 data/students/generation_config.json（学生数量、口味分布、性格分布、钱包范围、本硕比例）

---

## Phase 2: 核心基础设施（阻塞所有用户故事）

**Purpose**: 信号总线、配置加载器、时间系统等所有子系统依赖的基础服务

**⚠️ CRITICAL**: 以下任务必须在任何用户故事之前完成

- [ ] T008 实现 scripts/autoload/game_events.gd — 全局信号总线单例，定义所有跨子系统信号（时间、满意度、经济、建筑交互、事件等，详见 contracts/game_events_interface.md）
- [ ] T009 实现 scripts/autoload/game_config.gd — 游戏配置加载器单例，启动时加载所有 data/*.json 文件并提供访问接口
- [ ] T010 实现 scripts/autoload/time_manager.gd — 时间系统单例，管理 7个时段循环、日/周/学期推进、四档速度控制（暂停/正常/快进/极速）、周末判断
- [ ] T011 实现 scripts/core/student.gd — 学生 Resource 类，包含所有属性（id、name、student_type、wallet_balance、taste_preference、personality_tag、satisfaction、position、state（idle/moving/queuing_cafeteria/queuing_facility/eating/studying/sleeping/returning_late/exercising）、meals_today、curfew_violated 等）
- [ ] T012 实现 scripts/core/building.gd — 建筑 Resource 基类，包含 id、name、type、grid_position、grid_size、open_periods、upgrade_level 等属性
- [ ] T013 实现场景 scenes/main.tscn — 主场景入口，包含 CampusMap、UI CanvasLayer 节点，引用所有 Autoload 单例

**Checkpoint**: 基础设施就绪，用户故事实现可以开始

---

## Phase 3: User Story 1 — 校园地图与学生实时移动 (Priority: P1)

**Goal**: 玩家看到一个写实还原的校园俯视图，学生按时间表在地图上实时移动

**Independent Test**: 启动游戏，学生按时段自动移动，切换速度档位，地图显示清水河校区布局

### 数据文件

- [ ] T014 [P] [US1] 创建 data/buildings/campus_layout.json — 清水河校区所有建筑的位置、大小、类型（硕丰苑28栋、9个餐厅、品学楼ABC、立人楼、图书馆、学生活动中心、商业街等）
- [ ] T015 [P] [US1] 创建 data/buildings/building_types.json — 建筑类型模板定义（开放时段、可交互性等）

### 核心对象

- [ ] T016 [P] [US1] 实现 scripts/core/cafeteria.gd — 食堂 Resource（Building 子类），包含 restaurant_id、restaurant_name、area、floors（楼层数组，如[1]或[1,2]）、menu_scope、windows 数组、revenue 等属性
- [ ] T017 [P] [US1] 实现 scripts/core/dormitory.gd — 宿舍楼 Resource（Building 子类），包含 group_id、has_ac、has_private_bath、capacity、base_satisfaction_bonus 等属性
- [ ] T018 [P] [US1] 实现 scripts/core/dormitory_group.gd — 宿舍组团 Resource，包含 group_id、student_type、buildings 列表、热水/电费/维修/清洁/门禁参数

### 地图与移动

- [ ] T019 [US1] 实现场景 scenes/campus_map.tscn — 校园地图场景，包含 TileMapLayer（草地/道路瓦片地面层）、NavigationRegion2D（可行走区域）、Buildings 容器节点、Students 容器节点
- [ ] T020 [US1] 实现 scripts/map/campus_map_controller.gd — 地图控制器，启动时根据 campus_layout.json 实例化所有建筑节点，设置 NavigationRegion2D
- [ ] T021 [US1] 实现 scripts/map/building_controller.gd — 建筑交互控制器，处理建筑点击事件（通过 input_event），发射 GameEvents.building_clicked 信号
- [ ] T022 [US1] 实现 scripts/map/pathfinding_helper.gd — 寻路辅助工具，提供从任意格子坐标到目标建筑入口的最短路径计算（基于 NavigationServer2D）
- [ ] T023 [US1] 实现 scripts/core/student_ai.gd — 学生 AI 行为决策：根据当前时段决定目标建筑（早晨→食堂，上午→教学楼，中午→食堂，下午→教学楼，傍晚→食堂，晚上→教学楼，深夜→宿舍），启动寻路移动
- [ ] T024 [US1] 实现 scripts/map/student_renderer.gd — 学生精灵管理器，使用对象池管理 Sprite2D 实例，处理学生移动动画（基于寻路路径逐帧更新 position）
- [ ] T025 [US1] 实现 scripts/systems/student_manager.gd — 学生管理器，游戏启动时根据 generation_config.json 批量生成学生（概率分布分配口味/性格/钱包），管理学生生命周期

### UI：时间控制

- [ ] T026 [US1] 实现 scripts/ui/time_controls.gd — 时间速度控制按钮（暂停/正常/快进/极速），调用 TimeManager.set_speed()
- [ ] T027 [US1] 实现场景 scenes/ui/hud.tscn — 主界面 HUD，包含顶部迷你信息栏（日期/时段/速度控制按钮）和可折叠侧边栏容器

### 占位美术资源

- [ ] T028 [P] [US1] 创建 assets/sprites/buildings/ 下所有建筑的占位精灵（48×48 彩色方块，标注建筑名称，区分食堂/宿舍/教学楼）
- [ ] T029 [P] [US1] 创建 assets/sprites/students/ 学生占位精灵（16×16 彩色小方块，4个方向行走帧）
- [ ] T030 [P] [US1] 创建 assets/tiles/ 地面瓦片集占位（草地绿色、道路灰色、广场浅灰，48×48）
- [ ] T031 [US1] 实现场景 scenes/buildings/teaching_building.tscn 和 scenes/buildings/library.tscn — 不可交互的背景建筑场景

**Checkpoint**: 校园地图可运行，500+学生按时段移动，速度控制正常

---

## Phase 4: User Story 2 — 食堂管理系统 (Priority: P2)

**Goal**: 玩家点击餐厅配置菜品/价格，观察学生排队就餐行为

**Independent Test**: 配置食堂窗口参数，观察学生选择行为，查看营收变化

### 数据文件

- [ ] T032 [P] [US2] 创建 data/cafeterias/restaurant_defs.json — 9个真实餐厅定义（银桦/紫荆/芙蓉/学子/思源/家园/西北/朝阳（1楼+2楼）/清真，含位置、楼层数、窗口数、专属菜单范围）
- [ ] T033 [P] [US2] 创建 data/dishes/dish_database.json — 菜品数据库（30-50道菜：每道含 id、name、category、taste_tag、base_cost、quality_level、quality_score、available_for、is_halal）

### 核心对象

- [ ] T034 [P] [US2] 实现 scripts/core/dish.gd — 菜品 Resource 类
- [ ] T035 [P] [US2] 实现 scripts/core/window_slot.gd — 食堂窗口 Resource 类，包含 dish_id、price、markup_rate、service_speed、staff_skill_level、queue 数组、daily_customers 等属性
- [ ] T036 [US2] 实现场景 scenes/buildings/cafeteria.tscn — 食堂建筑场景，包含多个窗口子节点，显示排队状态和当前菜品信息

### 食堂系统逻辑

- [ ] T037 [US2] 实现 scripts/systems/cafeteria_system.gd — 食堂运营系统：窗口管理、排队FIFO处理（基于时段 tick 递减等待时间，队列达到 queue_max 后新学生自动放弃）、服务速度计算（受厨师技能影响）、营收追踪（每道菜 = 售价 - 食材成本 - 米饭成本，米饭成本 rice_cost_per_meal 从 game_params.json 读取）
- [ ] T038 [US2] 在 student_ai.gd 中实现效用选择逻辑 — 遍历所有开放窗口，计算效用值（各因子归一化到 0-1 后加权求和：口味匹配(1/0)×w1 + (1-price/max_price)×w2 + (1-dist/max_dist)×w3 + (1-queue/queue_max)×w4 + quality_score/100×w5，max 值从 game_params.json 读取），选择最高效用窗口，效用<阈值则放弃就餐（满意度下降）
- [ ] T039 [US2] 实现每周菜单轮换功能 — TimeManager.week_started 信号触发时，提示玩家可更换菜品；菜品更换后记录连续周数，频繁更换（<2周）降低习惯性满意度
- [ ] T040 [US2] 实现混合定价模式 — 支持单道菜单独定价（直接设置 price）和窗口统一加成率（markup_rate，售价 = 食材成本×(1+markup_rate)）。参数修改缓存到下个时段生效（time_period_changed 时应用），给玩家"下好棋等开局"的策略感

### UI：食堂配置面板

- [ ] T041 [US2] 实现场景 scenes/ui/cafeteria_panel.tscn — 食堂配置面板，包含窗口列表、每个窗口的菜品下拉选择、价格输入、加成率输入、当前排队人数和日营收显示
- [ ] T042 [US2] 实现 scripts/ui/building_panel_controller.gd — 建筑面板控制器，根据 building_type 动态切换显示 CafeteriaPanel 或 DormitoryPanel
- [ ] T043 [US2] 在 hud.tscn 中集成 BuildingPanel 弹窗逻辑（点击食堂建筑→打开 CafeteriaPanel→修改参数→实时生效）

**Checkpoint**: 食堂系统可运行，学生根据效用模型选择窗口，排队实时显示，营收可追踪

---

## Phase 5: User Story 3 — 宿舍管理系统 (Priority: P2)

**Goal**: 玩家调整宿舍组团参数（热水/电费/维修/清洁/门禁），观察成本和满意度变化

**Independent Test**: 调整宿舍参数，验证成本和满意度指标实时变化

### 数据文件

- [ ] T044 [P] [US3] 创建 data/buildings/dormitory_groups.json — 8个组团完整定义（硕丰苑1-8组团，楼栋列表、等级差异、本科/研究生区分、默认参数值）

### 宿舍系统逻辑

- [ ] T045 [US3] 实现 scripts/systems/dormitory_system.gd — 宿舍运营系统：参数修改→成本计算（燃气费=基础值×热水时段长度×楼栋数，维修费=基础值×频率×楼栋数，保洁费=基础值×清洁等级×楼栋数），电费收入=定价×用量，满意度影响计算
- [ ] T046 [US3] 在 student_ai.gd 中实现宿舍满意度逻辑 — 学生每日根据热水可用性、门禁遵守情况、清洁等级计算住宿满意度变化；超时返回门禁（curfew_period）时记录晚归
- [ ] T047 [US3] 实现宿舍等级差异系统 — 不同楼栋有/无空调、独卫/公共卫浴影响 base_satisfaction_bonus，低等级宿舍基础满意度低于高等级

### UI：宿舍配置面板

- [ ] T048 [US3] 实现场景 scenes/buildings/dormitory.tscn — 宿舍楼建筑场景，显示楼栋等级（空调/独卫图标）和组团信息
- [ ] T049 [US3] 实现场景 scenes/ui/dormitory_panel.tscn — 宿舍配置面板，包含热水时段滑块、电费定价滑块、维修频率滑块、清洁等级滑块、门禁时间滑块，所有参数范围和步进值从 dormitory_groups.json 的 config_bounds 字段读取（JSON 配置驱动），实时显示成本预估和满意度预测
- [ ] T050 [US3] 在 building_panel_controller.gd 中集成 DormitoryPanel — 点击宿舍楼→打开 DormitoryPanel→调参→实时生效

**Checkpoint**: 宿舍系统可运行，参数调整影响成本和满意度

---

## Phase 6: User Story 4 — 数据看板 (Priority: P3)

**Goal**: 玩家通过侧边栏仪表盘监控综合满意度、营收、利润等指标

**Independent Test**: 触发各种运营状况，验证仪表盘数据准确、预警正常触发

### 仪表盘逻辑

- [ ] T051 [P] [US4] 实现 scripts/ui/dashboard_controller.gd — 仪表盘数据控制器，监听 GameEvents 信号实时更新显示数据
- [ ] T052 [P] [US4] 实现 scripts/ui/event_log.gd — 事件日志滚播，监听 GameEvents.event_triggered 和 GameEvents.event_resolved，按时间倒序显示事件列表
- [ ] T053 [US4] 实现场景 scenes/ui/dashboard.tscn — 数据仪表盘，包含综合满意度仪表（0-100刻度）、分维度满意度条（食堂/宿舍/教学/文娱）、当日营收/累计利润、学校声望、预警横幅（满意度<65黄色、<60红色）
- [ ] T054 [US4] 实现历史趋势图表 — 简单折线图（使用 Godot Line2D 或 Control 绘制），默认显示过去 7 天（按日采样），可切换到过去 4 周（按周采样），标注关键事件点
- [ ] T055 [US4] 在 hud.tscn 侧边栏中集成 DashboardTab 和 EventLogTab — 可折叠展开，默认显示迷你仪表盘（顶部一行关键数字）

**Checkpoint**: 数据看板完整可用，所有指标实时更新

---

## Phase 7: User Story 5 — 学期评级与预算循环 (Priority: P3)

**Goal**: 学期结束给出评级，预算与绩效挂钩

**Independent Test**: 加速时间完成一个学期，验证评级计算和预算变化

### 评级与预算逻辑

- [ ] T056 [P] [US5] 实现 scripts/autoload/satisfaction_manager.gd — 满意度管理器，计算加权综合满意度（食堂×30% + 宿舍×30% + 教学×20% + 文娱×20%），每日汇总，低于60分发射 satisfaction_below_threshold 信号。满意度变化公式：体验质量分 = 效用值×100 - 等待惩罚（等待时长×wait_penalty_coefficient），满意度变化 = (体验质量分-50) × 性格系数 × student_tolerance
- [ ] T057 [P] [US5] 实现 scripts/autoload/economy_manager.gd — 经济管理器，追踪收入（预算拨款 + 食堂营收 + 宿舍水电费）和支出（工资、食材、能源、维修、升级），日/周/学期结算
- [ ] T058 [P] [US5] 实现 scripts/autoload/reputation_manager.gd — 声望管理器，根据满意度趋势和事件处理结果调整声望值，声望影响新生质量分布和预算额度
- [ ] T059 [P] [US5] 实现 scripts/core/semester.gd — 学期 Resource，包含 semester_number、current_week、rating、budget_allocated 等属性
- [ ] T060 [US5] 实现 scripts/systems/evaluation_system.gd — 学期评级系统，学期结束时计算评级（S/A/B/C/F，双指标独立门槛，阈值从 semester_config.json 读取），确定下学期预算额度（新预算 = 基准预算 × (1 + 满意度贡献 + 声望贡献) × performance_coefficient）
- [ ] T061 [US5] 实现场景 scenes/ui/semester_report.tscn — 学期评级报告弹窗，显示评级、各维度满意度均值、营收/支出总结、下学期预算变化、新生质量变化
- [ ] T062 [US5] 实现场景 scenes/ui/game_over.tscn — 游戏结束画面，显示最终经营数据、最高连续学期数、总利润等
- [ ] T063 [US5] 在 TimeManager 中实现学期结束检测 — 当前周超过18周时触发学期结束流程（发射 semester_ended 信号，EvaluationSystem 计算评级，EconomyManager 结算预算）

**Checkpoint**: 完整的学期经营循环可运行

---

## Phase 8: User Story 6 — 随机事件系统 (Priority: P4)

**Goal**: 随机事件打破平衡，玩家做决策应对

**Independent Test**: 触发特定事件，验证事件效果和玩家决策机制

### 事件数据与逻辑

- [ ] T064 [P] [US6] 创建 data/events/event_definitions.json — 事件模板（卫生检查、管道漏水、停电、食材涨价、考试周、财务危机等），含触发条件、效果、玩家选项。财务危机事件：预算余额为负时触发，玩家选择"削减服务"（满意度下降）或"申请紧急拨款"（下学期预算减少）
- [ ] T065 [P] [US6] 实现 scripts/core/game_event.gd — 事件 Resource 类，包含 event_id、event_type、name、description、effects、choices 等属性
- [ ] T066 [US6] 实现 scripts/autoload/event_manager.gd — 事件管理器，根据触发条件和概率每2-4天随机触发事件，管理事件队列（防止同时过多事件）。周期性事件（如考试周）触发时发射 period_event_active 信号，StudentAI 监听信号调整学生行为（考试周期间晚上时段更多学生去图书馆/自习室而非体育馆/食堂）
- [ ] T067 [US6] 实现场景 scenes/ui/event_dialog.tscn — 事件决策对话框，显示事件描述、选项按钮（每个选项显示成本和预期效果），玩家选择后执行效果

**Checkpoint**: 随机事件系统可运行

---

## Phase 9: User Story 7 — 建筑升级系统 (Priority: P4)

**Goal**: 玩家可升级食堂窗口和宿舍组团，施工期间暂停服务

**Independent Test**: 发起升级，验证施工暂停和升级后效果

### 升级数据与逻辑

- [ ] T068 [P] [US7] 创建 data/upgrades/upgrade_definitions.json — 升级定义（食堂窗口1-5级、宿舍组团1-5级的成本、施工天数、属性提升表）
- [ ] T069 [US7] 实现 scripts/systems/upgrade_system.gd — 升级逻辑，验证资金充足→启动升级→发射 upgrade_started 信号（StudentAI 监听，所有目标为该建筑的学生重新路由）→标记施工中→清空排队队列→设施暂停服务→倒计时→升级完成→发射 upgrade_completed 信号→恢复服务并提升属性
- [ ] T070 [US7] 在 CafeteriaPanel 和 DormitoryPanel 中添加升级按钮 — 显示当前等级、升级成本、施工天数，点击发起升级

**Checkpoint**: 升级系统可运行

---

## Phase 10: 菜单系统与存档

**Purpose**: 主菜单、难度选择、存档读档、教程提示

- [ ] T071 [P] 实现场景 scenes/menu/main_menu.tscn — 主菜单（新游戏/继续游戏/退出），"新游戏"进入难度选择
- [ ] T072 [P] 实现场景 scenes/menu/difficulty_select.tscn — 难度选择界面（简单/普通/困难），选择后初始化游戏
- [ ] T073 实现场景 scenes/menu/save_load.tscn — 存档/读档界面，显示多个存档位（保存时间、学期数/当前周数、综合满意度、最近评级），支持覆盖保存确认（弹窗）
- [ ] T074 实现 scripts/autoload/save_manager.gd — 存档系统，将完整游戏状态序列化为 JSON 文件（user://saves/slot_N.json），加载时反序列化恢复所有管理器和学生状态
- [ ] T075 [P] 实现 scripts/ui/tutorial_system.gd — 按需提示系统，维护提示队列和已读标记，固定提示事件清单（首次打开建筑面板、首次修改参数、首次触发事件、首次查看仪表盘、首次启动升级），触发一次后标记已读不再重复
- [ ] T076 实现 scripts/core/staff.gd — 员工 Resource，包含 staff_type（厨师/维修工/保洁/宿管）、skill_level（MVP 固定初始值，不可培训）、assigned_building、monthly_salary

---

## Phase 11: 收尾与完善

**Purpose**: 整合所有系统，修复问题，准备可试玩版本

- [ ] T077 整合测试：完整运行一个学期（18周），验证时间循环、食堂运营、宿舍管理、满意度计算、评级、预算循环的端到端流程
- [ ] T078 性能优化：确认 500+ 学生同时移动时帧率不低于 30fps，对象池优化学生精灵创建/销毁
- [ ] T079 平衡性微调：调整 data/balance/game_params.json 中的效用权重和满意度阈值，确保默认参数下普通难度不会过快/过慢触发游戏结束
- [ ] T080 代码质量：运行 gdformat 格式化所有 GDScript 文件，确保无语法错误
- [ ] T081 创建占位字体 assets/fonts/default_font.tres — 使用 Godot 内置字体资源或开源中文字体

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: 无依赖，立即开始
- **Foundational (Phase 2)**: 依赖 Phase 1 — **阻塞所有用户故事**
- **US1 校园地图 (Phase 3)**: 依赖 Phase 2 — 无其他故事依赖
- **US2 食堂 (Phase 4)**: 依赖 Phase 2 + US1（需要地图和建筑交互）
- **US3 宿舍 (Phase 5)**: 依赖 Phase 2 + US1（需要地图和建筑交互）
- **US4 数据看板 (Phase 6)**: 依赖 Phase 2 + US2/US3（需要满意度和经济数据）
- **US5 学期评级 (Phase 7)**: 依赖 Phase 2 + US4（需要满意度和经济数据完整）
- **US6 随机事件 (Phase 8)**: 依赖 Phase 2 + US2/US3（事件影响这些系统）
- **US7 建筑升级 (Phase 9)**: 依赖 Phase 2 + US2/US3（升级影响食堂和宿舍）
- **菜单存档 (Phase 10)**: 依赖 Phase 2
- **收尾 (Phase 11)**: 依赖所有用户故事

### Parallel Opportunities

Phase 1 中 T003-T007 全部可并行（不同 JSON 文件）。
Phase 3 中 T014/T015/T016/T017/T018/T028/T029/T030 全部可并行。
Phase 4 中 T032/T033/T034/T035 可并行（数据文件和 Resource 类）。
Phase 6 中 T051/T052 可并行（仪表盘和事件日志独立）。
Phase 7 中 T056/T057/T058/T059 可并行（满意度/经济/声望/学期 Resource）。
Phase 8 中 T064/T065 可并行。

---

## Implementation Strategy

### MVP First (仅 Phase 1-3)

1. 完成 Phase 1: 项目初始化
2. 完成 Phase 2: 核心基础设施
3. 完成 Phase 3: 校园地图 + 学生移动
4. **STOP and VALIDATE**: 能看到校园地图上学生实时移动，切换速度
5. 这就是一个可演示的最小 MVP：一个有校园地图和学生活动的"沙盒"

### Incremental Delivery

1. Setup + Foundational → 基础就绪
2. + US1 → 可视化校园地图（MVP 演示）
3. + US2 + US3 → 核心玩法可玩（食堂+宿舍配置）
4. + US4 + US5 → 完整经营循环（数据看板+学期评级）
5. + US6 + US7 → 额外深度（事件+升级）
6. + 菜单存档 + 收尾 → 完整可发布版本
