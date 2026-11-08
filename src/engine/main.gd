extends Control

## M2 组装根：场景、HUD、坩埚覆盖面板、小店柜台、时间驱动与事件接线。
## 业务规则在 core / domain / app；这里只决定“谁连谁”。

const MARGIN := 16
const PANEL_SEPARATION := 8
const DEFAULT_TIER := "t_low_flame"
const ADD_COUNT := 1
const MINUTES_PER_HOUR := 60.0
const TIME_FORMAT := "%02d:%02d · %s"
const CRUCIBLE_PANEL_SIZE := Vector2(1180.0, 680.0)
const SHOP_PANEL_SIZE := Vector2(660.0, 420.0)
const UI_LAYER := 10

var _db: ContentDatabase
var _rng: DeterministicRng
var _clock: GameClock
var _inventory: Inventory
var _craft_process: CraftProcess
var _perception: Perception
var _publisher: CraftEventPublisher
var _use_case: CraftUseCase
var _time_driver: GameTimeDriver
var _character: CharacterState
var _wallet: Wallet
var _gather_process: GatherProcess
var _economy: Economy
var _gather: GatherUseCase
var _wild_spawner: WildSpawner
var _sell: SellUseCase
var _interact: InteractUseCase
var _flags: Flags
var _knowledge: Knowledge
var _spirituality: Spirituality
var _journal: Journal
var _letters: LetterBook
var _letter_use_case: LetterUseCase
var _day_use_case: DayUseCase

var _world: WorldView
var _ui_layer: CanvasLayer
var _ui_root: Control
var _hud: GameHud
var _shelf: MaterialShelf
var _crucible: CruciblePanel
var _observation: ObservationPanel
var _shop: ShopPanel
var _letter_panel: LetterPanel
var _journal_panel: JournalPanel
var _menu_panel: MenuPanel
var _crucible_overlay: CenterContainer
var _shop_overlay: CenterContainer
var _letter_overlay: CenterContainer
var _journal_overlay: CenterContainer
var _menu_overlay: CenterContainer
var _letter_source: String = ""
var _message_log: Array[String] = []

var _pending_inputs: Dictionary = {}
var _pending_tier: String = DEFAULT_TIER
var _active: bool = false
var _active_inputs: Dictionary = {}
var _progress: float = 0.0


func _ready() -> void:
	theme = UiTheme.create()
	_build_world_ui()
	_load_content()
	if _db == null or not _db.errors.is_empty():
		_notify("内容载入失败，见控制台。")
		return
	_hud.configure(_db)
	_assemble()
	_connect_signals()
	_start_scene()
	_refresh_all()
	_letter_use_case.refresh()
	_notify("锅是冷的。先看看那只旧木箱。")


func _process(delta: float) -> void:
	if _time_driver == null:
		return
	_time_driver.advance_real(delta)
	_hud.set_time(_time_text())
	_hud.set_date(_date_text())
	if _observation.is_debug_visible():
		_observation.set_debug(_debug_text())


func _unhandled_input(event: InputEvent) -> void:
	if not event is InputEventKey:
		return
	var key_event := event as InputEventKey
	if not key_event.pressed or key_event.echo:
		return
	if key_event.keycode == KEY_T and _time_driver != null:
		_time_driver.cycle_scale()
		_hud.set_time(_time_text())
	elif key_event.keycode == KEY_H:
		_observation.toggle_debug()
		_observation.set_debug(_debug_text())
	elif key_event.keycode == KEY_B:
		var enabled := _world.toggle_debug_zones()
		_notify("布点模式：%s" % ("开" if enabled else "关"))
	elif key_event.keycode == KEY_I:
		_open_menu("items")
	elif key_event.keycode == KEY_J:
		_open_journal("records")
	elif key_event.keycode == KEY_ESCAPE:
		_close_panels()


func _build_world_ui() -> void:
	_world = WorldView.new()
	_world.y_sort_enabled = true
	add_child(_world)

	_ui_layer = CanvasLayer.new()
	_ui_layer.layer = UI_LAYER
	add_child(_ui_layer)

	_ui_root = Control.new()
	_ui_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_ui_root.theme = theme
	_ui_layer.add_child(_ui_root)
	_ui_root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	_hud = GameHud.new()
	_ui_root.add_child(_hud)
	_hud.setup()


func _load_content() -> void:
	_db = ContentDatabase.new()
	_db.load_all()
	_build_panels()


func _build_panels() -> void:
	_crucible_overlay = _make_overlay()
	var frame := PanelContainer.new()
	frame.custom_minimum_size = CRUCIBLE_PANEL_SIZE
	var box := VBoxContainer.new()
	var header := HBoxContainer.new()
	header.add_child(UiTheme.title("炼药工坊"))
	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(spacer)
	var close_button := Button.new()
	close_button.text = "关闭"
	close_button.pressed.connect(_close_panels)
	header.add_child(close_button)
	box.add_child(header)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", PANEL_SEPARATION)
	box.add_child(row)
	_shelf = MaterialShelf.new()
	row.add_child(_shelf)
	_crucible = CruciblePanel.new()
	_crucible.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(_crucible)
	_observation = ObservationPanel.new()
	row.add_child(_observation)
	frame.add_child(box)
	_crucible_overlay.add_child(frame)
	_shelf.setup(_db)
	_crucible.setup(_db, DEFAULT_TIER)
	_observation.setup()

	_shop_overlay = _make_overlay()
	var shop_frame := PanelContainer.new()
	shop_frame.custom_minimum_size = SHOP_PANEL_SIZE
	_shop = ShopPanel.new()
	_shop.setup()
	shop_frame.add_child(_shop)
	_shop_overlay.add_child(shop_frame)

	_letter_overlay = _make_overlay()
	var letter_frame := PanelContainer.new()
	letter_frame.custom_minimum_size = Vector2(1000.0, 640.0)
	letter_frame.add_theme_stylebox_override("panel", UiTheme.paper_style())
	_letter_panel = LetterPanel.new()
	_letter_panel.setup()
	_letter_panel.letter_selected.connect(_on_letter_selected)
	_letter_panel.close_requested.connect(_close_panels)
	letter_frame.add_child(_letter_panel)
	_letter_overlay.add_child(letter_frame)

	_journal_overlay = _make_overlay()
	var journal_frame := PanelContainer.new()
	journal_frame.custom_minimum_size = Vector2(920.0, 640.0)
	journal_frame.add_theme_stylebox_override("panel", UiTheme.paper_style())
	_journal_panel = JournalPanel.new()
	_journal_panel.setup()
	_journal_panel.close_requested.connect(_close_panels)
	journal_frame.add_child(_journal_panel)
	_journal_overlay.add_child(journal_frame)

	_menu_overlay = _make_overlay()
	var menu_frame := PanelContainer.new()
	menu_frame.custom_minimum_size = Vector2(940.0, 660.0)
	menu_frame.add_theme_stylebox_override("panel", UiTheme.paper_style())
	_menu_panel = MenuPanel.new()
	_menu_panel.setup()
	_menu_panel.close_requested.connect(_close_panels)
	_menu_panel.letter_selected.connect(_on_menu_letter_selected)
	menu_frame.add_child(_menu_panel)
	_menu_overlay.add_child(menu_frame)


func _make_overlay() -> CenterContainer:
	var overlay := CenterContainer.new()
	overlay.z_index = 20
	overlay.visible = false
	overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	_ui_root.add_child(overlay)
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	return overlay


func _assemble() -> void:
	_rng = DeterministicRng.new()
	_rng.init_world(int(_db.constant("demo.world_seed")))
	_clock = GameClock.new(_db)
	_inventory = Inventory.new()
	var starting: Dictionary = _db.constant("demo.starting_inventory")
	for mat_id in starting:
		_inventory.add_material(str(mat_id), int(starting[mat_id]))
	_character = CharacterState.new(_db)
	_wallet = Wallet.new()
	_flags = Flags.new()
	_knowledge = Knowledge.new()
	_spirituality = Spirituality.new(_db)
	_perception = Perception.new(_db)
	_journal = Journal.new(_db, _knowledge, _perception)

	var solver := ReactionSolver.new(_db)
	_craft_process = CraftProcess.new(_db, _rng, solver)
	_gather_process = GatherProcess.new(_db)
	_economy = Economy.new(_db)
	_publisher = CraftEventPublisher.new(Events, _perception)
	_use_case = CraftUseCase.new(
		_db, _clock, _inventory, _craft_process, _publisher, _journal, _spirituality
	)
	_wild_spawner = WildSpawner.new(_db, _rng)
	_gather = GatherUseCase.new(_db, _gather_process, _inventory, _character, _clock, _rng, _wild_spawner, _publisher)
	_sell = SellUseCase.new(_db, _economy, _inventory, _wallet, _clock, _publisher, _flags)
	_interact = InteractUseCase.new(_publisher, _gather, _flags)
	_letters = LetterBook.new(_db, _clock, _flags, _knowledge, _spirituality, _journal)
	_letter_use_case = LetterUseCase.new(_db, _letters, _journal, _spirituality, _knowledge, _publisher)
	_day_use_case = DayUseCase.new(_spirituality, _letter_use_case)
	_clock.day_passed.connect(_on_day_passed)
	_time_driver = GameTimeDriver.new(_db, _use_case)


func _connect_signals() -> void:
	Events.action_requested.connect(_on_action_requested)
	Events.state_changed.connect(_on_state_changed)
	Events.cue_requested.connect(_on_cue_requested)
	Events.panel_requested.connect(_on_panel_requested)
	_world.interact_requested.connect(_on_world_interact)
	_world.hint_changed.connect(_hud.set_hint)
	_shelf.material_selected.connect(_on_material_selected)
	_crucible.tier_selected.connect(_on_tier_selected)
	_crucible.start_pressed.connect(_on_start_pressed)
	_crucible.take_out_pressed.connect(_on_take_out_pressed)
	_shop.sell_requested.connect(_on_sell_requested)
	_shop.close_requested.connect(_close_panels)


func _start_scene() -> void:
	_world.setup(_db)
	_change_scene(SceneLayout.WORKSHOP)


func _change_scene(scene_id: String) -> void:
	if scene_id == "" or _world == null:
		return
	_world.change_scene(scene_id)
	_hud.set_scene(_scene_name(scene_id))
	if _gather != null:
		_world.set_node_availability(_gather.unavailable_ids())
	_refresh_wild_view(scene_id)
	_close_panels()


func _scene_name(scene_id: String) -> String:
	if scene_id == SceneLayout.WORKSHOP:
		return "炼药工坊"
	if scene_id == SceneLayout.SHOP:
		return "小店"
	if scene_id == SceneLayout.FOREST:
		return "晨暮森林"
	return scene_id


func _on_world_interact(target_id: String) -> void:
	Events.action_requested.emit("interact", { "target_id": target_id })


func _on_material_selected(mat_id: String) -> void:
	Events.action_requested.emit("crucible_add", { "mat_id": mat_id, "count": ADD_COUNT })


func _on_tier_selected(tier_id: String) -> void:
	Events.action_requested.emit("crucible_set_tier", { "tier_id": tier_id })


func _on_start_pressed() -> void:
	Events.action_requested.emit("crucible_start", {})


func _on_take_out_pressed() -> void:
	Events.action_requested.emit("crucible_take_out", {})


func _on_sell_requested(product_index: int) -> void:
	Events.action_requested.emit("sell_product", { "product_index": product_index })


func _on_action_requested(action: String, payload: Dictionary) -> void:
	if _use_case == null:
		return
	match action:
		"interact":
			_handle_interact(payload)
		"scene_change":
			_interact.handle_scene_change(str(payload.get("scene_id", "")))
		"gather_node":
			_gather_and_report(str(payload.get("node_id", "")))
		"sell_product":
			_sell_product(int(payload.get("product_index", 0)))
		"crucible_add":
			_add_material(payload)
		"crucible_remove":
			_remove_material(payload)
		"crucible_set_tier":
			_set_tier(str(payload.get("tier_id", "")))
		"crucible_start":
			_start()
		"crucible_take_out":
			_take_out()
		"letter_open":
			_on_letter_selected(str(payload.get("letter_id", "")))
		"journal_open":
			_open_journal(str(payload.get("page", "records")))
		_:
			_notify("未知操作：%s" % action)


func _handle_interact(payload: Dictionary) -> void:
	var target_id := str(payload.get("target_id", ""))
	if target_id == "" or _interact == null:
		return
	var result := _interact.handle(target_id)
	if result.has("success"):
		_notify(_gather_text(result))
	elif str(result.get("kind", "")) == "message":
		_notify(str(result.get("message", "")))


func _gather_and_report(node_id: String) -> void:
	if _gather == null:
		return
	_notify(_gather_text(_gather.gather(node_id)))


func _gather_text(result: Dictionary) -> String:
	var reason := str(result.get("reason", ""))
	if reason == "ok":
		var material := _db.material(str(result.get("material_id", "")))
		return "采到 %d 份%s。" % [int(result.get("count", 0)), str(material.get("name", "材料"))]
	if reason == "miss":
		return "空手而归。"
	if reason == "regrowing":
		return "这里还没长回来。"
	if reason == "unknown_node":
		return "这里没有可采的东西。"
	return ""


func _sell_product(product_index: int) -> void:
	if _sell == null:
		return
	var result := _sell.sell(product_index)
	_refresh_shop()
	if bool(result.get("sold", false)):
		_shop.set_status("卖出，获得 %d 金币。" % int(result.get("price", 0)))
		if _letter_use_case != null:
			_letter_use_case.refresh()
	elif str(result.get("reason", "")) == "no_demand":
		_shop.set_status("卖不掉：需求覆盖不足。")
	else:
		_shop.set_status("这瓶不能卖。")


func _on_panel_requested(panel: String, params: Dictionary) -> void:
	match panel:
		"crucible":
			_open_crucible()
		"shop":
			_open_shop()
		"letters":
			_open_letters(str(params.get("source", "")))
		"journal":
			_open_journal(str(params.get("page", "records")))


func _open_crucible() -> void:
	_hud.visible = false
	_crucible_overlay.visible = true
	_shop_overlay.visible = false
	_world.set_input_enabled(false)
	_refresh_pending()
	_crucible.select_tier(_pending_tier)
	if _active:
		_crucible.set_status("平衡完成，可以取出。" if _progress >= 1.0 else "炼制中……")
	else:
		_crucible.set_status("投料，选火候，然后点火。")


func _open_shop() -> void:
	_hud.visible = false
	_crucible_overlay.visible = false
	_shop_overlay.visible = true
	_world.set_input_enabled(false)
	_refresh_shop()
	_shop.set_status("")


func _close_panels() -> void:
	if _crucible_overlay != null:
		_crucible_overlay.visible = false
	if _shop_overlay != null:
		_shop_overlay.visible = false
	if _letter_overlay != null:
		_letter_overlay.visible = false
	if _journal_overlay != null:
		_journal_overlay.visible = false
	if _menu_overlay != null:
		_menu_overlay.visible = false
	if _hud != null:
		_hud.visible = true
	if _world != null:
		_world.set_input_enabled(true)


func _open_letters(source: String) -> void:
	_hud.visible = false
	if _letter_use_case == null:
		return
	_letter_source = source
	_letter_overlay.visible = true
	_crucible_overlay.visible = false
	_shop_overlay.visible = false
	_journal_overlay.visible = false
	_world.set_input_enabled(false)
	_letter_panel.set_status("")
	_refresh_letter_list()


func _refresh_letter_list() -> void:
	if _letter_use_case == null:
		return
	_letter_panel.show_list(_letter_use_case.list_view(_letter_source))


func _on_letter_selected(letter_id: String) -> void:
	if _letter_use_case == null or letter_id == "":
		return
	var result := _letter_use_case.open(letter_id)
	if bool(result.get("ok", false)):
		_letter_panel.show_letter(result.get("view", {}))
		_hud.set_mail(_letters.unread_ids().size())


func _open_journal(page: String) -> void:
	_hud.visible = false
	if _letter_use_case == null:
		return
	_journal_overlay.visible = true
	_crucible_overlay.visible = false
	_shop_overlay.visible = false
	_letter_overlay.visible = false
	_world.set_input_enabled(false)
	_refresh_journal()
	_journal_panel.show_page(page)


func _refresh_journal() -> void:
	if _letter_use_case == null:
		return
	var recipes_view := _letter_use_case.journal_view("recipes")
	_journal_panel.refresh_recipes(recipes_view.get("recipes", []))
	_journal_panel.refresh_records(_letter_use_case.journal_view("records"))

func _open_menu(page: String = "items") -> void:
	_hud.visible = false
	if _menu_panel == null:
		return
	_menu_overlay.visible = true
	_crucible_overlay.visible = false
	_shop_overlay.visible = false
	_letter_overlay.visible = false
	_journal_overlay.visible = false
	_world.set_input_enabled(false)
	_refresh_menu()
	_menu_panel.show_page(page)


func _refresh_menu() -> void:
	if _menu_panel == null:
		return
	var items: Array[Dictionary] = []
	for material_id in _inventory.materials:
		var count := int(_inventory.materials[material_id])
		if count <= 0:
			continue
		var material := _db.material(str(material_id))
		items.append({
			"art_id": str(material.get("art_id", "")),
			"name": str(material.get("name", material_id)),
			"count": count,
		})
	for index in _inventory.products.size():
		var product := _inventory.product_at(index)
		if product == null:
			continue
		var display := product.display_name()
		if product.recipe_id != "":
			display = str(_db.recipe(product.recipe_id).get("name", display))
		items.append({
			"art_id": "art_ui_icon_potion",
			"name": display,
			"count": 1,
		})
	var letters: Array[Dictionary] = []
	if _letter_use_case != null:
		letters = _letter_use_case.list_view("")
	var unread := _letters.unread_ids().size() if _letters != null else 0
	_menu_panel.refresh({
		"items": items,
		"letters": letters,
		"messages": _message_log.duplicate(),
		"demand_short": _demand_text(),
		"demand_detail": _demand_detail_text(),
		"info": {
			"location": _scene_name(_world.current_scene()),
			"date": _date_text(),
			"time": _time_text(),
			"hp": _character.hp,
			"sanity": _character.sanity,
			"gold": _wallet.gold,
			"unread": unread,
		},
	})


func _on_menu_letter_selected(letter_id: String) -> void:
	if _letter_use_case == null or letter_id == "":
		return
	var result := _letter_use_case.open(letter_id)
	if bool(result.get("ok", false)):
		_menu_panel.show_letter(result.get("view", {}))
		_refresh_menu()


func _demand_detail_text() -> String:
	var demand: Dictionary = _db.constant("demand.spring_early")
	var needs: Dictionary = demand.get("needs", {})
	var vocabulary: Dictionary = _db.constant("vocabulary.effects")
	var lines: Array[String] = []
	lines.append("[b]%s[/b]" % str(demand.get("name", "")))
	for effect_id in needs:
		lines.append("· %s：%.2f" % [
			str(vocabulary.get(effect_id, effect_id)),
			float(needs[effect_id]),
		])
	var days: Array = demand.get("days", [])
	var day_parts: Array[String] = []
	for day in days:
		day_parts.append(str(day))
	lines.append("有效期：第 %s 天" % "–".join(day_parts))
	lines.append("覆盖率低于 0.50 时，小店不会收。")
	return "
".join(lines)


func _notify(text: String) -> void:
	if text == "":
		return
	_message_log.append(text)
	while _message_log.size() > 10:
		_message_log.pop_front()
	if _menu_overlay != null and _menu_overlay.visible:
		_refresh_menu()


func _on_day_passed(day: int, season: int, year: int) -> void:
	if _day_use_case == null:
		return
	_day_use_case.on_day_passed(day, season, year)
	_hud.set_time(_time_text())


func _refresh_shop() -> void:
	if _shop == null or _sell == null:
		return
	var view: Array[Dictionary] = []
	for index in _inventory.products.size():
		var product := _inventory.product_at(index)
		if product == null:
			continue
		var quote := _sell.quote(index)
		var display := product.display_name()
		if product.recipe_id != "":
			display = str(_db.recipe(product.recipe_id).get("name", display))
		view.append({
			"index": index,
			"name": display,
			"coverage": float(quote.get("coverage", 0.0)),
			"price": int(quote.get("price", 0)),
			"can_sell": bool(quote.get("can_sell", false)),
		})
	_shop.refresh(view, _demand_text())


func _add_material(payload: Dictionary) -> void:
	if _active:
		return
	var mat_id := str(payload.get("mat_id", ""))
	var count := int(payload.get("count", ADD_COUNT))
	var current := int(_pending_inputs.get(mat_id, 0))
	var available := _inventory.count_material(mat_id) - current
	if available <= 0:
		_notify("库存不足。")
		return
	_pending_inputs[mat_id] = current + mini(count, available)
	_refresh_pending()


func _remove_material(payload: Dictionary) -> void:
	if _active:
		return
	var mat_id := str(payload.get("mat_id", ""))
	var count := int(payload.get("count", ADD_COUNT))
	var current := int(_pending_inputs.get(mat_id, 0))
	if current <= 0:
		return
	var remaining := current - count
	if remaining <= 0:
		_pending_inputs.erase(mat_id)
	else:
		_pending_inputs[mat_id] = remaining
	_refresh_pending()


func _set_tier(tier_id: String) -> void:
	if tier_id == "":
		return
	if _active and _progress >= 1.0:
		return
	_pending_tier = tier_id
	if _active:
		_use_case.set_tier(tier_id)
	_crucible.select_tier(tier_id)


func _start() -> void:
	if _active:
		return
	if _pending_inputs.is_empty():
		_notify("先投料。")
		return
	var session_id := _use_case.begin(_pending_inputs, _pending_tier)
	if session_id == "":
		_notify("材料不足，或上一炉还没取出。")
		return
	_pending_inputs.clear()
	_crucible.set_status("炼制中……")
	_notify("炼制中……")
	_refresh_pending()


func _take_out() -> void:
	if not _active:
		return
	var result := _use_case.take_out()
	if result == null:
		_notify("还没到平衡，再等等。")
		return
	_observation.set_observation(_perception.describe(result, { "spirit_total": 0 }))
	_crucible.set_status("取出成功。")
	_notify("取出成功。去小店的柜台卖卖看。")


func _on_state_changed(scope: String, payload: Dictionary) -> void:
	match scope:
		"inventory":
			_shelf.refresh(_inventory, _active)
			if _shop_overlay != null and _shop_overlay.visible:
				_refresh_shop()
			if _menu_overlay != null and _menu_overlay.visible:
				_refresh_menu()
		"player":
			_hud.set_player(int(payload.get("hp", 0)), int(payload.get("sanity", 0)))
		"money":
			_hud.set_money(int(payload.get("gold", 0)))
			if _menu_overlay != null and _menu_overlay.visible:
				_refresh_menu()
		"letters":
			_hud.set_mail(int(payload.get("unread", 0)))
		"knowledge", "journal":
			if _journal_overlay != null and _journal_overlay.visible:
				_refresh_journal()
		"nodes":
			_world.set_node_availability(_as_string_array(payload.get("unavailable", [])))
		"wild":
			if str(payload.get("scene_id", "")) == _world.current_scene():
				_world.set_wild_nodes(_as_dictionary_array(payload.get("nodes", [])))
		"crucible":
			var was_active := _active
			_active = bool(payload.get("active", false))
			_progress = float(payload.get("progress", 0.0))
			if _active:
				var inputs_view: Dictionary = payload.get("inputs", {})
				_active_inputs = inputs_view.duplicate()
				_pending_tier = str(payload.get("tier_id", _pending_tier))
			else:
				_active_inputs.clear()
			if was_active != _active:
				_shelf.refresh(_inventory, _active)
			_refresh_pending()
			if _active:
				_crucible.set_status("平衡完成，可以取出。" if _progress >= 1.0 else "炼制中……")
			elif was_active:
				_crucible.set_status("投料，选火候，然后点火。")


func _on_cue_requested(cue: String, params: Dictionary) -> void:
	match cue:
		"bubbles":
			_crucible.set_bubbles(
				int(params.get("bubble_level", 0)),
				int(params.get("steam_level", 0))
			)
		"scene":
			_change_scene(str(params.get("scene_id", "")))
		"mail_arrived":
			_notify("门口有新的信。")


func _refresh_all() -> void:
	_shelf.refresh(_inventory, _active)
	_refresh_pending()
	_crucible.select_tier(_pending_tier)
	_observation.set_time(_time_text())
	_hud.set_time(_time_text())
	_hud.set_date(_date_text())
	_hud.set_player(_character.hp, _character.sanity)
	_hud.set_money(_wallet.gold)
	_hud.set_mail(_letters.unread_ids().size() if _letters != null else 0)


func _refresh_wild_view(scene_id: String) -> void:
	if _world == null or _gather == null:
		return
	if scene_id == SceneLayout.FOREST:
		_world.set_wild_nodes(_gather.wild_nodes(scene_id))
	else:
		var empty: Array[Dictionary] = []
		_world.set_wild_nodes(empty)


func _refresh_pending() -> void:
	var view: Dictionary = _active_inputs if _active else _pending_inputs
	_crucible.refresh(_active, _progress, view, not _pending_inputs.is_empty())


func _time_text() -> String:
	if _clock == null or _time_driver == null:
		return ""
	var hour := _clock.current_hour()
	var whole_hour := int(hour)
	var minute := int((hour - float(whole_hour)) * MINUTES_PER_HOUR)
	return TIME_FORMAT % [whole_hour, minute, _time_driver.scale_label()]


func _date_text() -> String:
	if _clock == null:
		return ""
	var weekdays: Array[String] = [
		"星期一", "星期二", "星期三", "星期四", "星期五", "星期六", "星期日",
	]
	var index := (_clock.today() - 1) % weekdays.size()
	return "%d日 · %s" % [_clock.day, weekdays[index]]


func _demand_text() -> String:
	var demand: Dictionary = _db.constant("demand.spring_early")
	var needs: Dictionary = demand.get("needs", {})
	var vocabulary: Dictionary = _db.constant("vocabulary.effects")
	var parts: Array[String] = []
	for effect_id in needs:
		parts.append("%s %.1f" % [str(vocabulary.get(effect_id, effect_id)), float(needs[effect_id])])
	return "需求：%s（%s）" % [str(demand.get("name", "")), "、".join(parts)]


func _debug_text() -> String:
	if _use_case == null:
		return ""
	return JSON.stringify(_use_case.debug_snapshot(), "  ")


func _as_string_array(value: Variant) -> Array[String]:
	var out: Array[String] = []
	if value is Array:
		for item in value:
			out.append(str(item))
	return out


func _as_dictionary_array(value: Variant) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	if value is Array:
		for item in value:
			if item is Dictionary:
				out.append(item)
	return out
