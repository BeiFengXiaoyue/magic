class_name Wallet
extends RefCounted

## 金币与炼金印记（契约 02 §1.11）。悬空存储，不占背包格。

var gold: int = 0
var seals: int = 0


func add_gold(amount: int) -> void:
	if amount > 0:
		gold += amount


func add_seals(amount: int) -> void:
	if amount > 0:
		seals += amount


func spend_gold(amount: int) -> bool:
	if amount <= 0:
		return false
	if gold < amount:
		return false
	gold -= amount
	return true


func snapshot() -> Dictionary:
	return { "gold": gold, "seals": seals }
