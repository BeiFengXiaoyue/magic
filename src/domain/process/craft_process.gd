class_name CraftProcess
extends RefCounted

## 炼制过程（契约 02 §2.1）。
## 材料 → 元素池（波动经 craft 流）→ 温度（经 device 流）→ 求解 → 会话。
## 换火候只重掷温度并重解，不重新消费 craft 流。

const MIN_AMOUNT := 1e-12  # no-magic-ok: 数值零阈值，非策划数值
const DEFAULT_TIER := 1  # no-magic-ok: M1 只有 T1；配方未命中时的阶兜底

var _db: ContentDatabase
var _rng: DeterministicRng
var _solver: ReactionSolver
var _tiers: Array
var _temperature_range: Array
var _device: Dictionary
var _device_id: String
var _craft_minutes_by_tier: Dictionary


func _init(db: ContentDatabase, rng: DeterministicRng, solver: ReactionSolver) -> void:
	_db = db
	_rng = rng
	_solver = solver
	_tiers = db.constant("reaction.temperature_tiers")
	_temperature_range = db.constant("reaction.temperature_range_c")
	_device = db.constant("device")
	_device_id = str(_device.get("default_id", ""))
	_craft_minutes_by_tier = db.constant("time.craft_minutes_by_tier")


func start(inputs: Dictionary, conditions: Dictionary) -> CraftSession:
	var tier_id := str(conditions.get("temperature_tier", ""))
	var temperature := _roll_temperature(tier_id)
	if is_nan(temperature):
		push_error("CraftProcess: 缺少或未知 temperature_tier: %s" % tier_id)
		return null
	var pool := _build_element_pool(inputs)
	if pool.is_empty():
		push_error("CraftProcess: 元素池为空")
		return null
	var recipe_match := _match_recipe(inputs, tier_id)
	var duration := int(recipe_match["duration"])
	if duration <= 0:
		push_error("CraftProcess: 无法确定炼制时长")
		return null

	var session := CraftSession.new()
	session.inputs = inputs.duplicate()
	session.recipe_id = str(recipe_match["recipe_id"])
	session.tier_id = tier_id
	session.temperature_c = temperature
	session.duration_minutes = duration
	session.element_pool = pool.duplicate()
	session.result = _solver.solve(pool, { "temperature_c": temperature })
	return session


func tick(session: CraftSession, game_minutes: int) -> void:
	if session == null:
		return
	session.advance(game_minutes)


func set_tier(session: CraftSession, tier_id: String) -> void:
	if session == null:
		return
	var temperature := _roll_temperature(tier_id)
	if is_nan(temperature):
		return
	session.tier_id = tier_id
	session.temperature_c = temperature
	session.result = _solver.solve(session.element_pool, { "temperature_c": temperature })


func take_out(session: CraftSession) -> CraftResult:
	if session == null or not session.finished:
		return null
	return session.result


func _roll_temperature(tier_id: String) -> float:
	var tier := _find_tier(tier_id)
	if tier.is_empty():
		return NAN
	var device_entry: Variant = _device.get(_device_id, null)
	if not device_entry is Dictionary:
		return NAN
	var jitter := float(device_entry.get("temp_jitter_c", 0.0))
	var device_rng := _rng.stream("device")
	var offset := device_rng.randf_range(-jitter, jitter)
	var minimum := float(_temperature_range[0])
	var maximum := float(_temperature_range[1])
	return clampf(float(tier["nominal_c"]) + offset, minimum, maximum)


func _find_tier(tier_id: String) -> Dictionary:
	for tier_entry in _tiers:
		var tier: Dictionary = tier_entry
		if str(tier.get("id", "")) == tier_id:
			return tier
	return {}


func _build_element_pool(inputs: Dictionary) -> Dictionary:
	var pool: Dictionary = {}
	var known: Dictionary = {}
	var craft_rng := _rng.stream("craft")
	for mat_id in _db.material_ids():
		known[mat_id] = true
		var count := int(inputs.get(mat_id, 0))
		if count <= 0:
			continue
		var material := _db.material(mat_id)
		var total_base := float(material.get("element_total", 0.0))
		var sigma := float(material.get("fluctuation", 0.0))
		var spectrum: Dictionary = material.get("spectrum", {})
		var spectrum_ids: Array = spectrum.keys()
		spectrum_ids.sort_custom(_element_precedes)
		for _copy in count:
			var total := total_base * craft_rng.randf_range(1.0 - sigma, 1.0 + sigma)
			var weights: Dictionary = {}
			var weight_sum := 0.0
			for element_id in spectrum_ids:
				var factor := craft_rng.randf_range(1.0 - sigma, 1.0 + sigma)
				var weight := float(spectrum[element_id]) * factor
				weights[element_id] = weight
				weight_sum += weight
			if weight_sum <= 0.0:
				continue
			for element_id in spectrum_ids:
				var amount := total * float(weights[element_id]) / weight_sum
				pool[element_id] = float(pool.get(element_id, 0.0)) + amount
	for mat_id in inputs:
		if not known.has(mat_id):
			push_error("CraftProcess: 未知材料 %s" % str(mat_id))
	return pool


func _element_precedes(a: Variant, b: Variant) -> bool:
	return _db.element_order(str(a)) < _db.element_order(str(b))


func _match_recipe(inputs: Dictionary, tier_id: String) -> Dictionary:
	for recipe_id in _db.recipe_ids():
		var recipe := _db.recipe(recipe_id)
		if str(recipe.get("temperature_tier", "")) != tier_id:
			continue
		var recipe_inputs: Dictionary = recipe.get("inputs", {})
		if _inputs_match(inputs, recipe_inputs):
			return {
				"duration": int(recipe.get("duration_minutes", 0)),
				"recipe_id": recipe_id,
			}
	return {
		"duration": int(_craft_minutes_by_tier.get(str(DEFAULT_TIER), 0)),
		"recipe_id": "",
	}


func _inputs_match(inputs: Dictionary, recipe_inputs: Dictionary) -> bool:
	if inputs.size() != recipe_inputs.size():
		return false
	for mat_id in recipe_inputs:
		if not inputs.has(mat_id):
			return false
		if int(inputs[mat_id]) != int(recipe_inputs[mat_id]):
			return false
	return true
