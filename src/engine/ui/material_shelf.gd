class_name MaterialShelf
extends VBoxContainer

## 左侧原料架：只负责显示与发出“选中材料”，不碰库存规则。

signal material_selected(mat_id: String)

const WIDTH := 280.0
const SEPARATION := 8

var _db: ContentDatabase
var _list: VBoxContainer
var _product_label: Label


func setup(db: ContentDatabase) -> void:
	_db = db
	custom_minimum_size = Vector2(WIDTH, 0.0)
	add_theme_constant_override("separation", SEPARATION)
	add_child(UiTheme.title("原料架"))
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	add_child(scroll)
	_list = VBoxContainer.new()
	_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(_list)
	_product_label = UiTheme.label("产物：0")
	add_child(_product_label)


func refresh(inventory: Inventory, disabled: bool) -> void:
	if _db == null:
		return
	for child in _list.get_children():
		_list.remove_child(child)
		child.queue_free()
	for mat_id in _db.material_ids():
		var entry := _db.material(mat_id)
		var count := inventory.count_material(mat_id)
		var button := Button.new()
		button.text = "%s  ×%d" % [entry.get("name", mat_id), count]
		UiTheme.style_button(button)
		button.disabled = disabled or count <= 0
		button.pressed.connect(_on_material_pressed.bind(mat_id))
		_list.add_child(button)
	_product_label.text = "产物：%d" % inventory.products.size()


func _on_material_pressed(mat_id: String) -> void:
	material_selected.emit(mat_id)
