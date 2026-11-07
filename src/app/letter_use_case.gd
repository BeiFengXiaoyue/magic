class_name LetterUseCase
extends RefCounted

## O4 · 读一封信（契约 05 §6.1）。
## 引擎只消费 list_view / letter_view / journal_view 与事件 payload。

var _db: ContentDatabase
var _letters: LetterBook
var _journal: Journal
var _spirituality: Spirituality
var _knowledge: Knowledge
var _publisher: CraftEventPublisher


func _init(
	db: ContentDatabase,
	letters: LetterBook,
	journal: Journal,
	spirituality: Spirituality,
	knowledge: Knowledge,
	publisher: CraftEventPublisher = null
) -> void:
	_db = db
	_letters = letters
	_journal = journal
	_spirituality = spirituality
	_knowledge = knowledge
	_publisher = publisher


func refresh() -> Array[String]:
	var delivered := _letters.refresh_arrivals()
	if not delivered.is_empty() and _publisher != null:
		_publisher.publish_mail_arrived(delivered)
		for id in delivered:
			_publisher.publish_letter(_letters.state(id))
	_publish_letters_state()
	return delivered


func open(id: String) -> Dictionary:
	var result := _letters.open(id)
	if bool(result.get("ok", false)):
		if _publisher != null:
			_publisher.publish_letter(_letters.state(id))
			_publisher.publish_spirit(_spirituality)
			_publisher.publish_knowledge(_knowledge)
			_publisher.publish_journal(_journal)
		refresh()
		result["view"] = letter_view(id)
	_publish_letters_state()
	return result


func list_view(source: String = "") -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for id in _letters.delivered_ids():
		var entry_data := _letters.entry(id)
		var arrival: Variant = entry_data.get("arrival", {})
		if source != "":
			if not arrival is Dictionary or str(arrival.get("delivery", "")) != source:
				continue
		var letter_state := _letters.state(id)
		var author: Variant = entry_data.get("author", {})
		var author_name := ""
		if author is Dictionary:
			author_name = str(author.get("name", ""))
		out.append({
			"id": id,
			"title": str(entry_data.get("title", "")),
			"author_name": author_name,
			"status": letter_state.status,
			"delivered_day": letter_state.delivered_day,
			"read_day": letter_state.read_day,
		})
	return out


func letter_view(id: String) -> Dictionary:
	var entry_data := _letters.entry(id)
	if entry_data.is_empty():
		return {}
	var letter_state := _letters.state(id)
	var author: Variant = entry_data.get("author", {})
	var author_name := ""
	if author is Dictionary:
		author_name = str(author.get("name", ""))
	var arrival: Variant = entry_data.get("arrival", {})
	var delivery := ""
	if arrival is Dictionary:
		delivery = str(arrival.get("delivery", ""))

	var unlocked_recipes: Array[Dictionary] = []
	var unlocked_concepts: Array[Dictionary] = []
	var unlocked_locations: Array[Dictionary] = []
	var notes: Array[String] = []
	var unlocks: Variant = entry_data.get("unlocks", {})
	if unlocks is Dictionary:
		for recipe_id in unlocks.get("recipes", []):
			var recipe := _db.recipe(str(recipe_id))
			unlocked_recipes.append({
				"id": str(recipe_id),
				"name": str(recipe.get("name", recipe_id)),
			})
		for concept_id in unlocks.get("concepts", []):
			unlocked_concepts.append({
				"id": str(concept_id),
				"name": _concept_name(str(concept_id)),
			})
		for location_id in unlocks.get("locations", []):
			var node := _db.node(str(location_id))
			unlocked_locations.append({
				"id": str(location_id),
				"name": str(node.get("name", location_id)),
			})
		for note in unlocks.get("notes", []):
			notes.append(str(note))

	return {
		"id": id,
		"title": str(entry_data.get("title", "")),
		"author_name": author_name,
		"body": str(entry_data.get("body", "")),
		"delivery": delivery,
		"status": letter_state.status,
		"delivered_day": letter_state.delivered_day,
		"read_day": letter_state.read_day,
		"unlocked_recipes": unlocked_recipes,
		"unlocked_concepts": unlocked_concepts,
		"unlocked_locations": unlocked_locations,
		"notes": notes,
	}


func journal_view(page: String) -> Dictionary:
	if page == "recipes":
		return { "recipes": _journal.recipes_view() }
	return {
		"records": _journal.records_view(),
		"locations": _journal.locations_view(),
		"notes": _journal.notes_view(),
		"format": _journal.record_format(),
	}


func _concept_name(concept_id: String) -> String:
	var concepts: Variant = _db.constant("concepts")
	if concepts is Dictionary and concepts.has(concept_id):
		return str(concepts[concept_id])
	return concept_id


func _publish_letters_state() -> void:
	if _publisher == null:
		return
	_publisher.publish_letters(_letters.delivered_ids().size(), _letters.unread_ids().size())
