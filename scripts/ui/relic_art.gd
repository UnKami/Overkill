class_name RelicArt extends RefCounted
## Resolves relic art without allowing card scenes to override object assets.


static func load_texture(art_id: String) -> Texture2D:
	var candidates: Array[String] = [
		"res://assets/relics/active/%s_object.png" % art_id,
		"res://assets/relics/%s.png" % art_id,
		"res://assets/relics/%s.jpg" % art_id,
		"res://assets/icons/ui/%s.png" % art_id,
	]
	for path: String in candidates:
		if ResourceLoader.exists(path):
			return ResourceLoader.load(path) as Texture2D
	return null
