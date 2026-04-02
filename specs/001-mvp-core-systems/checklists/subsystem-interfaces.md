# 子系统接口完整性检查: 校园后勤管理模拟游戏 MVP

**Purpose**: 验证所有子系统（地图、食堂、宿舍、时间、满意度、经济、事件、升级、存档）之间的接口定义是否完整、无遗漏、无矛盾
**Created**: 2026-04-01
**Feature**: [spec.md](../spec.md) | [contracts/game_events_interface.md](../contracts/game_events_interface.md) | [data-model.md](../data-model.md)

## 采访解决方案记录 (2026-04-01)

以下决策通过用户采访确认，应在后续实施时更新到 contracts 和 data-model 中：

- **CHK009 排队信号**: 新增 `student_queued(student_id, window_id)`、`student_dequeued(student_id, window_id)`、`student_served(student_id, window_id, satisfaction_delta)` 三个信号到 GameEvents
- **CHK026 存档schema**: 采用全量快照模式，存档 JSON 包含 metadata/time/budget/satisfaction/reputation/所有 cafeteria/所有 dormitory_group/所有 student/events_triggered
- **CHK030 满意度公式**: `变化 = (体验质量分 - 50) × 性格系数`，体验质量分 = 效用值归一化到 0-100，性格系数存储在 game_params.json（吃货 0.8、学霸 0.3、抠门 0.5、运动健将 0.4）
- **CHK037 食堂汇总**: 食堂维度满意度 = 所有学生个人食堂满意度的算术平均值
- **CHK017 员工工资**: 按岗位固定月薪，在 game_params.json 中定义（厨师 3500、维修工 3000、保洁 2500、宿管 2800），人数自动配齐不可调整
- **CHK019 利润达标**: 学期总利润 > 0 且 学期末综合满意度 ≥ 60（双重条件）
- **CHK020 事件分发**: EventManager 直接调用受影响子系统方法（如 SatisfactionManager.adjust_category()、EconomyManager.spend()）
- **CHK014-015 背景满意度**: 教学环境基准 70 分、文娱基准 65 分，事件可临时增减，到期按天线性回归基准值
- **CHK021 故障持续**: 故障事件有 daily_damage 和 max_duration_days 字段，每日自动施加伤害，超时自动修复（满意度部分恢复，声望下降）
- **CHK025 升级清队**: 升级开始时立即清空排队队列，被清出学生由 StudentAI 重新评估选择

## 信号总线完整性

- [ ] CHK001 - GameEvents 是否为所有子系统间需要传递状态变更的场景都定义了信号？当前是否有子系统状态变更但未定义对应信号的情况？ [Completeness, Spec §FR-005 ~ FR-034]
- [ ] CHK002 - 信号参数类型是否全部明确（int/float/String/enum/Dictionary）？是否存在参数类型模糊的信号？ [Clarity, Contracts §1]
- [ ] CHK003 - 信号触发时机是否覆盖了"游戏开始→每日循环→学期结束→游戏结束"的完整生命周期？是否缺少"游戏暂停/恢复"相关信号？ [Coverage]
- [ ] CHK004 - 是否存在同一状态变更通过多个冗余信号广播的情况（例如 satisfaction_category_changed 和 satisfaction_overall_changed 是否会产生重复通知风暴）？ [Consistency]

## TimeManager ↔ 其他子系统接口

- [ ] CHK005 - TimeManager 是否暴露了所有子系统需要的只读时间属性？data-model.md 中 Semester 的 current_week/current_day 是否与 TimeManager 对齐？ [Consistency, Data-Model §9 vs Contracts §2]
- [ ] CHK006 - 四档速度的倍率值是否明确定义（暂停=0、正常=1、快进=?、极速=?）？contracts 中只说了"0/1/2/3"，倍率数值是否在 time_config.json 中定义？ [Clarity, Contracts §2]
- [ ] CHK007 - "时段变更"信号 time_period_changed 是否携带了足够的上下文（当天是周几、是否周末）供学生AI判断行为差异？ [Completeness, Contracts §1]
- [ ] CHK008 - 是否定义了 TimeManager 与 SaveManager 的接口？存档时需要保存/恢复哪些时间状态？ [Gap]

## StudentAI ↔ 食堂系统接口

- [ ] CHK009 - StudentAI 选择窗口后，是否有明确的信号通知 CafeteriaSystem 将学生加入排队队列？contracts 中提到"通过信号通知 CafeteriaSystem 排队变化"，但 GameEvents 中未定义 student_queued/student_dequeued 信号 [Gap]
- [ ] CHK010 - 学生到达食堂但所有窗口排队满时，StudentAI 是否有明确的决策路径定义？spec edge case 中提到了但 data-model 和 contracts 中是否有对应处理？ [Coverage, Spec §Edge Cases]
- [ ] CHK011 - 食堂窗口服务完成后，谁负责通知学生离开队列？是 CafeteriaSystem 自动处理还是通过信号通知 StudentAI？这个接口是否明确？ [Ambiguity, Contracts §2]
- [ ] CHK012 - get_window_utility 的效用值量纲是否明确？各因子（口味匹配/价格/距离/排队/质量）的单位和取值范围是否一致（都是0-100还是混合量纲）？ [Clarity, Spec §FR-019, Research §9]

## SatisfactionManager ↔ 满意度数据源接口

- [ ] CHK013 - SatisfactionManager 如何接收"就餐体验满意度"数据？是 CafeteriaSystem 在每次就餐后发射 satisfaction_category_changed 还是由 SatisfactionManager 主动拉取？这个方向是否明确？ [Ambiguity]
- [ ] CHK014 - 教学环境满意度和文娱满意度的数据来源是否明确？assumptions 中说是"固定背景值"，但 FR-022 说它们占40%权重。它们的初始值是多少？随机事件改变它们后如何恢复？ [Completeness, Spec §Assumptions vs §FR-022]
- [ ] CHK015 - "教学环境"维度在MVP不受玩家管理但受随机事件影响，事件对教学/文娱满意度的临时影响是否有持续时间定义？是立即恢复还是持续到学期结束？ [Gap]

## EconomyManager ↔ 收入/支出数据源接口

- [ ] CHK016 - EconomyManager 是否定义了接收所有收入和支出数据的接口？食堂营收数据从 CafeteriaSystem 获取、宿舍水电费从 DormitorySystem 获取、员工工资从哪里获取？ [Completeness]
- [ ] CHK017 - 员工工资的计算公式是否明确定义？data-model 中 Staff 有 skill_level，但工资 = 基础工资 × 技能等级？各岗位的基础工资是多少？ [Gap]
- [ ] CHK018 - 食材成本的计算周期是每时段/每日/每周？与食堂窗口的关系是按窗口独立计算还是按餐厅汇总？ [Clarity]
- [ ] CHK019 - "利润达标"的判定标准是否明确定义？FR-026 说"满意度高且利润达标"，但"达标"的具体阈值是多少？是正值还是参考值？ [Ambiguity, Spec §FR-026]

## EventManager ↔ 受影响子系统接口

- [ ] CHK020 - event_resolved 信号中 choice_index 对应的效果如何传递给各子系统？是 EventManager 直接调用还是通过信号链传递？这个分发机制是否明确？ [Ambiguity]
- [ ] CHK021 - 设备故障类事件（如管道漏水）的"持续未修复"状态如何在系统中维护？是否有定时检查机制还是仅在事件解决时一次性处理？ [Gap]
- [ ] CHK022 - 周期性事件（如考试周）的开始和结束是否有对应信号通知？考试周影响学生行为模式，StudentAI 如何感知考试周的开始和结束？ [Coverage]

## UpgradeSystem ↔ 建筑/经济接口

- [ ] CHK023 - 升级的"资金检查"接口是否定义？UpgradeSystem 验证资金时是从 EconomyManager 读取余额还是自主维护？ [Completeness]
- [ ] CHK024 - 升级完成后"属性提升"的具体数值（服务速度提升多少、质量上限提升多少）是否在 upgrade_definitions.json 中明确定义？还是由代码硬编码？这涉及宪章原则VI数据驱动 [Clarity]
- [ ] CHK025 - 升级施工期间，窗口/组团被标记为不可用后，已排队的学生如何处理？是被自动移除排队还是继续等待？ [Edge Case, Gap]

## SaveManager ↔ 所有子系统接口

- [ ] CHK026 - SaveManager 需要序列化哪些状态？是否有一个明确的状态快照schema定义（student数据、cafeteria配置、dormitory配置、budget、satisfaction等）？plan.md 中提到了存档JSON结构但未在 contracts 或 data-model 中正式定义 [Gap]
- [ ] CHK027 - 读档恢复时，所有 Autoload 单例是否有一致的初始化顺序？是否存在循环依赖（如 SatisfactionManager 需要 cafeteria 数据，CafeteriaSystem 需要 satisfaction 数据）？ [Consistency]
- [ ] CHK028 - 存档版本兼容性是否定义？如果后续更新了存档schema（新增字段），旧存档如何处理？ [Gap]

## Student 实体 ↔ 分配/属性接口

- [ ] CHK029 - 学生分配到宿舍组团/楼栋的规则是否明确？是按组团均匀分配还是按学生类型（本科/研究生）分配到对应组团？ [Completeness, Data-Model §1]
- [ ] CHK030 - 学生满意度（satisfaction_cafeteria / satisfaction_dormitory）的计算频率是每次就餐/每日结算还是实时累积？FR-021 说"受体验影响"，但变化幅度公式是否定义？ [Clarity, Spec §FR-021]
- [ ] CHK031 - Student 的 meals_today 字段用于什么逻辑？是否有"一日三餐必须都吃"的要求？超过3次会怎样？不足呢？ [Coverage, Data-Model §1]

## 建筑类型 ↔ 交互接口

- [ ] CHK032 - FR-004 列出了校医院和体育馆，但 MVP 不做这些系统。它们在地图上的处理方式是否明确？仅作为不可交互背景建筑还是有最小限度的数据模型？ [Completeness, Spec §FR-004 vs Assumptions]
- [ ] CHK033 - 不可交互建筑（教学楼、图书馆）是否定义了任何属性？学生在"上课"状态时进入教学楼，教学楼是否需要有容量限制或内部状态？ [Gap]
- [ ] CHK034 - 建筑升级系统（FR-032-034）是否适用于所有建筑类型还是仅限食堂和宿舍？contracts 中 upgrade_started 信号接受 building_id 但未限制类型 [Consistency]

## 跨子系统数据一致性

- [ ] CHK035 - 所有引用同一实体（如 Cafeteria、Student）的子系统是否使用相同的唯一标识符？restaurant_id / student_id 的格式和命名规范是否全局一致？ [Consistency, Data-Model vs Contracts]
- [ ] CHK036 - 学生实体在 StudentManager、CafeteriaSystem（排队）、DormitorySystem（住宿满意度）中是否共享同一实例引用，还是各维护独立副本？data一致性如何保证？ [Consistency]
- [ ] CHK037 - 满意度计算中"食堂满意度"的具体计算公式是否明确定义？是所有9个餐厅满意度的算术平均还是加权平均（如按客流量加权）？ [Clarity, Spec §FR-022]
