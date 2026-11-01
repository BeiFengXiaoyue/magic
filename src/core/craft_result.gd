class_name CraftResult
extends RefCounted

## 一炉炼制的最终结果（契约 02 §1.2）。
## composition 的键同时包含化合物与未反应元素，占比按元素单位计，Σ = 1。

var composition: Dictionary = {}
var yield_ratio: float = 0.0
var dominant: String = ""
var reaction_log: Array = []
var reading: Dictionary = { "effects": {}, "costs": {} }
