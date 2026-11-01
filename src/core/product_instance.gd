class_name ProductInstance
extends RefCounted

## 一瓶成品（契约 02 §1.10）。每瓶组成不同 ⇒ 不可堆叠；
## 覆盖率与价格一律由 result 现算，不存派生值。

var itm_id: String = ""
var recipe_id: String = ""
var result: CraftResult = null
var created_day: int = 0
var itm_name: String = ""


func display_name() -> String:
	return itm_name if itm_name != "" else itm_id
