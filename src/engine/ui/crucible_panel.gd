class_name CruciblePanel
extends VBoxContainer

## 中间坩埚面板：投料显示、火候、进度、气泡、开始/取出。
## 只发信号，不调用用例。

signal tier_selected(tier_id: String)
signal start_pressed
signal take_out_pressed

const PROGRESS_MAX := 100.0
const BUBBLE_MIN_WIDTH := 480.0
const BUBBLE_MIN_HEIGHT := 260.0
const SEPARATION := 8

var _db: ContentDatabase
var _tier_buttons: Dictionary = {}
var _pending_label: Label
var _progress: ProgressBar
var _bubble: BubbleView
var _start_button: Button
var _take_button: Button
var _status_label: Label


func setup(db: ContentDatabase, default_tier: String) -> void:
	_db = db
	add_theme_constant_override("separation", SEPARATION)
	add_child(UiTheme.title("坩埚"))
	_pending_label = UiTheme.label("尚未投料")
	add_child(_pending_label)
	add_child(UiTheme.label("火候"))

	var tier_row := HBoxContainer.new()
	tier_row.add_theme_constant_override("separation", SEPARATION)
	add_child(tier_row)
	var group := ButtonGroup.new()
	var tiers: Variant = db.constant("reaction.temperature_tiers")
	if tiers is Array:
		for tier_entry in tiers:
			var tier: Dictionary = tier_entry
			var tier_id := str(tier.get("id", ""))
			var button := Button.new()
			button.text = str(tier.get("name", tier_id))
			button.toggle_mode = true
			button.button_group = group
			button.pressed.connect(_on_tier_pressed.bind(tier_id))
			tier_row.add_child(button)
			_tier_buttons[tier_id] = button

	_progress = ProgressBar.new()
	_progress.show_percentage = false
	_progress.max_value = PROGRESS_MAX
	add_child(_progress)

	_bubble = BubbleView.new()
	_bubble.custom_minimum_size = Vector2(BUBBLE_MIN_WIDTH, BUBBLE_MIN_HEIGHT)
	_bubble.size_flags_vertical = Control.SIZE_EXPAND_FILL
	add_child(_bubble)

	var action_row := HBoxContainer.new()
	action_row.add_theme_constant_override("separation", SEPARATION)
	add_child(action_row)
	_start_button = Button.new()
	_start_button.text = "点火"
	_start_button.disabled = true
	_start_button.pressed.connect(_on_start_pressed)
	action_row.add_child(_start_button)
	_take_button = Button.new()
	_take_button.text = "取出"
	_take_button.disabled = true
	_take_button.pressed.connect(_on_take_out_pressed)
	action_row.add_child(_take_button)

	_status_label = UiTheme.label("")
	add_child(_status_label)
	select_tier(default_tier)


func select_tier(tier_id: String) -> void:
	if not _tier_buttons.has(tier_id):
		return
	var button: Button = _tier_buttons[tier_id]
	button.button_pressed = true


func refresh(active: bool, progress: float, inputs: Dictionary, can_start: bool) -> void:
	_pending_label.text = _pending_text(inputs)
	_progress.value = progress * PROGRESS_MAX
	_start_button.disabled = active or not can_start
	_take_button.disabled = not active or progress < 1.0


func set_status(text: String) -> void:
	_status_label.text = text


func set_bubbles(bubble_level: int, steam_level: int) -> void:
	_bubble.set_levels(bubble_level, steam_level)


func _pending_text(inputs: Dictionary) -> String:
	if inputs.is_empty():
		return "尚未投料"
	var parts: Array[String] = []
	for mat_id in inputs:
		if _db == null:
			continue
		var entry := _db.material(str(mat_id))
		parts.append("%s ×%d" % [entry.get("name", str(mat_id)), int(inputs[mat_id])])
	return "已投料：" + "、".join(parts)


func _on_tier_pressed(tier_id: String) -> void:
	tier_selected.emit(tier_id)


func _on_start_pressed() -> void:
	start_pressed.emit()


func _on_take_out_pressed() -> void:
	take_out_pressed.emit()
