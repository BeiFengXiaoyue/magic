class_name Perception
extends RefCounted

## 感知通道（契约 02 §1.8）。引擎唯一允许直接调用的内核输出。
## M1 的陶土坩埚没有读数，readings 恒为空。

const STEAM_TIER_OFFSET := 2  # no-magic-ok: 契约 02 §1.8 规定的蒸气档位偏移
const DEFAULT_SPIRIT_TIER_MID := 4  # no-magic-ok: constants.perception 缺失时的兜底
const DEFAULT_SPIRIT_TIER_HIGH := 6  # no-magic-ok: 同上

var _db: ContentDatabase


func _init(db: ContentDatabase) -> void:
	_db = db


func describe(result: CraftResult, ctx: Dictionary) -> String:
	var spirit_total := int(ctx.get("spirit_total", 0))
	if result == null or result.dominant == "":
		return "一锅没有结合的东西，只有几缕未散的气味。"
	var dominant_name := _element_name(result.dominant)
	var tiers := _spirit_tiers()
	if spirit_total >= tiers.y:
		return "以%s为主，药性清晰可辨；边缘还有别的味道，但压不住它。" % dominant_name
	if spirit_total >= tiers.x:
		return "能看出以%s为主，还带着一点别的东西。" % dominant_name
	return "一炉温热的混合物。你隐约觉得它以%s为主。" % dominant_name


func readings(result: CraftResult, ctx: Dictionary) -> Dictionary:
	var device_id := str(ctx.get("device_id", ""))
	if device_id == "":
		return {}
	var device: Variant = _db.constant("device")
	if not device is Dictionary or not device.has(device_id):
		return {}
	var info: Variant = device[device_id]
	if not info is Dictionary or not bool(info.get("has_readout", false)):
		return {}
	var temperature_c := float(ctx.get("temperature_c", 0.0))
	var precision_c := float(info.get("readout_precision_c", 0.0))
	return { "temperature_c": temperature_c, "precision_c": precision_c }


func visual(state: Dictionary, ctx: Dictionary) -> Dictionary:
	var temperature_c := float(ctx.get("temperature_c", 0.0))
	var tiers: Variant = _db.constant("reaction.temperature_tiers")
	var index := 0
	if tiers is Array:
		for i in tiers.size():
			var tier: Dictionary = tiers[i]
			var range_c: Array = tier["range_c"]
			var low := float(range_c[0])
			var high := float(range_c[1])
			if temperature_c >= low and temperature_c < high:
				index = i
				break
			if temperature_c >= high:
				index = i
	return {
		"bubble_level": index,
		"steam_level": maxi(0, index - STEAM_TIER_OFFSET),
	}


func _element_name(element_id: String) -> String:
	if element_id == "":
		return ""
	var entry := _db.element(element_id)
	return str(entry.get("name", element_id))


func _spirit_tiers() -> Vector2i:
	var tiers: Variant = _db.constant("perception.spirit_tiers")
	if tiers is Dictionary:
		return Vector2i(
			int(tiers.get("mid", DEFAULT_SPIRIT_TIER_MID)),
			int(tiers.get("high", DEFAULT_SPIRIT_TIER_HIGH))
		)
	return Vector2i(DEFAULT_SPIRIT_TIER_MID, DEFAULT_SPIRIT_TIER_HIGH)
