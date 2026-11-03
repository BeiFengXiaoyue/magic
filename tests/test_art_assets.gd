extends RefCounted

## art_id → 路径/类别，以及缺图回退。


func run(ctx: TestContext) -> void:
	ctx.check_eq(ArtAssets.category_of("art_scene_shop"), "scene", "场景类别")
	ctx.check_eq(ArtAssets.category_of("art_prop_qinglucao"), "prop", "物件类别")
	ctx.check_eq(ArtAssets.category_of("bad"), "", "非法 ID")
	ctx.check_eq(
		ArtAssets.path_for("art_scene_shop"),
		"res://assets/textures/scene/art_scene_shop.png",
		"场景路径"
	)
	ctx.check_eq(
		ArtAssets.path_for("art_prop_qinglucao"),
		"res://assets/textures/prop/art_prop_qinglucao.png",
		"物件路径"
	)
	ctx.check(ArtAssets.texture("art_scene_shop") != null, "已生成的场景贴图应能加载")
	ctx.check(ArtAssets.texture("art_prop_qinglucao") != null, "已生成的物件贴图应能加载")
	ctx.check(ArtAssets.texture("art_missing_thing") == null, "缺图应返回 null")
