class_name TestContext
extends RefCounted

## 极简断言收集器：所有测试共用一个实例。

var failures: Array[String] = []
var checks: int = 0


func check(condition: bool, message: String) -> void:
	checks += 1
	if not condition:
		failures.append(message)


func check_eq(actual: Variant, expected: Variant, message: String) -> void:
	checks += 1
	if actual != expected:
		failures.append("%s：期望 %s，实际 %s" % [message, str(expected), str(actual)])


func check_approx(actual: float, expected: float, tolerance: float, message: String) -> void:
	checks += 1
	if abs(actual - expected) > tolerance:
		failures.append("%s：期望 %.6f ± %.6f，实际 %.6f" % [message, expected, tolerance, actual])
