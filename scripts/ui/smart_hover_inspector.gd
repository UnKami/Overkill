class_name SmartHoverInspector extends Control
## Slay-the-Spire-caliber instant hover inspector with live combat math,
## per-hour clash timeline, and contextual side-by-side keyword callout sub-cards.
## Strict zero mouse interference (MOUSE_FILTER_IGNORE on all nodes).

static var _instance: SmartHoverInspector = null

const VIEWPORT_FALLBACK := Vector2(1920.0, 1080.0)
const SCREEN_MARGIN: float = 16.0
const ANCHOR_GAP: float = 14.0
const PRIMARY_WIDTH: float = 410.0
const KEYWORD_WIDTH: float = 268.0
const MAX_KEYWORD_CARDS: int = 4

const COLOR_BUFFED := Color("#67E68D")
const COLOR_WEAKENED := Color("#FF7A7A")
const COLOR_NEUTRAL := Color("#E5E4DF")
const COLOR_FORMULA_BG := Color("#0B1824F4")
const COLOR_CLASH_BG := Color("#09131DF4")
const COLOR_CARD_BG := Color("#071019F8")
const COLOR_KEYWORD_BG := Color("#09141FF6")

const KEYWORD_DEFINITIONS: Dictionary = {
	"Block": {
		"title": "BLOCK",
		"color": Color("#4FB8FF"),
		"desc": "Absorbs incoming attack damage before Vitality. Persists across hours until depleted or battle ends."
	},
	"Strength": {
		"title": "STRENGTH",
		"color": Color("#B76CFF"),
		"desc": "Adds +1 damage per stack to every attack hit for the remainder of combat."
	},
	"Vulnerable": {
		"title": "VULNERABLE",
		"color": Color("#EFB477"),
		"desc": "Target takes 50% more damage from attacks (×1.5). Decays by 1 stack at the end of each hour tick."
	},
	"Weak": {
		"title": "WEAK",
		"color": Color("#84C8AE"),
		"desc": "Reduces attack damage dealt by 25% (×0.75). Decays by 1 stack at the end of each hour tick."
	},
	"Bleed": {
		"title": "BLEED",
		"color": Color("#58D66B"),
		"desc": "Deals unblockable Vitality damage at the start of every hour tick. Does not decay automatically."
	},
	"Thorns": {
		"title": "THORNS",
		"color": Color("#B76CFF"),
		"desc": "Automatically deals retaliatory damage back to the attacker whenever struck."
	},
	"Lifesteal": {
		"title": "LIFESTEAL",
		"color": Color("#67E68D"),
		"desc": "Restores your Vitality equal to the unblocked HP damage dealt by this strike."
	},
	"Overkill": {
		"title": "OVERKILL",
		"color": Color("#C41734"),
		"desc": "Excess damage dealt beyond 0 HP is banked 1:1 as Overkill Points and triggers Overkill synergies."
	},
	"Sector Finisher": {
		"title": "SECTOR FINISHER (H3/6/9)",
		"color": Color("#FFD166"),
		"desc": "Triggers bonus damage or extra hits when bound to the final hour of any sector (Hours 3, 6, or 9)."
	},
	"Resonance": {
		"title": "RESONANCE",
		"color": Color("#80C8D1"),
		"desc": "Gains bonus power when the immediately preceding hour holds a relic sharing at least one Essence color."
	},
	"Echo": {
		"title": "ECHO",
		"color": Color("#D988FF"),
		"desc": "Re-triggers the relic bound to the immediately preceding hour on your Chronometer."
	},
	"Socket Multiplier": {
		"title": "SOCKET MULTIPLIER",
		"color": Color("#FFD166"),
		"desc": "Permanently amplifies the damage multiplier of an hour socket for the rest of combat."
	},
	"Overdrive": {
		"title": "OVERDRIVE",
		"color": Color("#B76CFF"),
		"desc": "Empowers the very next attacking relic that resolves, multiplying or boosting every hit."
	},
	"Hazard": {
		"title": "HAZARD SOCKET",
		"color": Color("#E74C3C"),
		"desc": "Corrupted hour: attacks launched from this socket deal 50% of their damage back to you as recoil."
	},
	"Locked": {
		"title": "LOCKED SOCKET",
		"color": Color("#99A9B5"),
		"desc": "Sealed hour: this socket cannot be replaced during Sector Hot-Swap phases."
	},
	"Siphon": {
		"title": "OVERKILL SIPHON",
		"color": Color("#C41734"),
		"desc": "If this enemy attack deals unblocked Vitality damage, it drains 25% of your banked Overkill."
	}
}

var _active_anchor: Control = null
var _primary_card: PanelContainer
var _accent_bar: ColorRect
var _badge_label: Label
var _title_label: Label
var _rule_rect: ColorRect
var _body_label: RichTextLabel
var _formula_box: PanelContainer
var _formula_label: RichTextLabel
var _clash_box: PanelContainer
var _clash_label: RichTextLabel
var _keyword_column: VBoxContainer
var _fade_tween: Tween = null


func _ready() -> void:
	name = "SmartHoverInspector"
	top_level = true
	z_index = 120
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	theme = ScreenDesign.build_theme()
	_build_ui()
	hide()


static func ensure(context: Node) -> SmartHoverInspector:
	if is_instance_valid(_instance) and _instance.is_inside_tree():
		return _instance
	if context == null or not context.is_inside_tree():
		return null
	var tree: SceneTree = context.get_tree()
	if tree == null:
		return null
	var parent_node: Node = tree.current_scene if is_instance_valid(tree.current_scene) else tree.root
	if parent_node == null:
		return null
	var existing: SmartHoverInspector = parent_node.get_node_or_null("SmartHoverInspector") as SmartHoverInspector
	if is_instance_valid(existing):
		_instance = existing
		return _instance
	_instance = SmartHoverInspector.new()
	parent_node.add_child(_instance)
	return _instance


static func find_combat_controller(node: Node) -> Object:
	var cur: Node = node
	while cur != null:
		if cur is CombatController:
			return cur
		cur = cur.get_parent()
	if node != null and node.is_inside_tree():
		var scene: Node = node.get_tree().current_scene
		if scene is CombatController:
			return scene
	return null


static func hide_inspector(source: Control = null) -> void:
	if not is_instance_valid(_instance):
		return
	if source != null and _instance._active_anchor != null and _instance._active_anchor != source:
		return
	_instance._active_anchor = null
	_instance.hide()


func _process(_delta: float) -> void:
	if not visible:
		return
	if _active_anchor == null or not is_instance_valid(_active_anchor) or not _active_anchor.is_visible_in_tree():
		_active_anchor = null
		hide()
		return
	_reposition_around(_active_anchor)


func _build_ui() -> void:
	_primary_card = PanelContainer.new()
	_primary_card.name = "PrimaryCard"
	_primary_card.custom_minimum_size = Vector2(PRIMARY_WIDTH, 0.0)
	_primary_card.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_primary_card)

	var outer_vbox := VBoxContainer.new()
	outer_vbox.add_theme_constant_override("separation", 0)
	outer_vbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_primary_card.add_child(outer_vbox)

	_accent_bar = ColorRect.new()
	_accent_bar.custom_minimum_size = Vector2(0.0, 4.0)
	_accent_bar.color = ScreenDesign.GOLD
	_accent_bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	outer_vbox.add_child(_accent_bar)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 16)
	margin.add_theme_constant_override("margin_right", 16)
	margin.add_theme_constant_override("margin_top", 12)
	margin.add_theme_constant_override("margin_bottom", 14)
	margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	outer_vbox.add_child(margin)

	var inner_vbox := VBoxContainer.new()
	inner_vbox.add_theme_constant_override("separation", 7)
	inner_vbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
	margin.add_child(inner_vbox)

	_badge_label = Label.new()
	_badge_label.add_theme_font_size_override("font_size", 13)
	_badge_label.add_theme_color_override("font_color", ScreenDesign.MUTED)
	_badge_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_badge_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	inner_vbox.add_child(_badge_label)

	_title_label = Label.new()
	_title_label.add_theme_font_override("font", ScreenDesign.display_font())
	_title_label.add_theme_font_size_override("font_size", 22)
	_title_label.add_theme_color_override("font_color", ScreenDesign.TEXT)
	_title_label.add_theme_color_override("font_outline_color", Color("04090e"))
	_title_label.add_theme_constant_override("outline_size", 4)
	_title_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_title_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	inner_vbox.add_child(_title_label)

	_rule_rect = ColorRect.new()
	_rule_rect.custom_minimum_size = Vector2(0.0, 1.0)
	_rule_rect.color = Color(ScreenDesign.GOLD, 0.45)
	_rule_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	inner_vbox.add_child(_rule_rect)

	_body_label = _make_rich_label(16)
	inner_vbox.add_child(_body_label)

	_formula_box = PanelContainer.new()
	_formula_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_formula_box.add_theme_stylebox_override("panel", _make_subbox_style(COLOR_FORMULA_BG, ScreenDesign.CYAN))
	inner_vbox.add_child(_formula_box)

	_formula_label = _make_rich_label(15)
	_formula_box.add_child(_formula_label)

	_clash_box = PanelContainer.new()
	_clash_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_clash_box.add_theme_stylebox_override("panel", _make_subbox_style(COLOR_CLASH_BG, ScreenDesign.GOLD))
	inner_vbox.add_child(_clash_box)

	_clash_label = _make_rich_label(14)
	_clash_box.add_child(_clash_label)

	_keyword_column = VBoxContainer.new()
	_keyword_column.name = "KeywordColumn"
	_keyword_column.custom_minimum_size = Vector2(KEYWORD_WIDTH, 0.0)
	_keyword_column.add_theme_constant_override("separation", 8)
	_keyword_column.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_keyword_column)


func _make_rich_label(font_size: int) -> RichTextLabel:
	var rtl := RichTextLabel.new()
	rtl.bbcode_enabled = true
	rtl.fit_content = true
	rtl.scroll_active = false
	rtl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	rtl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	rtl.add_theme_font_size_override("normal_font_size", font_size)
	rtl.add_theme_font_size_override("bold_font_size", font_size)
	rtl.add_theme_color_override("default_color", COLOR_NEUTRAL)
	return rtl


func _make_card_style(bg: Color, border: Color, border_width: int = 2) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = bg
	style.border_color = border
	style.set_border_width_all(border_width)
	style.set_corner_radius_all(6)
	style.shadow_color = Color(0.0, 0.0, 0.0, 0.82)
	style.shadow_size = 16
	style.content_margin_left = 0
	style.content_margin_right = 0
	style.content_margin_top = 0
	style.content_margin_bottom = 0
	return style


func _make_subbox_style(bg: Color, left_accent: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = bg
	style.border_color = Color(left_accent, 0.78)
	style.border_width_left = 3
	style.border_width_top = 1
	style.border_width_right = 1
	style.border_width_bottom = 1
	style.set_corner_radius_all(4)
	style.content_margin_left = 10
	style.content_margin_right = 10
	style.content_margin_top = 7
	style.content_margin_bottom = 7
	return style


static func inspect_socket(socket_view: ClockSocketView, battle: Object = null) -> void:
	var inst: SmartHoverInspector = ensure(socket_view)
	if inst == null or socket_view == null or socket_view.data == null:
		return
	var resolved_battle: Object = battle if battle != null else find_combat_controller(socket_view)
	inst.show_for_socket(socket_view, resolved_battle)


static func inspect_pedestal(pedestal_view: RelicPedestalView, battle: Object = null, target_hour: int = 0) -> void:
	var inst: SmartHoverInspector = ensure(pedestal_view)
	if inst == null or pedestal_view == null or pedestal_view.relic == null:
		return
	var resolved_battle: Object = battle if battle != null else find_combat_controller(pedestal_view)
	inst.show_for_pedestal(pedestal_view, resolved_battle, target_hour)


static func inspect_relic(anchor: Control, relic: ClockRelicData, battle: Object = null, target_hour: int = 0, subtitle_override: String = "") -> void:
	var inst: SmartHoverInspector = ensure(anchor)
	if inst == null or anchor == null or relic == null:
		return
	var resolved_battle: Object = battle if battle != null else find_combat_controller(anchor)
	inst.show_for_relic_control(anchor, relic, resolved_battle, target_hour, subtitle_override)


static func inspect_combatant(anchor: Control, battle: Object, is_enemy: bool) -> void:
	var inst: SmartHoverInspector = ensure(anchor)
	if inst == null or anchor == null or battle == null:
		return
	inst.show_for_combatant(anchor, battle, is_enemy)


static func inspect_pile(anchor: Control, title_text: String, subtitle_text: String, relics: Array, accent: Color = ScreenDesign.GOLD) -> void:
	var inst: SmartHoverInspector = ensure(anchor)
	if inst == null or anchor == null:
		return
	inst.show_for_pile(anchor, title_text, subtitle_text, relics, accent)


static func inspect_custom(
	anchor: Control,
	title_text: String,
	subtitle_text: String,
	body_bbcode: String,
	formula_lines: Array[String] = [],
	clash_lines: Array[String] = [],
	keywords: Array[String] = [],
	accent: Color = ScreenDesign.GOLD
) -> void:
	var inst: SmartHoverInspector = ensure(anchor)
	if inst == null or anchor == null:
		return
	inst._present(anchor, title_text, subtitle_text, body_bbcode, formula_lines, clash_lines, keywords, accent)


func show_for_socket(socket_view: ClockSocketView, battle: Object = null) -> void:
	if socket_view == null or socket_view.data == null:
		return
	var s_data: ClockSocketData = socket_view.data
	var hour: int = s_data.hour_index
	var is_finisher_hour: bool = hour in [3, 6, 9]
	var is_enemy: bool = socket_view.is_enemy_socket

	if is_enemy:
		_show_enemy_socket(socket_view, s_data, battle)
		return

	var keywords: Array[String] = []
	var formula_lines: Array[String] = []
	var clash_lines: Array[String] = []
	var accent: Color = ScreenDesign.CYAN
	var sector_num: int = ((hour - 1) / 3) + 1
	var header_badge: String = "PLAYER CHRONOMETER  ·  HOUR %02d  (SECTOR %d)" % [hour, sector_num]
	if is_finisher_hour:
		header_badge += "  ★ SECTOR FINISHER"
		_add_unique_keyword(keywords, "Sector Finisher")

	if s_data.multiplier > 1.01:
		formula_lines.append("[color=#ffd166][b]Socket Multiplier:[/b] %.1f× permanent attack amplification[/color]" % s_data.multiplier)
		_add_unique_keyword(keywords, "Socket Multiplier")
	if s_data.is_locked:
		formula_lines.append("[color=#99a9b5][b]Locked Socket:[/b] Cannot be hot-swapped in Phase 2[/color]")
		_add_unique_keyword(keywords, "Locked")
	if s_data.is_hazard:
		formula_lines.append("[color=#ff7a7a][b]Hazard Socket:[/b] Attacks deal 50%% damage back as recoil[/color]")
		_add_unique_keyword(keywords, "Hazard")

	if s_data.slotted_relic != null:
		var relic: ClockRelicData = s_data.slotted_relic
		accent = relic.primary_color()
		var live: Dictionary = compute_relic_live_stats(relic, battle, hour)
		var pos_tags: Array = live.get("positional_tags", [])
		if not pos_tags.is_empty():
			header_badge += "\n" + "  ".join(pos_tags)
		var body_text: String = _format_relic_body(relic, live)
		for f_line: String in live.get("formula_lines", []):
			formula_lines.append(f_line)
		_collect_relic_keywords(relic, keywords)
		if battle != null:
			var preview_hours: Array = _determine_clash_hours_for_socket(battle, hour)
			var swap_relic: ClockRelicData = null
			var swap_hour: int = 0
			if int(battle.get("phase")) == CombatController.Phase.QUADRANT and socket_view.is_interactive and battle.get("current_drawn_relic") != null:
				swap_relic = battle.get("current_drawn_relic")
				swap_hour = hour
				formula_lines.append("[color=#efd9ad][b]Hot-Swap Preview:[/b] Click to replace [b]%s[/b] with [b]%s[/b][/color]" % [relic.name, swap_relic.name])
			clash_lines = build_clash_timeline(battle, preview_hours, swap_hour, swap_relic)
		_present(socket_view, relic.name.to_upper(), header_badge, body_text, formula_lines, clash_lines, keywords, accent)
	else:
		var empty_body: String = "No relic bound to Hour %02d." % hour
		if is_finisher_hour:
			empty_body += "\n[color=#ffd166]★ Final hour of Sector %d: triggers [b]Sector Finisher[/b] bonuses on relics bound here.[/color]" % sector_num
		if socket_view.is_targetable_empty:
			empty_body += "\n[color=#80c8d1][b]Click to target Hour %02d[/b] as your next binding slot in this sector![/color]" % hour
		if battle != null:
			var preview_hours: Array = _determine_clash_hours_for_socket(battle, hour)
			clash_lines = build_clash_timeline(battle, preview_hours)
		_present(socket_view, "EMPTY SOCKET  ·  %02d O'CLOCK" % hour, header_badge, empty_body, formula_lines, clash_lines, keywords, accent)


func _show_enemy_socket(socket_view: ClockSocketView, s_data: ClockSocketData, battle: Object = null) -> void:
	var hour: int = s_data.hour_index
	var keywords: Array[String] = []
	var formula_lines: Array[String] = []
	var clash_lines: Array[String] = []
	var enemy_name: String = "ADVERSARY"
	var profile_note: String = ""
	if battle != null and battle.has_method("_active_enemy"):
		var enemy_res: EnemyData = battle._active_enemy()
		if enemy_res != null:
			enemy_name = enemy_res.display_name.to_upper()
			var prof: String = EnemyClockPattern.profile(enemy_res)
			if prof in ["reverse", "eclipse"]:
				profile_note = "Counter-Clockwise Hand (Pairs with Your Hour %02d)" % (10 - hour)
			else:
				profile_note = "Clockwise Hand (Pairs with Your Hour %02d)" % hour

	var badge: String = "%s  ·  ENEMY HOUR %02d" % [enemy_name, hour]
	if not profile_note.is_empty():
		badge += "\n" + profile_note

	if not s_data.intent_revealed:
		var hidden_body: String = "This enemy hour has not been revealed yet.\n[color=#99a9b5]Enemy intents are unveiled as the chronometer hands approach this sector.[/color]"
		_present(socket_view, "UNREVEALED INTENT  ·  H%02d" % hour, badge, hidden_body, formula_lines, clash_lines, keywords, Color("#83929E"))
		return

	var live_enemy: Dictionary = compute_enemy_socket_live_stats(s_data, battle)
	var accent: Color = live_enemy.get("accent", Color("#E74C3C"))
	var title_text: String = live_enemy.get("title", "ENEMY INTENT · HOUR %02d" % hour)
	var body_lines: Array[String] = []

	if s_data.intent_damage > 0:
		var live_dmg: int = int(live_enemy.get("live_damage", s_data.intent_damage))
		var hits: int = maxi(1, s_data.intent_hits)
		var dmg_col: String = "#67e68d" if live_dmg < s_data.intent_damage else ("#ff7a7a" if live_dmg > s_data.intent_damage else "#ff9e8a")
		if hits > 1:
			body_lines.append("• Strikes for [color=%s][b]%d × %d[/b][/color] ([b]%d total damage[/b])." % [dmg_col, live_dmg, hits, live_dmg * hits])
		else:
			body_lines.append("• Strikes for [color=%s][b]%d damage[/b][/color]." % [dmg_col, live_dmg])

	if s_data.intent_block > 0:
		body_lines.append("• Gains [color=#76d9ee][b]%d Block[/b][/color] before attacks resolve." % s_data.intent_block)
		_add_unique_keyword(keywords, "Block")
	if s_data.intent_strength > 0:
		body_lines.append("• Gains [color=#b76cff][b]+%d Strength[/b][/color] before attacks resolve." % s_data.intent_strength)
		_add_unique_keyword(keywords, "Strength")
	if s_data.intent_vulnerable > 0:
		body_lines.append("• Inflicts [color=#efb477][b]%d Vulnerable[/b][/color] on you." % s_data.intent_vulnerable)
		_add_unique_keyword(keywords, "Vulnerable")
	if s_data.intent_weak > 0:
		body_lines.append("• Inflicts [color=#84c8ae][b]%d Weak[/b][/color] on you." % s_data.intent_weak)
		_add_unique_keyword(keywords, "Weak")
	if s_data.intent_bleed > 0:
		body_lines.append("• Inflicts [color=#58d66b][b]%d Bleed[/b][/color] on you." % s_data.intent_bleed)
		_add_unique_keyword(keywords, "Bleed")
	if s_data.is_siphon:
		body_lines.append("• [color=#c41734][b]Siphon:[/b][/color] Drains 25% of your banked Overkill on unblocked HP damage.")
		_add_unique_keyword(keywords, "Siphon")

	if body_lines.is_empty():
		body_lines.append("Enemy performs no action on this hour.")

	for f_line: String in live_enemy.get("formula_lines", []):
		formula_lines.append(f_line)

	if battle != null and battle.has_method("_active_enemy"):
		var enemy_res: EnemyData = battle._active_enemy()
		var paired_player_hour: int = (10 - hour) if EnemyClockPattern.profile(enemy_res) in ["reverse", "eclipse"] else hour
		if paired_player_hour >= 1 and paired_player_hour <= 9:
			clash_lines = build_clash_timeline(battle, [paired_player_hour])

	_present(socket_view, title_text, badge, "\n".join(body_lines), formula_lines, clash_lines, keywords, accent)


func show_for_pedestal(pedestal_view: RelicPedestalView, battle: Object = null, target_hour: int = 0) -> void:
	if pedestal_view == null or pedestal_view.relic == null:
		return
	var relic: ClockRelicData = pedestal_view.relic
	var resolved_hour: int = target_hour
	if resolved_hour <= 0 and battle != null:
		resolved_hour = _resolve_default_target_hour(battle)
	show_for_relic_control(pedestal_view, relic, battle, resolved_hour)


func show_for_relic_control(anchor: Control, relic: ClockRelicData, battle: Object = null, target_hour: int = 0, subtitle_override: String = "") -> void:
	var live: Dictionary = compute_relic_live_stats(relic, battle, target_hour)
	var badge: String = subtitle_override if not subtitle_override.is_empty() else ("%s  ·  %s" % [relic.affinity_name().to_upper(), _tier_name(relic.tier)])
	var pos_tags: Array = live.get("positional_tags", [])
	if target_hour >= 1 and target_hour <= 9:
		badge += "  ·  TARGET HOUR %02d" % target_hour
	if not pos_tags.is_empty():
		badge += "\n" + "  ".join(pos_tags)

	var body_text: String = _format_relic_body(relic, live)
	var formula_lines: Array[String] = []
	for f_line: String in live.get("formula_lines", []):
		formula_lines.append(f_line)

	var clash_lines: Array[String] = []
	if battle != null and not bool(battle.get("_resolving")) and not bool(battle.get("_combat_over")):
		if int(battle.get("phase")) == CombatController.Phase.ASSEMBLY and target_hour >= 1 and target_hour <= 9:
			var sector_idx: int = ((target_hour - 1) / 3) + 1
			var sector_hours: Array[int] = ChronometerView.get_quadrant_hours(sector_idx)
			# Check if other hours in sector are already filled or if this is single-hour assembly
			var filled_in_sector: int = 0
			for sh: int in sector_hours:
				if sh != target_hour and battle.player_sockets[sh - 1].slotted_relic != null:
					filled_in_sector += 1
			var preview_hours: Array = sector_hours if filled_in_sector == 2 else [target_hour]
			clash_lines = build_clash_timeline(battle, preview_hours, target_hour, relic)
		elif int(battle.get("phase")) == CombatController.Phase.QUADRANT:
			var q_hours: Array[int] = ChronometerView.get_quadrant_hours(int(battle.get("active_quadrant")))
			var swap_h: int = target_hour if q_hours.has(target_hour) else 0
			clash_lines = build_clash_timeline(battle, q_hours, swap_h, relic if swap_h > 0 else null)

	var keywords: Array[String] = []
	_collect_relic_keywords(relic, keywords)
	_present(anchor, relic.name.to_upper(), badge, body_text, formula_lines, clash_lines, keywords, relic.primary_color())


func show_for_combatant(anchor: Control, battle: Object, is_enemy: bool) -> void:
	if battle == null:
		return
	var keywords: Array[String] = []
	var formula_lines: Array[String] = []
	var body_lines: Array[String] = []

	if not is_enemy:
		var hp: int = maxi(0, int(battle.get("player_hp")))
		var max_hp: int = maxi(1, int(battle.get("player_max_hp")))
		var blk: int = int(battle.get("player_block"))
		var p_str: int = int(battle.get("player_strength"))
		var p_bleed: int = int(battle.get("player_bleed"))
		var p_thorns: int = int(battle.get("player_thorns"))
		var p_weak: int = int(battle.get("player_weak"))
		var p_vuln: int = int(battle.get("player_vulnerable"))
		var next_bonus: int = int(battle.get("player_next_hit_bonus"))
		var next_mult: int = maxi(1, int(battle.get("player_next_attack_multiplier")))

		body_lines.append("[color=#f08a83][b]Vitality:[/b] %d / %d HP[/color]   ·   [color=#76d9ee][b]Block:[/b] %d[/color]   ·   [color=#c41734][b]Overkill:[/b] %d[/color]" % [hp, max_hp, blk, OKRunState.current_ok])
		_add_unique_keyword(keywords, "Block")
		_add_unique_keyword(keywords, "Overkill")

		var active_statuses: Array[String] = []
		if p_str > 0:
			active_statuses.append("• [color=#b76cff][b]Strength +%d:[/b][/color] Your attacks deal +%d damage per hit." % [p_str, p_str])
			_add_unique_keyword(keywords, "Strength")
		if p_thorns > 0:
			active_statuses.append("• [color=#b76cff][b]Thorns %d:[/b][/color] Deals %d damage back whenever you are struck." % [p_thorns, p_thorns])
			_add_unique_keyword(keywords, "Thorns")
		if next_mult > 1:
			active_statuses.append("• [color=#d988ff][b]Overdrive ×%d:[/b][/color] Your next attacking relic deals %d× damage." % [next_mult, next_mult])
			_add_unique_keyword(keywords, "Overdrive")
		if next_bonus > 0:
			active_statuses.append("• [color=#ffd166][b]Kinetic Charge +%d:[/b][/color] Your next attacking relic gains +%d base damage per hit." % [next_bonus, next_bonus])
			_add_unique_keyword(keywords, "Overdrive")
		if p_bleed > 0:
			active_statuses.append("• [color=#58d66b][b]Bleed %d:[/b][/color] You lose %d HP at the start of every hour tick." % [p_bleed, p_bleed])
			_add_unique_keyword(keywords, "Bleed")
		if p_weak > 0:
			active_statuses.append("• [color=#84c8ae][b]Weak %d:[/b][/color] Your attacks deal 25%% less damage (%d tick(s) remaining)." % [p_weak, p_weak])
			_add_unique_keyword(keywords, "Weak")
		if p_vuln > 0:
			active_statuses.append("• [color=#efb477][b]Vulnerable %d:[/b][/color] You take 50%% more attack damage (%d tick(s) remaining)." % [p_vuln, p_vuln])
			_add_unique_keyword(keywords, "Vulnerable")

		if active_statuses.is_empty():
			body_lines.append("[color=#99a9b5]No active buffs or debuffs on The Executioner.[/color]")
		else:
			body_lines.append("\n".join(active_statuses))

		var deck_count: int = (battle.get("player_deck") as Array).size() if battle.get("player_deck") is Array else 0
		var discard_count: int = (battle.get("player_discard") as Array).size() if battle.get("player_discard") is Array else 0
		formula_lines.append("[color=#80c8d1][b]Reserve Piles:[/b] %d in Draw Pile  ·  %d in Discard Pile[/color]" % [deck_count, discard_count])

		_present(anchor, "THE EXECUTIONER", "PLAYER STATUS & ACTIVE MODIFIERS", "\n".join(body_lines), formula_lines, [], keywords, ScreenDesign.CYAN)
	else:
		var e_hp: int = maxi(0, int(battle.get("enemy_hp")))
		var e_max_hp: int = maxi(1, int(battle.get("enemy_max_hp")))
		var e_blk: int = int(battle.get("enemy_block"))
		var e_str: int = int(battle.get("enemy_strength"))
		var e_bleed: int = int(battle.get("enemy_bleed"))
		var e_thorns: int = int(battle.get("enemy_thorns"))
		var e_weak: int = int(battle.get("enemy_weak"))
		var e_vuln: int = int(battle.get("enemy_vulnerable"))

		var enemy_res: EnemyData = battle._active_enemy() if battle.has_method("_active_enemy") else null
		var e_title: String = enemy_res.display_name.to_upper() if enemy_res != null else "THE ADVERSARY"
		var e_desc: String = EnemyClockPattern.description(enemy_res)

		body_lines.append("[color=#f08a83][b]Vitality:[/b] %d / %d HP[/color]   ·   [color=#76d9ee][b]Block:[/b] %d[/color]" % [e_hp, e_max_hp, e_blk])
		if not e_desc.is_empty():
			body_lines.append("[color=#efd9ad]%s[/color]" % e_desc)

		var active_statuses: Array[String] = []
		if e_str > 0:
			active_statuses.append("• [color=#b76cff][b]Strength +%d:[/b][/color] Enemy attacks deal +%d damage per hit." % [e_str, e_str])
			_add_unique_keyword(keywords, "Strength")
		if e_thorns > 0:
			active_statuses.append("• [color=#b76cff][b]Thorns %d:[/b][/color] Deals %d damage back when you strike this enemy." % [e_thorns, e_thorns])
			_add_unique_keyword(keywords, "Thorns")
		if e_bleed > 0:
			active_statuses.append("• [color=#58d66b][b]Bleed %d:[/b][/color] Enemy loses %d HP at the start of every hour tick." % [e_bleed, e_bleed])
			_add_unique_keyword(keywords, "Bleed")
		if e_weak > 0:
			active_statuses.append("• [color=#84c8ae][b]Weak %d:[/b][/color] Enemy attacks deal 25%% less damage (%d tick(s) remaining)." % [e_weak, e_weak])
			_add_unique_keyword(keywords, "Weak")
		if e_vuln > 0:
			active_statuses.append("• [color=#efb477][b]Vulnerable %d:[/b][/color] Enemy takes 50%% more attack damage (%d tick(s) remaining)." % [e_vuln, e_vuln])
			_add_unique_keyword(keywords, "Vulnerable")

		if active_statuses.is_empty():
			body_lines.append("[color=#99a9b5]No active buffs or debuffs on this adversary.[/color]")
		else:
			body_lines.append("\n".join(active_statuses))

		_present(anchor, e_title, "ADVERSARY STATUS & MECHANISM TRAITS", "\n".join(body_lines), formula_lines, [], keywords, Color("#E74C3C"))


func show_for_pile(anchor: Control, title_text: String, subtitle_text: String, relics: Array, accent: Color = ScreenDesign.GOLD) -> void:
	var keywords: Array[String] = []
	var formula_lines: Array[String] = []
	var lines: Array[String] = []
	if relics.is_empty():
		lines.append("[color=#99a9b5]This pile is currently empty.[/color]")
	else:
		var counts: Dictionary = {}
		var sample_map: Dictionary = {}
		for item: Variant in relics:
			var r: ClockRelicData = item as ClockRelicData
			if r == null:
				continue
			var key: String = r.id if not r.id.is_empty() else r.name
			counts[key] = int(counts.get(key, 0)) + 1
			sample_map[key] = r
		for key: String in counts.keys():
			var r: ClockRelicData = sample_map[key]
			var count: int = int(counts[key])
			var col_hex: String = r.primary_color().to_html(false)
			var count_str: String = " ×%d" % count if count > 1 else ""
			lines.append("• [color=#%s][b]%s%s[/b][/color] — %s" % [col_hex, r.name, count_str, RelicPedestalView.summary(r).replace("\n", " · ")])
	formula_lines.append("[color=#efd9ad][b]Total Relics:[/b] %d[/color]" % relics.size())
	_present(anchor, title_text, subtitle_text, "\n".join(lines), formula_lines, [], keywords, accent)


func _present(
	anchor: Control,
	title_text: String,
	subtitle_text: String,
	body_bbcode: String,
	formula_lines: Array[String],
	clash_lines: Array[String],
	keywords: Array[String],
	accent: Color
) -> void:
	_active_anchor = anchor
	_accent_bar.color = accent
	_rule_rect.color = Color(accent, 0.45)
	_primary_card.add_theme_stylebox_override("panel", _make_card_style(COLOR_CARD_BG, Color(accent, 0.85), 2))

	_badge_label.text = subtitle_text
	_badge_label.visible = not subtitle_text.is_empty()
	_badge_label.add_theme_color_override("font_color", accent.lightened(0.28))

	_title_label.text = title_text
	_body_label.text = body_bbcode

	if formula_lines.is_empty():
		_formula_box.hide()
	else:
		_formula_box.show()
		_formula_box.add_theme_stylebox_override("panel", _make_subbox_style(COLOR_FORMULA_BG, accent.lightened(0.15)))
		_formula_label.text = "\n".join(formula_lines)

	if clash_lines.is_empty():
		_clash_box.hide()
	else:
		_clash_box.show()
		_clash_label.text = "\n".join(clash_lines)

	_rebuild_keyword_cards(keywords)
	_primary_card.reset_size()
	_keyword_column.reset_size()
	show()
	_reposition_around(anchor)
	call_deferred("_reposition_around", anchor)

	if not AudioManager.reduced_motion:
		if _fade_tween != null and _fade_tween.is_valid():
			_fade_tween.kill()
		modulate.a = 0.0
		_fade_tween = create_tween()
		_fade_tween.tween_property(self, "modulate:a", 1.0, 0.08)
	else:
		modulate.a = 1.0


func _rebuild_keyword_cards(keywords: Array[String]) -> void:
	for child: Node in _keyword_column.get_children():
		_keyword_column.remove_child(child)
		child.queue_free()

	var count: int = 0
	for kw: String in keywords:
		if count >= MAX_KEYWORD_CARDS:
			break
		if not KEYWORD_DEFINITIONS.has(kw):
			continue
		var def: Dictionary = KEYWORD_DEFINITIONS[kw]
		var kw_color: Color = def.get("color", ScreenDesign.GOLD)
		var card := PanelContainer.new()
		card.custom_minimum_size = Vector2(KEYWORD_WIDTH, 0.0)
		card.mouse_filter = Control.MOUSE_FILTER_IGNORE
		card.add_theme_stylebox_override("panel", _make_subbox_style(COLOR_KEYWORD_BG, kw_color))

		var vbox := VBoxContainer.new()
		vbox.add_theme_constant_override("separation", 3)
		vbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
		card.add_child(vbox)

		var k_title := Label.new()
		k_title.text = str(def.get("title", kw.to_upper()))
		k_title.add_theme_font_size_override("font_size", 14)
		k_title.add_theme_color_override("font_color", kw_color.lightened(0.2))
		k_title.mouse_filter = Control.MOUSE_FILTER_IGNORE
		vbox.add_child(k_title)

		var k_desc := Label.new()
		k_desc.text = str(def.get("desc", ""))
		k_desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		k_desc.add_theme_font_size_override("font_size", 13)
		k_desc.add_theme_color_override("font_color", Color("#CBD6DF"))
		k_desc.mouse_filter = Control.MOUSE_FILTER_IGNORE
		vbox.add_child(k_desc)

		_keyword_column.add_child(card)
		count += 1

	_keyword_column.visible = count > 0


func _reposition_around(anchor: Control) -> void:
	if not is_instance_valid(anchor):
		return
	var vp_size: Vector2 = get_viewport_rect().size
	if vp_size.x <= 10.0 or vp_size.y <= 10.0:
		vp_size = VIEWPORT_FALLBACK

	_primary_card.reset_size()
	_keyword_column.reset_size()
	var p_size: Vector2 = _primary_card.get_combined_minimum_size()
	p_size.x = maxf(p_size.x, PRIMARY_WIDTH)
	p_size.y = maxf(p_size.y, _primary_card.size.y)
	_primary_card.size = p_size

	var kw_size: Vector2 = Vector2.ZERO
	if _keyword_column.visible and _keyword_column.get_child_count() > 0:
		kw_size = _keyword_column.get_combined_minimum_size()
		kw_size.x = maxf(kw_size.x, KEYWORD_WIDTH)
		kw_size.y = maxf(kw_size.y, _keyword_column.size.y)
		_keyword_column.size = kw_size

	var total_w: float = p_size.x + ( kw_size.x + 8.0 if kw_size.x > 0.0 else 0.0 )
	var total_h: float = maxf(p_size.y, kw_size.y)
	var rect: Rect2 = anchor.get_global_rect()

	var pos := Vector2.ZERO
	var kw_on_left: bool = false

	# Determine if anchor is a wide bottom card/pedestal or top HUD pill vs a side socket
	var is_bottom_pedestal: bool = rect.position.y > vp_size.y * 0.56 and rect.size.y >= 160.0
	if is_bottom_pedestal:
		# Place above the pedestal so we never cover the choice row or clocks
		pos.x = clampf(rect.get_center().x - total_w * 0.5, SCREEN_MARGIN, vp_size.x - total_w - SCREEN_MARGIN)
		pos.y = rect.position.y - p_size.y - ANCHOR_GAP
		if pos.y < SCREEN_MARGIN:
			# Fallback to side if card is too tall to fit above
			if rect.end.x + ANCHOR_GAP + total_w <= vp_size.x - SCREEN_MARGIN:
				pos.x = rect.end.x + ANCHOR_GAP
			elif rect.position.x - ANCHOR_GAP - total_w >= SCREEN_MARGIN:
				pos.x = rect.position.x - ANCHOR_GAP - p_size.x
				kw_on_left = true
			pos.y = clampf(rect.get_center().y - total_h * 0.5, SCREEN_MARGIN, vp_size.y - total_h - SCREEN_MARGIN)
	else:
		# Place to the right if room, else to the left
		if rect.end.x + ANCHOR_GAP + total_w <= vp_size.x - SCREEN_MARGIN:
			pos.x = rect.end.x + ANCHOR_GAP
			kw_on_left = false
		elif rect.position.x - ANCHOR_GAP - total_w >= SCREEN_MARGIN:
			pos.x = rect.position.x - ANCHOR_GAP - p_size.x
			kw_on_left = true
		elif rect.end.x + ANCHOR_GAP + p_size.x <= vp_size.x - SCREEN_MARGIN:
			pos.x = rect.end.x + ANCHOR_GAP
			kw_on_left = true
		else:
			pos.x = maxf(SCREEN_MARGIN, rect.position.x - ANCHOR_GAP - p_size.x)
			kw_on_left = true
		pos.y = clampf(rect.get_center().y - p_size.y * 0.5, SCREEN_MARGIN, vp_size.y - total_h - SCREEN_MARGIN)

	_primary_card.global_position = pos
	if _keyword_column.visible and kw_size.x > 0.0:
		var kw_x: float = pos.x - kw_size.x - 8.0 if kw_on_left else pos.x + p_size.x + 8.0
		if kw_x < SCREEN_MARGIN:
			kw_x = pos.x + p_size.x + 8.0
		elif kw_x + kw_size.x > vp_size.x - SCREEN_MARGIN:
			kw_x = maxf(SCREEN_MARGIN, pos.x - kw_size.x - 8.0)
		var kw_y: float = clampf(pos.y, SCREEN_MARGIN, vp_size.y - kw_size.y - SCREEN_MARGIN)
		_keyword_column.global_position = Vector2(kw_x, kw_y)


static func compute_relic_live_stats(relic: ClockRelicData, battle: Object = null, hour_index: int = 0) -> Dictionary:
	var result: Dictionary = {
		"base_damage": 0,
		"live_damage": 0,
		"base_hits": 1,
		"live_hits": 1,
		"total_damage": 0,
		"base_block": 0,
		"live_block": 0,
		"is_damage_buffed": false,
		"is_damage_weakened": false,
		"is_block_buffed": false,
		"formula_lines": [] as Array[String],
		"positional_tags": [] as Array[String],
		"badge_tag": ""
	}
	if relic == null:
		return result

	var base_d: int = relic.base_damage
	var hits: int = maxi(1, relic.hits)
	var base_b: int = relic.base_block
	var live_d: int = base_d
	var live_b: int = base_b
	var pos_tags: Array[String] = []
	var formulas: Array[String] = []
	var is_finisher_hour: bool = hour_index in [3, 6, 9]

	if relic.sector_finisher_bonus_damage > 0 or relic.sector_finisher_hits_bonus > 0:
		if is_finisher_hour:
			pos_tags.append("[FINISHER H%d ★]" % hour_index)
		else:
			pos_tags.append("[FINISHER H3/6/9]")
	if relic.echo_previous_hour:
		pos_tags.append("[ECHO]")
	if relic.charge_next_socket_multiplier > 0.0:
		pos_tags.append("[+%.1f× SOCKET]" % relic.charge_next_socket_multiplier)

	var prev_relic: ClockRelicData = null
	var socket_mult: float = 1.0
	if battle != null and hour_index >= 1 and hour_index <= 9:
		var p_sockets: Variant = battle.get("player_sockets")
		if p_sockets is Array and (p_sockets as Array).size() >= 9:
			var sock: ClockSocketData = p_sockets[hour_index - 1]
			if sock != null:
				socket_mult = sock.multiplier
			var prev_idx: int = (hour_index - 2 + 9) % 9
			var prev_sock: ClockSocketData = p_sockets[prev_idx]
			if prev_sock != null:
				prev_relic = prev_sock.slotted_relic

	var resonance_active: bool = relic.resonance_essence_bonus > 0 and prev_relic != null and relic.shares_essence_with(prev_relic)
	if relic.resonance_essence_bonus > 0:
		pos_tags.append("[RESONANCE ★]" if resonance_active else "[RESONANCE]")

	var effective_relic: ClockRelicData = relic
	if relic.echo_previous_hour and prev_relic != null:
		formulas.append("[color=#d988ff][b]Echo Target (H%02d):[/b] Re-triggers [b]%s[/b][/color]" % [((hour_index - 2 + 9) % 9) + 1, prev_relic.name])
		if base_d <= 0 and prev_relic.base_damage > 0:
			effective_relic = prev_relic
			base_d = prev_relic.base_damage
			live_d = base_d
			hits = maxi(1, prev_relic.hits)
		if base_b <= 0 and prev_relic.base_block > 0:
			base_b = prev_relic.base_block
			live_b = base_b

	var live_hits: int = hits
	if effective_relic.sector_finisher_hits_bonus > 0 and is_finisher_hour:
		live_hits += effective_relic.sector_finisher_hits_bonus

	if battle != null:
		var p_str: int = int(battle.get("player_strength")) + effective_relic.apply_strength
		var p_blk: int = int(battle.get("player_block"))
		var p_thorns: int = int(battle.get("player_thorns")) + effective_relic.apply_thorns
		var p_weak: int = int(battle.get("player_weak"))
		var p_next_bonus: int = int(battle.get("player_next_hit_bonus"))
		var p_next_mult: int = maxi(1, int(battle.get("player_next_attack_multiplier")))
		var e_hp: int = int(battle.get("enemy_hp"))
		var e_max_hp: int = maxi(1, int(battle.get("enemy_max_hp")))
		var e_vuln: int = int(battle.get("enemy_vulnerable")) + effective_relic.apply_vulnerable
		var e_bleed: int = int(battle.get("enemy_bleed")) + effective_relic.apply_bleed
		var banked_ok: int = OKRunState.current_ok + effective_relic.grant_overkill

		if base_b > 0 or effective_relic.multiply_current_block > 1.0:
			var blk_parts: Array[String] = []
			if base_b > 0:
				blk_parts.append("Base %d" % base_b)
			if resonance_active and base_b > 0:
				live_b += effective_relic.resonance_essence_bonus
				blk_parts.append("+ Resonance %d" % effective_relic.resonance_essence_bonus)
			if effective_relic.multiply_current_block > 1.0:
				var pre_mult_blk: int = p_blk + live_b
				var post_mult_blk: int = floori(float(pre_mult_blk) * effective_relic.multiply_current_block)
				var gained_from_mult: int = maxi(0, post_mult_blk - p_blk)
				live_b = gained_from_mult
				blk_parts.append("(%d Cur + %d) × %.1f = +%d BLOCK" % [p_blk, base_b, effective_relic.multiply_current_block, gained_from_mult])
			elif live_b != base_b:
				blk_parts.append("= %d BLOCK" % live_b)
			if live_b != base_b or effective_relic.multiply_current_block > 1.0:
				formulas.append("[color=#76d9ee][b]Live Block:[/b] %s[/color]" % " ".join(blk_parts))

		var has_attack_payload: bool = (
			base_d > 0
			or effective_relic.damage_per_current_block_pct > 0.0
			or effective_relic.thorns_to_damage_multiplier > 0.0
			or effective_relic.damage_per_enemy_bleed > 0
			or effective_relic.damage_per_banked_overkill_div > 0
		)
		if has_attack_payload:
			var working_d: int = base_d
			var parts: Array[String] = []
			if effective_relic.conditional_hp_threshold_pct > 0.0 and float(e_hp) / float(e_max_hp) <= effective_relic.conditional_hp_threshold_pct:
				working_d = effective_relic.conditional_damage
				parts.append("ExecBase %d" % working_d)
			else:
				parts.append("Base %d" % working_d)

			if p_str > 0:
				working_d += p_str
				parts.append("+ Str %d" % p_str)
			if p_next_bonus > 0:
				working_d += p_next_bonus
				parts.append("+ Charge %d" % p_next_bonus)
			if effective_relic.sector_finisher_bonus_damage > 0 and is_finisher_hour:
				working_d += effective_relic.sector_finisher_bonus_damage
				parts.append("+ Finisher %d" % effective_relic.sector_finisher_bonus_damage)
			if resonance_active and base_d > 0:
				working_d += effective_relic.resonance_essence_bonus
				parts.append("+ Resonance %d" % effective_relic.resonance_essence_bonus)
			if effective_relic.damage_per_current_block_pct > 0.0:
				var blk_pool: int = p_blk + live_b
				var blk_dmg: int = floori(float(blk_pool) * effective_relic.damage_per_current_block_pct)
				working_d += blk_dmg
				parts.append("+ %d%%Blk(%d)" % [roundi(effective_relic.damage_per_current_block_pct * 100.0), blk_dmg])
			if effective_relic.thorns_to_damage_multiplier > 0.0:
				var th_dmg: int = floori(float(p_thorns) * effective_relic.thorns_to_damage_multiplier)
				working_d += th_dmg
				parts.append("+ Thorns(%d)" % th_dmg)
			if effective_relic.damage_per_enemy_bleed > 0:
				var bl_dmg: int = e_bleed * effective_relic.damage_per_enemy_bleed
				working_d += bl_dmg
				parts.append("+ Bleed(%d)" % bl_dmg)
			if effective_relic.damage_per_banked_overkill_div > 0:
				var ok_dmg: int = banked_ok / maxi(1, effective_relic.damage_per_banked_overkill_div)
				working_d += ok_dmg
				parts.append("+ OK(%d)" % ok_dmg)

			if e_vuln > 0:
				working_d = floori(working_d * 1.5)
				parts.append("× 1.5 Vuln")
			if p_weak > 0:
				working_d = floori(working_d * 0.75)
				parts.append("× 0.75 Weak")
			if socket_mult > 1.01 or socket_mult < 0.99:
				working_d = floori(working_d * socket_mult)
				parts.append("× %.1f Socket" % socket_mult)
			if p_next_mult > 1:
				working_d *= p_next_mult
				parts.append("× %d Overdrive" % p_next_mult)

			live_d = maxi(0, working_d)
			var dmg_color_hex: String = "#67e68d" if (live_d > base_d or live_hits > hits) else ("#ff7a7a" if live_d < base_d else "#ffd166")
			if live_hits > 1:
				formulas.append("[b]Live Math:[/b] %s = [color=%s][b]%d × %d (%d DMG)[/b][/color]" % [" ".join(parts), dmg_color_hex, live_d, live_hits, live_d * live_hits])
			else:
				formulas.append("[b]Live Math:[/b] %s = [color=%s][b]%d DMG[/b][/color]" % [" ".join(parts), dmg_color_hex, live_d])

	result["base_damage"] = base_d
	result["live_damage"] = live_d
	result["base_hits"] = hits
	result["live_hits"] = live_hits
	result["total_damage"] = live_d * live_hits
	result["base_block"] = base_b
	result["live_block"] = live_b
	result["is_damage_buffed"] = (live_d > base_d) or (live_hits > hits and live_d > 0)
	result["is_damage_weakened"] = (base_d > 0 and live_d < base_d)
	result["is_block_buffed"] = live_b > base_b
	result["formula_lines"] = formulas
	result["positional_tags"] = pos_tags
	result["badge_tag"] = pos_tags[0] if not pos_tags.is_empty() else ""
	return result


static func compute_enemy_socket_live_stats(s_data: ClockSocketData, battle: Object = null) -> Dictionary:
	var result: Dictionary = {
		"live_damage": s_data.intent_damage if s_data != null else 0,
		"live_hits": maxi(1, s_data.intent_hits) if s_data != null else 1,
		"live_block": s_data.intent_block if s_data != null else 0,
		"is_buffed": false,
		"is_weakened": false,
		"accent": Color("#83929E"),
		"title": "ENEMY INTENT",
		"formula_lines": [] as Array[String]
	}
	if s_data == null or not s_data.intent_revealed:
		return result

	var formulas: Array[String] = []
	var e_str: int = int(battle.get("enemy_strength")) if battle != null else 0
	var e_weak: int = int(battle.get("enemy_weak")) if battle != null else 0
	var p_vuln: int = int(battle.get("player_vulnerable")) if battle != null else 0

	# In CombatController._resolve_tick, enemy socket strength & player_vulnerable apply in Step 2 before Step 3 attack!
	var tick_str: int = e_str + s_data.intent_strength
	var tick_vuln: int = p_vuln + s_data.intent_vulnerable
	var live_d: int = s_data.intent_damage
	var hits: int = maxi(1, s_data.intent_hits)

	if s_data.intent_damage > 0:
		var parts: Array[String] = ["Base %d" % s_data.intent_damage]
		live_d = s_data.intent_damage + tick_str
		if e_str > 0:
			parts.append("+ Str %d" % e_str)
		if s_data.intent_strength > 0:
			parts.append("+ SelfBuff %d" % s_data.intent_strength)
		if tick_vuln > 0:
			live_d = floori(live_d * 1.5)
			parts.append("× 1.5 YourVuln")
		if e_weak > 0:
			live_d = floori(live_d * 0.75)
			parts.append("× 0.75 Weak")

		var col_hex: String = "#67e68d" if live_d < s_data.intent_damage else ("#ff7a7a" if live_d > s_data.intent_damage else "#ff9e8a")
		if hits > 1:
			formulas.append("[b]Enemy Attack Math:[/b] %s = [color=%s][b]%d × %d (%d DMG)[/b][/color]" % [" ".join(parts), col_hex, live_d, hits, live_d * hits])
		else:
			formulas.append("[b]Enemy Attack Math:[/b] %s = [color=%s][b]%d DMG[/b][/color]" % [" ".join(parts), col_hex, live_d])

	var action_names: Array[String] = []
	if s_data.intent_damage > 0:
		action_names.append("STRIKE")
		result["accent"] = Color("#E74C3C")
	if s_data.intent_block > 0:
		action_names.append("GUARD")
		if s_data.intent_damage <= 0:
			result["accent"] = Color("#3498DB")
	if s_data.intent_strength > 0:
		action_names.append("EMPOWER")
		if s_data.intent_damage <= 0 and s_data.intent_block <= 0:
			result["accent"] = ClockRelicData.essence_to_color(ClockRelicData.Essence.BUFF)
	if s_data.intent_weak > 0 or s_data.intent_vulnerable > 0 or s_data.intent_bleed > 0:
		action_names.append("HEX")
		if s_data.intent_damage <= 0 and s_data.intent_block <= 0 and s_data.intent_strength <= 0:
			result["accent"] = ClockRelicData.essence_to_color(ClockRelicData.Essence.DEBUFF)

	result["live_damage"] = live_d
	result["live_hits"] = hits
	result["is_buffed"] = s_data.intent_damage > 0 and live_d > s_data.intent_damage
	result["is_weakened"] = s_data.intent_damage > 0 and live_d < s_data.intent_damage
	result["title"] = (" + ".join(action_names) if not action_names.is_empty() else "IDLE") + ("  ·  H%02d" % s_data.hour_index)
	result["formula_lines"] = formulas
	return result


static func build_clash_timeline(battle: Object, hours: Array, replace_hour: int = 0, override_relic: ClockRelicData = null) -> Array[String]:
	var lines: Array[String] = []
	if battle == null or hours.is_empty():
		return lines
	var p_sockets: Variant = battle.get("player_sockets")
	var e_sockets: Variant = battle.get("enemy_sockets")
	if not (p_sockets is Array) or not (e_sockets is Array) or (p_sockets as Array).size() < 9 or (e_sockets as Array).size() < 9:
		return lines

	lines.append("[color=#efd9ad][b]CLASH OUTCOME FORECAST[/b][/color]")
	var s: Dictionary = {}
	for key: String in ["player_hp", "player_max_hp", "player_block", "player_strength", "player_bleed", "player_weak", "player_vulnerable", "player_thorns", "player_next_hit_bonus", "player_next_attack_multiplier", "enemy_hp", "enemy_max_hp", "enemy_block", "enemy_strength", "enemy_bleed", "enemy_weak", "enemy_vulnerable", "enemy_thorns"]:
		s[key] = int(battle.get(key))
	s["overkill"] = OKRunState.current_ok
	var enemy_res: EnemyData = battle._active_enemy() if battle.has_method("_active_enemy") else null

	for h_var: Variant in hours:
		var hour: int = int(h_var)
		if hour < 1 or hour > 9:
			continue
		var enemy_hour: int = EnemyClockPattern.hour_for(hour, enemy_res)
		var e_sock: ClockSocketData = e_sockets[enemy_hour - 1]
		var p_sock: ClockSocketData = p_sockets[hour - 1]
		var r: ClockRelicData = override_relic if hour == replace_hour else p_sock.slotted_relic

		if not e_sock.intent_revealed:
			lines.append("[color=#99a9b5]• H%02d vs E%02d: Enemy intent unrevealed (?)[/color]" % [hour, enemy_hour])
			break

		var p_hp_before: int = int(s["player_hp"])
		var e_hp_before: int = int(s["enemy_hp"])
		var ok_before: int = int(s["overkill"])

		DecisionPreview._tick(s, p_sock, e_sock, r)
		if EnemyClockPattern.has_twin(enemy_res) and hour % 3 == 0 and int(s["player_hp"]) > 0 and int(s["enemy_hp"]) > 0:
			var echo_sock: ClockSocketData = e_sockets[(enemy_hour + 3) % 9]
			if echo_sock.intent_revealed and echo_sock.intent_damage > 0:
				DecisionPreview._enemy_hit(s, DecisionPreview._enemy_damage(s, echo_sock.intent_damage), echo_sock.is_siphon)
				s["enemy_block"] = int(s["enemy_block"]) + echo_sock.intent_block
		for decay_key: String in ["player_weak", "player_vulnerable", "enemy_weak", "enemy_vulnerable"]:
			s[decay_key] = maxi(0, int(s[decay_key]) - 1)

		var p_delta: int = int(s["player_hp"]) - p_hp_before
		var e_delta: int = int(s["enemy_hp"]) - e_hp_before
		var ok_delta: int = int(s["overkill"]) - ok_before
		var p_delta_str: String = ("[color=#ff7a7a]%d HP[/color]" % p_delta) if p_delta < 0 else (("[color=#67e68d]+%d HP[/color]" % p_delta) if p_delta > 0 else "0 HP")
		var e_delta_str: String = ("[color=#ff9e44]%d HP[/color]" % e_delta) if e_delta < 0 else "0 HP"
		var ok_str: String = (" · [color=#ff6b81]+%d OK[/color]" % ok_delta) if ok_delta > 0 else ""

		lines.append("• [b]H%02d↔E%02d:[/b] Foe %s (%d🛡)  |  You %s (%d🛡)%s" % [
			hour, enemy_hour, e_delta_str, maxi(0, int(s["enemy_block"])), p_delta_str, maxi(0, int(s["player_block"])), ok_str
		])
		if int(s["enemy_hp"]) <= 0:
			lines.append("[color=#67e68d][b]★ ENEMY DEFEATED ON HOUR %02d![/b][/color]" % hour)
			break
		if int(s["player_hp"]) <= 0:
			lines.append("[color=#ff7a7a][b]⚠ LETHAL TO YOU ON HOUR %02d![/b][/color]" % hour)
			break

	lines.append("[color=#80c8d1]Net: You [b]%d HP[/b] (%d🛡)  ·  Foe [b]%d HP[/b] (%d🛡)  ·  [b]%d OK[/b][/color]" % [
		maxi(0, int(s["player_hp"])), maxi(0, int(s["player_block"])), maxi(0, int(s["enemy_hp"])), maxi(0, int(s["enemy_block"])), int(s["overkill"])
	])
	return lines


func _format_relic_body(relic: ClockRelicData, live: Dictionary) -> String:
	var clauses: Array[String] = []
	var live_d: int = int(live.get("live_damage", relic.base_damage))
	var live_h: int = int(live.get("live_hits", maxi(1, relic.hits)))
	var live_b: int = int(live.get("live_block", relic.base_block))
	var dmg_buffed: bool = bool(live.get("is_damage_buffed", false))
	var dmg_weakened: bool = bool(live.get("is_damage_weakened", false))
	var blk_buffed: bool = bool(live.get("is_block_buffed", false))

	if relic.base_damage > 0 or live_d > 0:
		var d_col: String = "#67e68d" if dmg_buffed else ("#ff7a7a" if dmg_weakened else "#ff9e44")
		if live_h > 1:
			clauses.append("• Deal [color=%s][b]%d × %d[/b][/color] damage ([b]%d total[/b])." % [d_col, live_d, live_h, live_d * live_h])
		else:
			clauses.append("• Deal [color=%s][b]%d[/b][/color] damage." % [d_col, live_d])

	if relic.base_block > 0 or live_b > 0:
		var b_col: String = "#67e68d" if blk_buffed else "#76d9ee"
		clauses.append("• Gain [color=%s][b]%d[/b][/color] persistent Block." % [b_col, live_b])

	if relic.multiply_current_block > 1.0:
		clauses.append("• Multiply your current Block by [color=#76d9ee][b]%.1f×[/b][/color]." % relic.multiply_current_block)
	if relic.damage_per_current_block_pct > 0.0:
		clauses.append("• Deals [color=#76d9ee][b]+%d%% of your current Block[/b][/color] as bonus attack damage." % roundi(relic.damage_per_current_block_pct * 100.0))
	if relic.thorns_to_damage_multiplier > 0.0:
		clauses.append("• Adds [color=#b76cff][b]%d× your Thorns[/b][/color] as bonus attack damage." % roundi(relic.thorns_to_damage_multiplier))
	if relic.damage_per_enemy_bleed > 0:
		clauses.append("• Deals [color=#58d66b][b]+%d damage[/b][/color] per enemy Bleed stack." % relic.damage_per_enemy_bleed)
	if relic.damage_per_banked_overkill_div > 0:
		clauses.append("• Deals [color=#c41734][b]+1 damage per %d[/b][/color] banked Overkill." % relic.damage_per_banked_overkill_div)
	if relic.sector_finisher_bonus_damage > 0:
		clauses.append("• [color=#ffd166][b]Sector Finisher (H3/6/9):[/b] +%d bonus damage.[/color]" % relic.sector_finisher_bonus_damage)
	if relic.sector_finisher_hits_bonus > 0:
		clauses.append("• [color=#ffd166][b]Sector Finisher (H3/6/9):[/b] +%d extra hit(s).[/color]" % relic.sector_finisher_hits_bonus)
	if relic.resonance_essence_bonus > 0:
		clauses.append("• [color=#80c8d1][b]Resonance:[/b] +%d power if preceding hour shares an Essence.[/color]" % relic.resonance_essence_bonus)
	if relic.echo_previous_hour:
		clauses.append("• [color=#d988ff][b]Echo:[/b] Re-triggers the preceding hour's bound relic.[/color]")
	if relic.charge_next_socket_multiplier > 0.0:
		clauses.append("• Permanently charges the next hour socket by [color=#ffd166][b]+%.1f×[/b][/color]." % relic.charge_next_socket_multiplier)
	if relic.apply_strength > 0:
		clauses.append("• Gain [color=#b76cff][b]+%d Strength[/b][/color]." % relic.apply_strength)
	if relic.apply_thorns > 0:
		clauses.append("• Gain [color=#b76cff][b]+%d Thorns[/b][/color]." % relic.apply_thorns)
	if relic.apply_vulnerable > 0:
		clauses.append("• Apply [color=#efb477][b]%d Vulnerable[/b][/color] to the enemy." % relic.apply_vulnerable)
	if relic.apply_weak > 0:
		clauses.append("• Apply [color=#84c8ae][b]%d Weak[/b][/color] to the enemy." % relic.apply_weak)
	if relic.apply_bleed > 0:
		clauses.append("• Apply [color=#58d66b][b]%d Bleed[/b][/color] to the enemy." % relic.apply_bleed)
	if relic.multiply_enemy_bleed > 1.0:
		clauses.append("• Multiply enemy Bleed stacks by [color=#58d66b][b]%.1f×[/b][/color]." % relic.multiply_enemy_bleed)
	if relic.trigger_bleed_times > 0:
		clauses.append("• Immediately triggers enemy Bleed [color=#58d66b][b]%d time(s)[/b][/color]." % relic.trigger_bleed_times)
	if relic.bonus_damage_next_hit > 0:
		clauses.append("• Next attack gains [color=#ffd166][b]+%d damage[/b][/color] per hit." % relic.bonus_damage_next_hit)
	if relic.next_attack_multiplier > 1:
		clauses.append("• Next attack deals [color=#d988ff][b]×%d damage[/b][/color]." % relic.next_attack_multiplier)
	if relic.conditional_damage > 0 and relic.conditional_hp_threshold_pct > 0.0:
		clauses.append("• Base damage becomes [color=#ff9e44][b]%d[/b][/color] when enemy HP is ≤%d%%." % [relic.conditional_damage, roundi(relic.conditional_hp_threshold_pct * 100.0)])
	if relic.lifesteal:
		clauses.append("• [color=#67e68d][b]Lifesteal:[/b][/color] Restore Vitality equal to unblocked HP damage dealt.")
	if relic.recoil_block_on_overkill:
		clauses.append("• Convert Overkill damage dealt into [color=#76d9ee][b]Block[/b][/color].")
	if relic.overkill_extraction_pct > 0.0:
		clauses.append("• Harvest [color=#c41734][b]%d%%[/b][/color] of unblocked damage as Overkill." % roundi(relic.overkill_extraction_pct * 100.0))
	if relic.grant_overkill > 0:
		clauses.append("• Gain [color=#c41734][b]+%d Overkill[/b][/color]." % relic.grant_overkill)

	if clauses.is_empty():
		return relic.description
	return "\n".join(clauses)


func _collect_relic_keywords(relic: ClockRelicData, out_keywords: Array[String]) -> void:
	if relic == null:
		return
	if relic.base_block > 0 or relic.multiply_current_block > 1.0 or relic.damage_per_current_block_pct > 0.0 or relic.recoil_block_on_overkill:
		_add_unique_keyword(out_keywords, "Block")
	if relic.apply_strength > 0:
		_add_unique_keyword(out_keywords, "Strength")
	if relic.apply_vulnerable > 0:
		_add_unique_keyword(out_keywords, "Vulnerable")
	if relic.apply_weak > 0:
		_add_unique_keyword(out_keywords, "Weak")
	if relic.apply_bleed > 0 or relic.multiply_enemy_bleed > 1.0 or relic.trigger_bleed_times > 0 or relic.damage_per_enemy_bleed > 0:
		_add_unique_keyword(out_keywords, "Bleed")
	if relic.apply_thorns > 0 or relic.thorns_to_damage_multiplier > 0.0:
		_add_unique_keyword(out_keywords, "Thorns")
	if relic.lifesteal:
		_add_unique_keyword(out_keywords, "Lifesteal")
	if relic.grant_overkill > 0 or relic.recoil_block_on_overkill or relic.damage_per_banked_overkill_div > 0 or relic.overkill_extraction_pct > 0.0:
		_add_unique_keyword(out_keywords, "Overkill")
	if relic.sector_finisher_bonus_damage > 0 or relic.sector_finisher_hits_bonus > 0:
		_add_unique_keyword(out_keywords, "Sector Finisher")
	if relic.resonance_essence_bonus > 0:
		_add_unique_keyword(out_keywords, "Resonance")
	if relic.echo_previous_hour:
		_add_unique_keyword(out_keywords, "Echo")
	if relic.charge_next_socket_multiplier > 0.0:
		_add_unique_keyword(out_keywords, "Socket Multiplier")
	if relic.next_attack_multiplier > 1 or relic.bonus_damage_next_hit > 0:
		_add_unique_keyword(out_keywords, "Overdrive")


static func _add_unique_keyword(arr: Array[String], kw: String) -> void:
	if not arr.has(kw):
		arr.append(kw)


static func _determine_clash_hours_for_socket(battle: Object, hour: int) -> Array:
	if battle == null:
		return [hour]
	if int(battle.get("phase")) == CombatController.Phase.QUADRANT:
		var q_hours: Array[int] = ChronometerView.get_quadrant_hours(int(battle.get("active_quadrant")))
		if q_hours.has(hour):
			return q_hours
	return [hour]


static func _resolve_default_target_hour(battle: Object) -> int:
	if battle == null:
		return 0
	if battle.has_method("get_target_assembly_hour"):
		return int(battle.call("get_target_assembly_hour"))
	var p_sockets: Variant = battle.get("player_sockets")
	var turn_h: int = clampi(int(battle.get("turn_number")), 1, 9)
	var sel: Variant = battle.get("selected_assembly_hour")
	if sel is int and int(sel) >= 1 and int(sel) <= 9:
		var sel_h: int = int(sel)
		if p_sockets is Array and (p_sockets as Array).size() >= sel_h:
			var sock: ClockSocketData = p_sockets[sel_h - 1]
			if sock != null and sock.slotted_relic == null and ((sel_h - 1) / 3) == ((turn_h - 1) / 3):
				return sel_h
	var priv_sel: Variant = battle.get("_selected_assembly_hour")
	if priv_sel is int and int(priv_sel) >= 1 and int(priv_sel) <= 9:
		var psel_h: int = int(priv_sel)
		if p_sockets is Array and (p_sockets as Array).size() >= psel_h:
			var sock2: ClockSocketData = p_sockets[psel_h - 1]
			if sock2 != null and sock2.slotted_relic == null:
				return psel_h
	if int(battle.get("phase")) == CombatController.Phase.ASSEMBLY:
		if p_sockets is Array and (p_sockets as Array).size() >= turn_h:
			var t_sock: ClockSocketData = p_sockets[turn_h - 1]
			if t_sock != null and t_sock.slotted_relic == null:
				return turn_h
			var sector_hours: Array[int] = ChronometerView.get_quadrant_hours(((turn_h - 1) / 3) + 1)
			for sh: int in sector_hours:
				var s_sock: ClockSocketData = p_sockets[sh - 1]
				if s_sock != null and s_sock.slotted_relic == null:
					return sh
		return turn_h
	return 0


static func _tier_name(tier: int) -> String:
	match tier:
		ClockRelicData.Tier.STARTER: return "STARTER RELIC"
		ClockRelicData.Tier.COMMON: return "COMMON RELIC"
		ClockRelicData.Tier.RARE: return "RARE RELIC"
		ClockRelicData.Tier.ZENITH: return "ZENITH RELIC"
		_: return "CLOCK RELIC"
