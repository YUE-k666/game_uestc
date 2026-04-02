extends Node

## 学期评级系统 — 计算评级、确定下学期预算

func calculate_rating(satisfaction_avg: float, profit_achievement: float) -> String:
	var thresholds := GameConfig.get_rating_thresholds()
	# 从高到低检查
	for grade in ["S", "A", "B", "C"]:
		var threshold: Dictionary = thresholds.get(grade, {})
		var sat_min: float = float(threshold.get("satisfaction_min", 0))
		var profit_min: float = float(threshold.get("profit_achievement_min", 0))
		if satisfaction_avg >= sat_min and profit_achievement >= profit_min:
			return grade
	return "F"

func calculate_next_budget(current_budget: float, satisfaction_avg: float, reputation: float) -> float:
	var config := GameConfig.semester_config
	var base_budget: float = float(config.get("基准预算", 500000.0))
	var sat_coeff: float = float(config.get("满意度贡献系数", 0.3))
	var rep_coeff: float = float(config.get("声望贡献系数", 0.2))

	var difficulty := GameConfig.get_difficulty_config()
	var perf_coeff: float = float(difficulty.get("performance_coefficient", 1.0))

	# 新预算 = 基准 × (1 + 满意度贡献 + 声望贡献) × 绩效系数
	var satisfaction_factor := (satisfaction_avg - 50.0) / 100.0 * sat_coeff
	var reputation_factor := (reputation - 50.0) / 100.0 * rep_coeff
	var new_budget := base_budget * (1.0 + satisfaction_factor + reputation_factor) * perf_coeff

	return maxf(new_budget, base_budget * 0.5)  # 最低不低于基准的50%

## 计算利润达成率
func calculate_profit_achievement(revenue: float, expense: float, budget: float) -> float:
	if budget <= 0.0:
		return 0.0
	var profit := revenue - expense
	var target_profit := budget * 0.1  # 目标利润为预算的10%
	if target_profit <= 0.0:
		return 100.0
	return clampf(profit / target_profit * 100.0, 0.0, 100.0)
