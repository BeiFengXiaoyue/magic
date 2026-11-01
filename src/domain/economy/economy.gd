class_name Economy
extends RefCounted

## D2 经济最小集（契约 02 §2.2）。
## coverage 不需要内容库，保持 static；cost_of / list_price 需要配方与 constants，故为实例方法。

var _db: ContentDatabase


func _init(db: ContentDatabase) -> void:
	_db = db


static func coverage(reading: Dictionary, demand: Dictionary) -> float:
	var needs: Dictionary = demand.get("needs", {})
	var effects: Dictionary = reading.get("effects", {})
	var total := 0.0
	var covered := 0.0
	for effect_id in needs:
		var need := float(needs[effect_id])
		if need <= 0.0:
			continue
		total += need
		covered += minf(float(effects.get(effect_id, 0.0)), need)
	if total <= 0.0:
		return 0.0
	return covered / total


func cost_of(product: ProductInstance) -> int:
	if product == null or product.recipe_id == "":
		return 0
	var recipe := _db.recipe(product.recipe_id)
	var inputs: Dictionary = recipe.get("inputs", {})
	var cost := 0
	for mat_id in inputs:
		var material := _db.material(str(mat_id))
		cost += int(material.get("price", 0)) * int(inputs[mat_id])
	return cost


func list_price(product: ProductInstance, demand: Dictionary, ctx: Dictionary) -> int:
	if product == null or product.result == null:
		return 0

	var match_ratio := coverage(product.result.reading, demand)
	var normal_threshold := float(_db.constant("matching.normal_threshold"))
	if match_ratio < normal_threshold:
		return 0

	var base_price := _base_price(product)
	var season := int(ctx.get("season", 0))
	var season_mult_table: Dictionary = _db.constant("pricing.season_mult")
	var season_mult := float(season_mult_table.get(str(season), 1.0))
	var rolling_q := int(ctx.get("rolling_q", 0))
	var q_th := maxi(1, int(ctx.get("q_th", 1)))
	var elasticity := float(_db.constant("pricing.elasticity"))
	var over := maxf(0.0, float(rolling_q) / float(q_th) - 1.0)
	var raw := float(base_price) * season_mult * match_ratio * (1.0 - elasticity * over)

	var cost := float(cost_of(product))
	var minimum := cost * float(_db.constant("pricing.p_floor_mult"))
	var maximum := float(base_price) * float(_db.constant("pricing.p_cap_mult"))
	return int(round(clampf(raw, minimum, maximum)))


func _base_price(product: ProductInstance) -> float:
	if product.recipe_id != "":
		var recipe := _db.recipe(product.recipe_id)
		if recipe.has("base_price"):
			return float(recipe["base_price"])
	return float(_db.constant("pricing.mixture_base_price"))
