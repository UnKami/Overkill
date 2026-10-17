class_name QAProfileGuard extends RefCounted
## Verification scenes must never write to a player's normal save profile.
static func require_isolated(node: Node) -> bool:
	var profile: String = OS.get_environment("APPDATA").replace("\\","/").to_lower()
	if profile.is_empty(): profile=OS.get_environment("XDG_DATA_HOME").replace("\\","/").to_lower()
	if profile.contains("/.tools/") or profile.contains("/.test-artifacts/"): return true
	push_error("QA scene refused normal user data. Set APPDATA to a disposable .tools/<profile> directory before launching.")
	node.get_tree().quit(1)
	return false
