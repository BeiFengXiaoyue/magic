class_name LetterBook
extends RefCounted

## 信件到达与阅读（契约 05 §5.2）。
## 只依赖 core；不碰 UI、不碰引擎。

var _db: ContentDatabase
var _clock: GameClock
var _flags: Flags
var _knowledge: Knowledge
var _spirituality: Spirituality
var _journal: Journal
var _states: Dictionary = {}


func _init(
	db: ContentDatabase,
	clock: GameClock,
	flags: Flags,
	knowledge: Knowledge,
	spirituality: Spirituality,
	journal: Journal
) -> void:
	_db = db
	_clock = clock
	_flags = flags
	_knowledge = knowledge
	_spirituality = spirituality
	_journal = journal
	for id in _db.letter_ids():
		_states[id] = LetterState.new(id)


func entry(id: String) -> Dictionary:
	return _db.letter(id)


func state(id: String) -> LetterState:
	if _states.has(id):
		return _states[id]
	return LetterState.new(id)


func delivered_ids() -> Array[String]:
	var out: Array[String] = []
	for id in _db.letter_ids():
		if state(id).status != "pending":
			out.append(id)
	return out


func unread_ids() -> Array[String]:
	var out: Array[String] = []
	for id in _db.letter_ids():
		if state(id).is_unread():
			out.append(id)
	return out


func is_delivered(id: String) -> bool:
	return state(id).status != "pending"


func refresh_arrivals() -> Array[String]:
	var delivered: Array[String] = []
	for id in _db.letter_ids():
		var letter_state := state(id)
		if letter_state.status != "pending":
			continue
		var entry_data := entry(id)
		var arrival: Variant = entry_data.get("arrival", null)
		if not arrival is Dictionary:
			continue
		var conditions: Variant = arrival.get("conditions", null)
		if not conditions is Dictionary:
			continue
		if not _conditions_met(conditions):
			continue
		letter_state.status = "delivered"
		letter_state.delivered_day = _clock.today()
		delivered.append(id)
	return delivered


func open(id: String) -> Dictionary:
	if not _db.has_letter(id):
		return {"ok": false, "reason": "unknown", "letter": {}, "unlocks": {}, "award": ""}
	var letter_state := state(id)
	if letter_state.status == "pending":
		return {"ok": false, "reason": "not_delivered", "letter": {}, "unlocks": {}, "award": ""}

	var entry_data := entry(id)
	if letter_state.status != "read":
		letter_state.status = "read"
		letter_state.read_day = _clock.today()

	var unlocks: Variant = entry_data.get("unlocks", {})
	_apply_unlocks(id, unlocks)

	var award := ""
	var spirituality: Variant = entry_data.get("spirituality", null)
	if spirituality is Dictionary and not bool(letter_state.awards.get("read", false)):
		var on_read: Variant = spirituality.get("on_read", null)
		if on_read is String and str(on_read) != "":
			_spirituality.apply_source(str(on_read))
			letter_state.awards["read"] = true
			award = str(on_read)

	return {
		"ok": true,
		"reason": "ok",
		"letter": entry_data,
		"unlocks": unlocks,
		"award": award,
	}


func snapshot() -> Dictionary:
	var out: Dictionary = {}
	for id in _states:
		var letter_state: LetterState = _states[id]
		if letter_state.status != "pending":
			out[id] = letter_state.snapshot()
	return out


func restore(snapshot: Dictionary) -> void:
	for id in _states:
		_states[id] = LetterState.new(id)
	for id in snapshot:
		if not _states.has(id):
			continue
		var data: Variant = snapshot[id]
		if data is Dictionary:
			_states[id].restore(data)


func _apply_unlocks(letter_id: String, unlocks: Variant) -> void:
	if not unlocks is Dictionary:
		return
	for recipe_id in _as_strings(unlocks.get("recipes", [])):
		_knowledge.unlock("recipe", recipe_id)
	for concept_id in _as_strings(unlocks.get("concepts", [])):
		_knowledge.unlock("concept", concept_id)
	for location_id in _as_strings(unlocks.get("locations", [])):
		_knowledge.unlock("location", location_id)
	for flag_id in _as_strings(unlocks.get("flags", [])):
		_flags.set_flag(flag_id)
	for note in _as_strings(unlocks.get("notes", [])):
		_journal.add_note(note, letter_id)


func _as_strings(value: Variant) -> Array[String]:
	var out: Array[String] = []
	if value is Array:
		for item in value:
			out.append(str(item))
	return out


func _conditions_met(conditions: Dictionary) -> bool:
	if conditions.has("all"):
		var all_conditions: Variant = conditions.get("all", [])
		if not all_conditions is Array:
			return false
		for condition in all_conditions:
			if not _condition_met(condition):
				return false
		return true
	if conditions.has("any"):
		var any_conditions: Variant = conditions.get("any", [])
		if not any_conditions is Array:
			return false
		for condition in any_conditions:
			if _condition_met(condition):
				return true
		return false
	return false


func _condition_met(condition: Variant) -> bool:
	if not condition is Dictionary:
		return false
	var value: Dictionary = condition
	match str(value.get("type", "")):
		"day":
			return _clock.today() >= int(value.get("min", 1))
		"after_letter":
			return state(str(value.get("id", ""))).status == "read"
		"flag":
			return _flags.has(str(value.get("id", "")))
		"knowledge":
			return _knowledge.has(str(value.get("kind", "")), str(value.get("id", "")))
	return false
