class_name EquilibriumSolver
extends RefCounted

## 单反应平衡求解（契约 02 §1.2 的方程）。
## 纯数学，不依赖内容库，便于独立测试。
##
## 求 g(x) = x − K·∏(A_i − a_i·x)^a_i = 0，x ∈ [0, x_max]。
## g(0) < 0，g(x_max) > 0，且单调递增，二分法稳定。

const BISECTION_STEPS := 80  # no-magic-ok: 固定迭代次数，保证确定性
const MIN_AMOUNT := 1e-12  # no-magic-ok: 数值零阈值，非策划数值


static func is_possible(free: Dictionary, composition: Dictionary) -> bool:
	if composition.is_empty():
		return false
	for element_id in composition:
		if float(free.get(element_id, 0.0)) <= MIN_AMOUNT:
			return false
	return true


static func max_extent(free: Dictionary, composition: Dictionary) -> float:
	var limit := INF
	for element_id in composition:
		var coefficient := float(composition[element_id])
		if coefficient <= 0.0:
			return 0.0
		limit = minf(limit, float(free.get(element_id, 0.0)) / coefficient)
	return maxf(0.0, limit)


static func solve_extent(free: Dictionary, composition: Dictionary, k: float, x_max: float) -> float:
	var low := 0.0
	var high := x_max
	for _step in BISECTION_STEPS:
		var mid := (low + high) / 2.0
		if _g_value(mid, free, composition, k) < 0.0:
			low = mid
		else:
			high = mid
	return (low + high) / 2.0


static func _g_value(x: float, free: Dictionary, composition: Dictionary, k: float) -> float:
	var product := 1.0
	for element_id in composition:
		var coefficient := float(composition[element_id])
		var remaining := maxf(0.0, float(free.get(element_id, 0.0)) - coefficient * x)
		product *= pow(remaining, coefficient)
	return x - k * product
