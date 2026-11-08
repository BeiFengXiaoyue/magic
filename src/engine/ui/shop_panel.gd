class_name ShopPanel
extends VBoxContainer

## 小店柜台：成品列表、覆盖率、报价、卖出；商队到访日附带器材货架。
## 报价由编排层算好传进来；这里只显示与发信号。

signal sell_requested(product_index: int)
signal buy_requested(device_id: String)
signal equip_requested(device_id: String)
signal close_requested

const WIDTH := 620.0
const HEIGHT := 520.0

var _demand_label: Label
var _list: VBoxContainer
var _offers_title: Label
var _offers: VBoxContainer
var _status_label: Label


func setup() -> void:
	custom_minimum_size = Vector2(WIDTH, HEIGHT)
	add_child(UiTheme.title("小店柜台"))
	_demand_label = _label("")
	add_child(_demand_label)
	_list = VBoxContainer.new()
	_list.size_flags_vertical = Control.SIZE_EXPAND_FILL
	add_child(_list)
	_offers_title = UiTheme.title("商队货架")
	_offers_title.add_theme_font_size_override("font_size", 18)
	add_child(_offers_title)
	_offers = VBoxContainer.new()
	add_child(_offers)
	_status_label = _label("")
	add_child(_status_label)
	var close_button := Button.new()
	close_button.text = "关闭"
	close_button.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	close_button.pressed.connect(_on_close_pressed)
	add_child(close_button)


func refresh(products: Array[Dictionary], demand_text: String) -> void:
	_demand_label.text = demand_text
	for child in _list.get_children():
		_list.remove_child(child)
		child.queue_free()
	if products.is_empty():
		_list.add_child(_label("还没有成品。先去炼一炉。"))
		return
	for entry in products:
		var row := HBoxContainer.new()
		var name := str(entry.get("name", "药剂"))
		var coverage := float(entry.get("coverage", 0.0))
		var price := int(entry.get("price", 0))
		var can_sell := bool(entry.get("can_sell", false))
		var price_text := ("%d 金币" % price) if can_sell else "卖不掉"
		var info := _label("%s · 覆盖率 %.2f · %s" % [name, coverage, price_text])
		info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(info)
		var button := Button.new()
		button.text = "卖出" if can_sell else "卖不掉"
		button.disabled = not can_sell
		button.pressed.connect(_on_sell_pressed.bind(int(entry.get("index", 0))))
		row.add_child(button)
		_list.add_child(row)


func refresh_offers(offers: Array[Dictionary], caravan_day: bool) -> void:
	for child in _offers.get_children():
		_offers.remove_child(child)
		child.queue_free()
	if not caravan_day:
		_offers.add_child(_label("商队还没来。"))
		return
	if offers.is_empty():
		_offers.add_child(_label("这次没带器材。"))
		return
	for offer in offers:
		var row := HBoxContainer.new()
		var name := str(offer.get("name", "器材"))
		var price := int(offer.get("price", 0))
		var pressure := float(offer.get("pressure_atm", 0.0))
		var owned := bool(offer.get("owned", false))
		var current := bool(offer.get("current", false))
		var info := _label("%s · %d 金币 · %.1f atm" % [name, price, pressure])
		info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(info)
		var button := Button.new()
		if current:
			button.text = "装备中"
			button.disabled = true
		elif owned:
			button.text = "装备"
			button.pressed.connect(_on_equip_pressed.bind(str(offer.get("id", ""))))
		else:
			button.text = "买下"
			button.pressed.connect(_on_buy_pressed.bind(str(offer.get("id", ""))))
		row.add_child(button)
		_offers.add_child(row)


func _label(text: String) -> Label:
	var label := UiTheme.label(text)
	label.add_theme_color_override("font_color", Color("#2a211a"))
	return label


func set_status(text: String) -> void:
	_status_label.text = text


func _on_sell_pressed(index: int) -> void:
	sell_requested.emit(index)


func _on_buy_pressed(device_id: String) -> void:
	buy_requested.emit(device_id)


func _on_equip_pressed(device_id: String) -> void:
	equip_requested.emit(device_id)


func _on_close_pressed() -> void:
	close_requested.emit()
