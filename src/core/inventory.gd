class_name Inventory
extends RefCounted

## 库存（契约 02 §1.9）。材料只记份数；成品以 ProductInstance 逐个存放，不可堆叠。

var materials: Dictionary = {}
var products: Array[ProductInstance] = []


func add_material(mat_id: String, count: int) -> void:
	if count <= 0:
		return
	materials[mat_id] = count_material(mat_id) + count


func take_material(mat_id: String, count: int) -> bool:
	if count <= 0:
		return false
	var available := count_material(mat_id)
	if available < count:
		return false
	var remaining := available - count
	if remaining == 0:
		materials.erase(mat_id)
	else:
		materials[mat_id] = remaining
	return true


func count_material(mat_id: String) -> int:
	return int(materials.get(mat_id, 0))


func add_product(product: ProductInstance) -> void:
	if product != null:
		products.append(product)


func remove_product(index: int) -> ProductInstance:
	if index < 0 or index >= products.size():
		return null
	var product: ProductInstance = products[index]
	products.remove_at(index)
	return product


func product_at(index: int) -> ProductInstance:
	if index < 0 or index >= products.size():
		return null
	return products[index]


func snapshot() -> Dictionary:
	var product_summary: Array = []
	for product in products:
		product_summary.append({
			"itm_id": product.itm_id,
			"recipe_id": product.recipe_id,
		})
	return {
		"materials": materials.duplicate(),
		"products": product_summary,
	}
