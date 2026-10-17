class_name ReactionSolver
extends RefCounted

## K1 查询接口（契约 02 §1.2）。
## 候选反应的 K 由温度唯一决定；按 K 降序贪心，K 近似相等时按 elements.json 表序。
## 单反应平衡交给 EquilibriumSolver，结果组装留在本类。

const TAU_SCALE_C := 100.0  # no-magic-ok: K 公式的 τ 单位（每 100°C 一个单位）
const K_EPSILON := 1e-9  # no-magic-ok: K 相等的比较容差
const KNOWN_CONDITIONS: Array[String] = [
	"temperature_c",
	"pressure_atm",
	"ambient",
	"spirit_phi",
	"catalyst",
	"duration_minutes",
]

var _db: ContentDatabase
var _alpha: float
var _t_ref_c: float
var _axis_multiplier: float
var _k_ref_by_tier: Dictionary


func _init(db: ContentDatabase) -> void:
	_db = db
	_alpha = float(db.constant("reaction.alpha"))
	_t_ref_c = float(db.constant("reaction.t_ref_c"))
	_axis_multiplier = float(db.constant("reaction.axis_multiplier"))
	_k_ref_by_tier = db.constant("reaction.k_ref_by_tier")


func solve(pool: Dictionary, conditions: Dictionary) -> CraftResult:
	_warn_unknown_conditions(conditions)
	var result := CraftResult.new()
	var free: Dictionary = {}
	var total_units := 0.0
	for element_id in pool:
		var amount := float(pool[element_id])
		if amount > 0.0:
			free[str(element_id)] = amount
			total_units += amount
	if total_units <= 0.0:
		return result

	var temperature_c := _read_temperature(conditions)
	var reactions := _build_reactions(temperature_c)
	var used: Dictionary = {}
	var compound_amounts: Dictionary = {}
	var theoretical: Dictionary = {}
	var reaction_log: Array = []

	while true:
		var picked: Dictionary = {}
		for reaction in reactions:
			var candidate_id: String = reaction["compound"]
			if used.has(candidate_id):
				continue
			var candidate_composition: Dictionary = reaction["composition"]
			if not EquilibriumSolver.is_possible(free, candidate_composition):
				continue
			picked = reaction
			break
		if picked.is_empty():
			break

		var compound_id: String = picked["compound"]
		var composition: Dictionary = picked["composition"]
		var k: float = picked["k"]
		used[compound_id] = true
		var x_max := EquilibriumSolver.max_extent(free, composition)
		if x_max <= EquilibriumSolver.MIN_AMOUNT:
			continue
		var extent := EquilibriumSolver.solve_extent(free, composition, k, x_max)
		if extent <= EquilibriumSolver.MIN_AMOUNT:
			continue

		var consumed: Dictionary = {}
		for element_id in composition:
			var coefficient := float(composition[element_id])
			var taken := coefficient * extent
			consumed[element_id] = taken
			free[element_id] = maxf(0.0, float(free.get(element_id, 0.0)) - taken)
		compound_amounts[compound_id] = extent
		theoretical[compound_id] = x_max
		reaction_log.append({
			"compound": compound_id,
			"k": k,
			"order": reaction_log.size() + 1,
			"consumed": consumed,
		})

	result.reaction_log = reaction_log
	result.composition = _build_composition(free, compound_amounts, total_units)
	result.dominant = _find_dominant(result.composition)
	result.yield_ratio = _find_yield(result.dominant, compound_amounts, theoretical)
	result.reading = _build_reading(result.composition)
	return result


func _build_reactions(temperature_c: float) -> Array:
	var reactions: Array = []
	for element_id in _db.element_ids():
		var entry := _db.element(element_id)
		if str(entry.get("kind", "")) != "compound":
			continue
		var composition: Dictionary = entry.get("composition", {})
		reactions.append({
			"compound": element_id,
			"composition": composition,
			"k": _k_value(entry, temperature_c),
			"order": _db.element_order(element_id),
		})
	reactions.sort_custom(_reaction_precedes)
	return reactions


func _reaction_precedes(a: Dictionary, b: Dictionary) -> bool:
	var k_a := float(a["k"])
	var k_b := float(b["k"])
	if abs(k_a - k_b) > K_EPSILON * maxf(1.0, maxf(abs(k_a), abs(k_b))):
		return k_a > k_b
	return int(a["order"]) < int(b["order"])


func _k_value(entry: Dictionary, temperature_c: float) -> float:
	var tier := int(entry.get("tier", 1))
	var k_ref := float(_k_ref_by_tier.get(str(tier), 0.0))
	var delta_h := float(entry.get("delta_h", 0.0))
	var tau := (temperature_c - _t_ref_c) / TAU_SCALE_C
	var k := k_ref * exp(_alpha * delta_h * tau)
	if entry.get("axis", null) != null:
		k *= _axis_multiplier
	return k


func _build_composition(free: Dictionary, compound_amounts: Dictionary, total_units: float) -> Dictionary:
	var composition: Dictionary = {}
	for element_id in free:
		var amount := float(free[element_id])
		if amount > EquilibriumSolver.MIN_AMOUNT:
			composition[str(element_id)] = amount / total_units
	for compound_id in compound_amounts:
		var extent := float(compound_amounts[compound_id])
		if extent <= EquilibriumSolver.MIN_AMOUNT:
			continue
		var entry := _db.element(str(compound_id))
		var parts: Dictionary = entry.get("composition", {})
		var units := 0.0
		for element_id in parts:
			units += float(parts[element_id]) * extent
		composition[str(compound_id)] = units / total_units
	var sum := 0.0
	for id in composition:
		sum += float(composition[id])
	if sum > 0.0:
		for id in composition:
			composition[id] = float(composition[id]) / sum
	return composition


func _find_dominant(composition: Dictionary) -> String:
	var best_id := ""
	var best_ratio := 0.0
	for element_id in _db.element_ids():
		if not composition.has(element_id):
			continue
		if str(_db.element(element_id).get("kind", "")) != "compound":
			continue
		var ratio := float(composition[element_id])
		if ratio > best_ratio:
			best_ratio = ratio
			best_id = element_id
	return best_id


func _find_yield(dominant: String, compound_amounts: Dictionary, theoretical: Dictionary) -> float:
	if dominant == "" or not compound_amounts.has(dominant) or not theoretical.has(dominant):
		return 0.0
	var max_extent := float(theoretical[dominant])
	if max_extent <= 0.0:
		return 0.0
	return clampf(float(compound_amounts[dominant]) / max_extent, 0.0, 1.0)


func _build_reading(composition: Dictionary) -> Dictionary:
	var effects: Dictionary = {}
	var costs: Dictionary = {}
	for id in composition:
		var ratio := float(composition[id])
		var entry := _db.element(str(id))
		var entry_effects: Variant = entry.get("effects", {})
		if entry_effects is Dictionary:
			for effect_id in entry_effects:
				effects[effect_id] = float(effects.get(effect_id, 0.0)) + float(entry_effects[effect_id]) * ratio
		var entry_costs: Variant = entry.get("costs", {})
		if entry_costs is Dictionary:
			for cost_id in entry_costs:
				costs[cost_id] = float(costs.get(cost_id, 0.0)) + float(entry_costs[cost_id]) * ratio
	return { "effects": effects, "costs": costs }


func _read_temperature(conditions: Dictionary) -> float:
	if conditions.has("temperature_c") and _is_number(conditions["temperature_c"]):
		return float(conditions["temperature_c"])
	return _t_ref_c


func _warn_unknown_conditions(conditions: Dictionary) -> void:
	if not OS.is_debug_build():
		return
	for key in conditions:
		if not KNOWN_CONDITIONS.has(str(key)):
			push_warning("ReactionSolver: 未知条件轴 %s（M1 忽略）" % str(key))


func _is_number(value: Variant) -> bool:
	return typeof(value) == TYPE_INT or typeof(value) == TYPE_FLOAT
