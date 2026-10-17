class_name ShopPanel
extends VBoxContainer

## 小店柜台：成品列表、覆盖率、报价、卖出。
## 报价由编排层算好传进来；这里只显示与发信号。

signal sell_requested(product_index: int)
signal close_requested

const WIDTH := 620.0
const HEIGHT := 360.0

var _demand_label: Label
var _list: VBoxContainer
var _status_label: Label


func setup() -> void:
	custom_minimum_size = Vector2(WIDTH, HEIGHT)
	add_child(UiTheme.title("小店柜台"))
	_demand_label = UiTheme.label("")
	add_child(_demand_label)
	_list = VBoxContainer.new()
	_list.size_flags_vertical = Control.SIZE_EXPAND_FILL
	add_child(_list)
	_status_label = UiTheme.label("")
	add_child(_status_label)
	var close_button := Button.new()
	close_button.text = "关闭"
	close_button.pressed.connect(_on_close_pressed)
	add_child(close_button)


func refresh(products: Array[Dictionary], demand_text: String) -> void:
	_demand_label.text = demand_text
	for child in _list.get_children():
		_list.remove_child(child)
		child.queue_free()
	if products.is_empty():
		_list.add_child(UiTheme.label("还没有成品。先去炼一炉。"))
		return
	for entry in products:
		var row := HBoxContainer.new()
		var name := str(entry.get("name", "药剂"))
		var coverage := float(entry.get("coverage", 0.0))
		var price := int(entry.get("price", 0))
		var can_sell := bool(entry.get("can_sell", false))
		var price_text := ("%d 金币" % price) if can_sell else "卖不掉"
		var info := UiTheme.label("%s · 覆盖率 %.2f · %s" % [name, coverage, price_text])
		info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(info)
		var button := Button.new()
		button.text = "卖出" if can_sell else "卖不掉"
		button.disabled = not can_sell
		button.pressed.connect(_on_sell_pressed.bind(int(entry.get("index", 0))))
		row.add_child(button)
		_list.add_child(row)


func set_status(text: String) -> void:
	_status_label.text = text


func _on_sell_pressed(index: int) -> void:
	sell_requested.emit(index)


func _on_close_pressed() -> void:
	close_requested.emit()
