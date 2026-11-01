class_name GatherProcess
extends ProcessEngine

## 采集过程（契约 02 §2.1 实例二）。
## 空手率 = 基础率(tier) × 工具修正 × (1 + 天气项)；成功/空手理智同耗。

var _db: ContentDatabase


func _init(db: ContentDatabase) -> void:
	_db = db


func attempt(node: Dictionary, tool_id: String, rng: DeterministicRng) -> Dictionary:
	var tier := int(node.get("tier", 1))
	var base_rates: Dictionary = _db.constant("gathering.base_miss_rate_by_tier")
	var base_rate := float(base_rates.get(str(tier), 0.0))
	var tool_mods: Dictionary = _db.constant("gathering.tool_modifier")
	var tool_mod := float(tool_mods.get(tool_id, 1.0))
	var weather := float(_db.constant("gathering.weather_term"))
	var miss_rate := clampf(base_rate * tool_mod * (1.0 + weather), 0.0, 1.0)

	var gather_rng := rng.stream("gather")
	var success := gather_rng.randf() >= miss_rate

	var sanity_costs: Dictionary = _db.constant("gathering.sanity_cost_by_tier")
	var sanity_cost := int(sanity_costs.get(str(tier), 0))
	var minutes_table: Dictionary = _db.constant("gathering.minutes")
	var action := str(node.get("action", "gather"))

	return {
		"success": success,
		"material_id": str(node.get("material_id", "")),
		"count": int(node.get("amount", 0)) if success else 0,
		"sanity_cost": sanity_cost,
		"minutes": int(minutes_table.get(action, 0)),
	}
