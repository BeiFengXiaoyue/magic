class_name Projection
extends RefCounted

## 双重语义投影（契约 02 §1.3）。
## M1 只实现药师视角：它是 result.reading 的只读视图，不重新计算。


static func for_pharmacist(result: CraftResult) -> Dictionary:
	return result.reading.duplicate(true)


static func for_artificer(result: CraftResult) -> Dictionary:
	return {}
