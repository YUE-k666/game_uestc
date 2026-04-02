# 综合质量扫描: 校园后勤管理模拟游戏 MVP 核心玩法

**Purpose**: 全面扫描已覆盖维度之外的需求质量缺陷——数据模型、可追溯性、数值系统、跨文档一致性、UI需求、边界场景
**Created**: 2026-04-01
**Focus**: 全面扫描 | **Depth**: 标准 | **Audience**: 评审者（PR）
**Feature**: [spec.md](../spec.md) | [plan.md](../plan.md) | [tasks.md](../tasks.md) | [data-model.md](../data-model.md) | [contracts/game_events_interface.md](../contracts/game_events_interface.md)

## 采访决策记录 (2026-04-01)

以下决策通过用户采访确认，应在后续实施时更新到对应文档中：

### 核心玩法基础
- **CHK016 餐厅数量**: 朝阳餐厅 = 1 个 Cafeteria 实体（含 floors: [1, 2] 属性），总计 9 个餐厅。plan.md 中"朝阳1楼/朝阳2楼"的表述需修正为"朝阳（1楼+2楼）"
- **CHK010 效用归一化**: 各因子归一化到 0-1 后加权求和。价格→1-(price/max_price)、距离→1-(dist/max_dist)、排队→1-(queue/queue_max)、质量→quality_score/100、口味→match(1/0)。最终效用 0-1。max 值在 game_params.json 中定义
- **CHK017 加成率层级**: markup_rate 保持在 WindowSlot（窗口级），每个窗口独立设置。FR-011 措辞"整个窗口"解读为"每个窗口整体"而非"整个餐厅"
- **CHK012 评级标准**: 双指标独立门槛。满意度和利润达成率各自有最低门槛（如 S 要求均分≥85 且利润≥120%），两项都达标才给该评级。阈值矩阵在 semester_config.json 中定义

### 数值公式
- **CHK011 体验质量分**: 体验质量分 = 效用值 × 100 - 等待惩罚（等待惩罚 = 排队时长 × 惩罚系数，系数在 game_params.json 中定义）。满意度变化 = (体验质量分 - 50) × 性格系数 × 宽容度系数
- **CHK013 预算公式**: 新预算 = 基准预算 × (1 + 满意度贡献 + 声望贡献)。满意度贡献 = (学期满意度均值 - 60) / 200，声望贡献 = 声望值 / 500。受 performance_coefficient 乘数调整
- **CHK015 钱包重置**: 新学期钱包 = 基础金额（由难度决定） ± 20% 随机波动。不结转上学期余额。基础金额在 difficulty_presets.json 中定义（建议：简单 2000、普通 1500、困难 1000）
- **CHK014 难度参数影响**: student_tolerance → 满意度下降的衰减系数（tolerance=0.8 时满意度下降幅度 ×0.8）。performance_coefficient → 预算变化率的乘数（系数=1.2 时预算增长快 20%）

### 数据模型
- **CHK018 员工培训**: MVP 不做培训。Staff 实体保留 skill_level（初始值固定，按建筑自动配齐），不提供培训机制。spec Assumptions 需修正"可培训"为"技能等级固定"
- **CHK003 Student 状态**: 增加 4 个状态：returning_late（晚归）、exercising（文娱）、queuing_cafeteria（食堂排队）、queuing_facility（设施排队）。原 queuing 状态拆分为更具体的排队类型
- **CHK019 时间权威源**: TimeManager 是运行时权威来源。每帧同步更新 Semester Resource 的 current_week/current_day/current_period 字段（用于 UI 绑定和存档序列化）
- **CHK020 非核心建筑**: 校医院、体育馆、商业街等在 campus_layout.json 中有位置和名称（type="other"），Building 基类实例化但无子系统逻辑。学生到达后进入 idle 状态

### UI 需求
- **CHK022 预警层级**: 仅 2 层——65 分黄色警告（横幅提示），60 分红色（游戏结束触发）
- **CHK021 图表粒度**: 默认显示过去 7 天（按日采样），可切换到过去 4 周（按周采样）。数据点取每日结束时快照值
- **CHK023 滑块范围**: 所有参数范围和步进值在 dormitory_groups.json 的 config_bounds 字段中定义，面板运行时动态读取（JSON 配置驱动）
- **CHK024 存档信息**: 文字摘要 4 项——存档时间、学期数/当前周数、综合满意度、最近评级。支持覆盖保存确认（弹窗），不支持删除存档

### 边界场景
- **CHK026 全食堂施工**: 无兜底机制。所有学生放弃就餐，满意度按放弃规则下降。玩家的策略失误
- **CHK027 预算耗尽**: 触发"财务危机"特殊事件——强制玩家选择：削减服务（满意度 -X）或申请紧急拨款（下学期预算减少 Y%）
- **CHK028 学期中施工**: 升级进度保留，跨学期继续。已投入资金不退还。施工状态持续到下学期
- **CHK029 移动中目标施工**: 施工开始时立即通知所有目标为该建筑的学生（upgrade_started 信号 → StudentAI 重路由），学生中途更改目标
- **CHK030 暂停修改参数**: 修改缓存，下个时段变更时（time_period_changed）才生效。给玩家"下好棋等开局"的策略感
- **CHK004 队列上限**: queue_max_length 既是逻辑限制也是 UI 限制。队列达到上限后新学生自动放弃该窗口，由 StudentAI 重新选择
- **CHK005 热水时段**: MVP 仅支持连续时段（start-end），不支持非连续多段配置

### 提示系统
- **CHK025 提示触发**: 固定提示事件清单——首次打开建筑面板、首次修改参数、首次触发事件、首次查看仪表盘、首次启动升级。每个触发一次后标记已读，不再重复

## 待办动作（无需用户决策，直接执行）

以下为需要补充到文档中的具体修改项：

- [ ] CHK031 - 在 data-model.md 中补充 Staff 实体正式定义（staff_type、skill_level、assigned_building_id、monthly_salary），明确 skill_level 在 MVP 中为固定初始值，不可通过培训变更 [Action, Data-Model]
- [ ] CHK032 - 在 data-model.md 中补充 SaveSlot 实体定义：slot_id、created_at、updated_at、semester_number、current_week、overall_satisfaction、latest_rating、game_state_snapshot [Action, Data-Model]
- [ ] CHK033 - 在 data-model.md 中更新 Student state 枚举，增加 returning_late、exercising、queuing_cafeteria、queuing_facility 4 个状态 [Action, Data-Model §1]
- [ ] CHK034 - 在 spec.md 中修正 FR-007，明确朝阳餐厅为 1 个餐厅含 2 层楼，餐厅总数为 9 个 [Action, Spec §FR-007]
- [ ] CHK035 - 在 spec.md Assumptions 中修正"可培训"为"技能等级固定，MVP 不做培训系统" [Action, Spec §Assumptions]
- [ ] CHK036 - 在 tasks.md 中补充考试周对学生 AI 行为影响的任务（T066 描述扩展或新增子任务）[Action, Tasks §T066]
- [ ] CHK037 - 在 tasks.md 中补充"财务危机"事件的任务（T064 event_definitions.json 需包含此事件定义）[Action, Tasks §T064]
- [ ] CHK038 - 在 tasks.md 中补充施工时重路由学生的任务（T069 upgrade_system.gd 描述扩展，发射信号通知 StudentAI）[Action, Tasks §T069]
- [ ] CHK039 - 在 tasks.md 中明确 FR-014 "一菜一饭"的成本计算规则——米饭成本为固定值（如 1.5 元/份），在 game_params.json 中定义 rice_cost_per_meal [Action, Tasks §T037]
- [ ] CHK040 - 在 game_params.json 设计中补充效用归一化所需参数：max_price、max_distance、queue_max 默认值、wait_penalty_coefficient [Action, Data Files]

## 原始检查项（已完成决策）

### 数据模型完整性

- [x] CHK001 - Staff（员工）实体在 spec §Key Entities 和 plan §Project Structure 中均有列出，但 data-model.md 未定义其字段结构 → 需补充正式实体定义（CHK031） [Gap, Data-Model vs Spec §Key Entities]
- [x] CHK002 - SaveSlot（存档）实体在 spec §Key Entities 中列出，但 data-model.md 和 contracts 均未定义存档 schema → 需补充（CHK032） [Gap]
- [x] CHK003 - Student 实体 state 枚举不全 → 增加 4 个状态（CHK033） [Completeness, Data-Model §1]
- [x] CHK004 - queue_max_length 语义不明 → 既是逻辑限制也是 UI 限制，达到上限后学生自动放弃 [Ambiguity, Data-Model §4]
- [x] CHK005 - 热水时段是否支持多段 → MVP 仅支持连续时段 [Clarity, Data-Model §6]

### 需求-任务可追溯性

- [ ] CHK006 - spec §Edge Cases 6 个边界场景在 tasks.md 中无对应任务 → 部分由 CHK026-030 决策覆盖（财务危机事件、施工重路由等），CHK037-038 补充任务 [Coverage]
- [ ] CHK007 - FR-014 "一菜一饭"成本规则不明 → 米饭成本为固定值，在 game_params.json 中定义（CHK039） [Traceability]
- [ ] CHK008 - 考试周影响学生 AI 行为无任务 → 需补充任务（CHK036） [Coverage]
- [ ] CHK009 - 楼栋数据归属不清晰 → campus_layout.json 定义位置坐标，dormitory_groups.json 定义楼栋属性（等级、容量等），通过 building_id 关联 [Clarity]

### 数值系统与公式完备性

- [x] CHK010 - 效用函数归一化 → 各因子归一化到 0-1 后加权求和 [Clarity, Spec §FR-019]
- [x] CHK011 - 体验质量分来源 → 效用值 × 100 - 等待惩罚 [Completeness, Spec §FR-021]
- [x] CHK012 - 评级阈值未定义 → 双指标独立门槛，semester_config.json 定义阈值矩阵 [Gap, Spec §FR-029]
- [x] CHK013 - 预算变化公式未定义 → 基准预算 × (1 + 满意度贡献 + 声望贡献) [Gap, Spec §FR-026]
- [x] CHK014 - 难度参数影响范围不明 → 宽容度→满意度衰减系数，绩效系数→预算乘数 [Ambiguity]
- [x] CHK015 - 钱包重置金额未定义 → 固定值 ± 20% 随机波动，由难度决定 [Gap]

### 跨文档一致性

- [x] CHK016 - 餐厅数量矛盾 → 朝阳=1个餐厅含楼层属性，总计 9 个 [Conflict]
- [x] CHK017 - markup_rate 层级歧义 → 窗口级，每窗口独立设置 [Ambiguity]
- [x] CHK018 - 员工培训范围冲突 → MVP 不做培训，修正 spec Assumptions [Conflict]
- [x] CHK019 - Semester 与 TimeManager 重复定义 → TimeManager 权威 + 同步到 Semester [Consistency]
- [x] CHK020 - 非核心建筑处理未定义 → 最小数据模型（type="other"），无子系统逻辑 [Completeness]

### UI 需求清晰度

- [x] CHK021 - 图表数据粒度 → 默认 7 天/按日，可切换 4 周/按周 [Clarity]
- [x] CHK022 - 预警阈值层级 → 2 层（65 黄色、60 红色） [Completeness]
- [x] CHK023 - 滑块范围 → JSON 配置驱动，dormitory_groups.json 定义 [Clarity]
- [x] CHK024 - 存档界面信息 → 文字摘要 4 项，支持覆盖确认 [Completeness]
- [x] CHK025 - 提示触发条件 → 固定提示事件清单，触发一次后标记已读 [Clarity]

### 边界场景与异常流

- [x] CHK026 - 全食堂施工 → 无兜底，学生直接放弃就餐 [Coverage]
- [x] CHK027 - 预算耗尽 → 触发"财务危机"事件，强制玩家二选一 [Exception Flow]
- [x] CHK028 - 学期中施工 → 进度保留跨学期继续，已投入资金不退 [Coverage]
- [x] CHK029 - 移动中目标施工 → 施工开始时立即重路由 [Exception Flow]
- [x] CHK030 - 暂停修改参数 → 缓存到下个时段生效 [Coverage]
