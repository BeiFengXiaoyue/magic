extends RefCounted

## 主角只有左右两套行走图：水平分量决定朝向，纯上下沿用上一次朝向。


func run(ctx: TestContext) -> void:
	ctx.check(not Player.resolve_facing(Vector2(-1.0, 0.0), true), "左移应朝左")
	ctx.check(Player.resolve_facing(Vector2(1.0, 0.0), false), "右移应朝右")
	ctx.check(not Player.resolve_facing(Vector2(-1.0, -1.0), true), "左上应朝左")
	ctx.check(Player.resolve_facing(Vector2(1.0, 1.0), false), "右下应朝右")
	ctx.check(Player.resolve_facing(Vector2(0.0, -1.0), true), "上移应沿用朝右")
	ctx.check(not Player.resolve_facing(Vector2(0.0, -1.0), false), "上移应沿用朝左")
	ctx.check(Player.resolve_facing(Vector2(0.0, 1.0), true), "下移应沿用朝右")
	ctx.check(not Player.resolve_facing(Vector2(0.0, 1.0), false), "下移应沿用朝左")
	ctx.check(Player.resolve_facing(Vector2.ZERO, true), "静止应保持当前朝向")
