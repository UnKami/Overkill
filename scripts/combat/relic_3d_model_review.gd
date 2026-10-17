extends Control
const MODELS: PackedScene = preload("res://assets/animations/relics/three_d/relics.glb")
var _checks: int = 0
func _ready() -> void:
	if not QAProfileGuard.require_isolated(self): return
	get_window().size = Vector2i(1280,720)
	var bg := ColorRect.new();bg.color=Color("18212a");bg.size=Vector2(1920,1080);add_child(bg)
	var heading := Label.new();heading.text="CANONICAL RELIC ART / NATIVE 3D VOLUME";heading.position=Vector2(35,20);heading.add_theme_font_size_override("font_size",32);add_child(heading)
	var ids: Array[String] = ["REL-01","REL-25","REL-15","REL-16","REL-14","REL-11"]
	for i: int in ids.size():
		var relic: ClockRelicData = ContentDatabase.get_clock_relic(ids[i])
		var at: Vector2 = Vector2(30+(i%3)*635,95+(i/3)*475)
		var label := Label.new();label.text=relic.name;label.position=at;label.add_theme_font_size_override("font_size",28);add_child(label)
		var reference := TextureRect.new();reference.texture=RelicArt.load_texture(relic.art_id);reference.position=at+Vector2(0,55);reference.size=Vector2(265,370);reference.expand_mode=TextureRect.EXPAND_IGNORE_SIZE;reference.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED;add_child(reference)
		reference.size=Vector2(265,370)
		var viewport := SubViewport.new();viewport.size=Vector2i(560,680);viewport.transparent_bg=true;viewport.own_world_3d=true;viewport.msaa_3d=Viewport.MSAA_4X;add_child(viewport)
		var model: Node3D = MODELS.instantiate();viewport.add_child(model)
		var prefix: String = ids[i].replace("-","_")+"__"
		for node: Node in model.find_children("*","MeshInstance3D",true,false):
			var mesh: MeshInstance3D = node as MeshInstance3D;mesh.visible=str(mesh.name).begins_with(prefix)
			if mesh.visible: assert(mesh.skin!=null);_checks+=1
		var camera := Camera3D.new();viewport.add_child(camera);camera.projection=Camera3D.PROJECTION_ORTHOGONAL
		var center: float = .29 if i==0 else -.10 if i==2 else .0
		camera.size=1.05 if i==0 else .62
		camera.position=Vector3(.12,center+.08,2);camera.look_at(Vector3(0,center,0))
		var env := WorldEnvironment.new();var settings := Environment.new();settings.background_mode=Environment.BG_COLOR;settings.background_color=Color(0,0,0,0);settings.ambient_light_source=Environment.AMBIENT_SOURCE_COLOR;settings.ambient_light_color=Color.WHITE;settings.ambient_light_energy=.65;env.environment=settings;viewport.add_child(env)
		var light := DirectionalLight3D.new();viewport.add_child(light);light.position=Vector3(-3,4,5);light.look_at(Vector3.ZERO);light.light_energy=.85
		var rendered := TextureRect.new();rendered.texture=viewport.get_texture();rendered.position=at+Vector2(305,55);rendered.size=Vector2(290,370);rendered.expand_mode=TextureRect.EXPAND_IGNORE_SIZE;rendered.stretch_mode=TextureRect.STRETCH_SCALE;add_child(rendered)
		rendered.size=Vector2(290,370)
	await get_tree().create_timer(1.0).timeout
	await RenderingServer.frame_post_draw
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://.test-artifacts/047"))
	get_viewport().get_texture().get_image().save_png("res://.test-artifacts/047/canonical-relics-3d.png")
	print("RELIC_REFERENCE_REVIEW_OK skinned_volume_meshes=%d" % _checks)
	get_tree().quit()
