extends Node3D

const PlayerScript = preload("res://scripts/player.gd")
const EnemyScript = preload("res://scripts/enemy.gd")
const AllyScript = preload("res://scripts/ally.gd")
const JoystickScript = preload("res://scripts/virtual_joystick.gd")
const ObjectiveScript = preload("res://scripts/objective.gd")
const MinionScript = preload("res://scripts/minion.gd")
const JungleMonsterScript = preload("res://scripts/jungle_monster.gd")

var player: CharacterBody3D
var health_bar: ProgressBar
var health_text: Label
var victory_shown: bool = false
var wave_timer: float = 18.0
var game_started: bool = false
var selected_game_mode: String = "Обычный матч"
var rank_points: int = 0

func _ready() -> void:
	_create_environment()
	_create_arena()
	_create_objectives()
	_create_jungle_camps()
	_create_player()
	_create_enemies()
	_create_allies()
	_spawn_wave()
	_create_hud()
	_load_rank_points()
	_show_mode_menu()

func _process(delta: float) -> void:
	if not game_started:
		return
	wave_timer -= delta
	if wave_timer <= 0.0:
		_spawn_wave()
		wave_timer = 18.0
	if not victory_shown and get_tree().get_nodes_in_group("enemy_throne").is_empty():
		victory_shown = true
		if selected_game_mode == "Ранговый матч":
			_save_rank_points(25)
		if is_instance_valid(player) and player.has_method("play_victory_pose"):
			player.play_victory_pose()
		var message := Label.new()
		message.text = "ПОБЕДА!"
		message.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
		message.add_theme_font_size_override("font_size", 44)
		message.add_theme_color_override("font_color", Color(0.35, 0.9, 1.0))
		get_node("CanvasLayer").add_child(message)

func _mat(color: Color, metallic: float = 0.0, roughness: float = 0.7) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = color
	m.metallic = metallic
	m.roughness = roughness
	return m

func _create_environment() -> void:
	var env := WorldEnvironment.new()
	var e := Environment.new()
	e.background_mode = Environment.BG_SKY
	var sky := Sky.new()
	var sky_mat := ProceduralSkyMaterial.new()
	sky_mat.sky_top_color = Color(0.16, 0.34, 0.55)
	sky_mat.sky_horizon_color = Color(0.62, 0.76, 0.78)
	sky_mat.ground_bottom_color = Color(0.12, 0.18, 0.12)
	sky_mat.ground_horizon_color = Color(0.34, 0.42, 0.30)
	sky.sky_material = sky_mat
	e.sky = sky
	e.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	e.ambient_light_color = Color(0.78, 0.88, 0.76)
	e.ambient_light_energy = 0.95
	e.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	e.glow_enabled = true
	e.glow_intensity = 0.28
	e.glow_bloom = 0.06
	e.ssao_enabled = true
	e.ssao_radius = 2.0
	e.ssao_intensity = 1.2
	env.environment = e
	add_child(env)

	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-52, -28, 0)
	sun.light_color = Color(1.0, 0.96, 0.84)
	sun.light_energy = 1.35
	sun.shadow_enabled = true
	sun.directional_shadow_max_distance = 55.0
	add_child(sun)

func _create_arena() -> void:
	var floor := MeshInstance3D.new()
	var plane := PlaneMesh.new()
	plane.size = Vector2(42, 42)
	floor.mesh = plane
	floor.material_override = _mat(Color(0.10, 0.24, 0.15), 0.0, 1.0)
	floor.position.y = -0.12
	add_child(floor)

	# Ancient stone lanes and luminous rune lines.
	for i in range(-3, 4):
		var line := MeshInstance3D.new()
		var box := BoxMesh.new()
		box.size = Vector3(0.055, 0.018, 38.0)
		line.mesh = box
		line.material_override = _mat(Color(0.15, 0.42, 0.85, 0.65), 0.3, 0.3)
		line.position = Vector3(float(i) * 3.5, -0.085, 0)
		add_child(line)

	_create_base(Vector3(0, 0, 12), Color(0.15, 0.55, 1.0))
	_create_base(Vector3(0, 0, -12), Color(1.0, 0.18, 0.16))
	_create_tower(Vector3(-3.8, 0, 6.0), Color(0.18, 0.55, 1.0))
	_create_tower(Vector3(3.8, 0, 6.0), Color(0.18, 0.55, 1.0))
	_create_tower(Vector3(-3.8, 0, -6.0), Color(1.0, 0.22, 0.16))
	_create_tower(Vector3(3.8, 0, -6.0), Color(1.0, 0.22, 0.16))

	# Ruined pillars around the battlefield.
	for x in [-14.0, 14.0]:
		for z in [-10.0, -3.0, 4.0, 11.0]:
			_create_pillar(Vector3(x, 0, z))

	# Crystal lamps.
	for p in [Vector3(-7, 0, -7), Vector3(7, 0, -7), Vector3(-7, 0, 7), Vector3(7, 0, 7)]:
		_create_crystal(p)

	_create_lane_paths()
	_create_river_and_bridges()
	_create_forest_border()
	_create_ground_details()
	_create_lane_lamps()
	_create_arena_landmarks()

func _create_base(pos: Vector3, glow: Color) -> void:
	var platform := MeshInstance3D.new()
	var cyl := CylinderMesh.new()
	cyl.top_radius = 3.0
	cyl.bottom_radius = 3.4
	cyl.height = 0.45
	platform.mesh = cyl
	platform.position = pos + Vector3(0, 0.05, 0)
	platform.material_override = _mat(Color(0.18, 0.2, 0.3), 0.45, 0.4)
	add_child(platform)

	var crystal := MeshInstance3D.new()
	var mesh := PrismMesh.new()
	mesh.size = Vector3(1.1, 2.7, 1.1)
	crystal.mesh = mesh
	crystal.position = pos + Vector3(0, 1.7, 0)
	crystal.rotation_degrees = Vector3(0, 45, 0)
	var cm := _mat(glow, 0.25, 0.18)
	cm.emission_enabled = true
	cm.emission = glow
	cm.emission_energy_multiplier = 1.8
	crystal.material_override = cm
	add_child(crystal)

func _create_tower(pos: Vector3, glow: Color) -> void:
	var base := MeshInstance3D.new()
	var base_mesh := CylinderMesh.new()
	base_mesh.top_radius = 0.85
	base_mesh.bottom_radius = 1.1
	base_mesh.height = 0.45
	base.mesh = base_mesh
	base.position = pos + Vector3(0, 0.22, 0)
	base.material_override = _mat(Color(0.22, 0.25, 0.36), 0.55, 0.35)
	add_child(base)

	var shaft := MeshInstance3D.new()
	var shaft_mesh := CylinderMesh.new()
	shaft_mesh.top_radius = 0.38
	shaft_mesh.bottom_radius = 0.62
	shaft_mesh.height = 2.1
	shaft.mesh = shaft_mesh
	shaft.position = pos + Vector3(0, 1.45, 0)
	shaft.material_override = _mat(Color(0.34, 0.37, 0.5), 0.5, 0.4)
	add_child(shaft)

	var crystal := MeshInstance3D.new()
	var crystal_mesh := PrismMesh.new()
	crystal_mesh.size = Vector3(0.65, 1.0, 0.65)
	crystal.mesh = crystal_mesh
	crystal.position = pos + Vector3(0, 2.85, 0)
	var cm := _mat(glow, 0.25, 0.18)
	cm.emission_enabled = true
	cm.emission = glow
	cm.emission_energy_multiplier = 2.4
	crystal.material_override = cm
	add_child(crystal)

func _create_pillar(pos: Vector3) -> void:
	var body := MeshInstance3D.new()
	var mesh := CylinderMesh.new()
	mesh.top_radius = 0.48
	mesh.bottom_radius = 0.62
	mesh.height = 3.8
	body.mesh = mesh
	body.position = pos + Vector3(0, 1.8, 0)
	body.material_override = _mat(Color(0.27, 0.29, 0.39), 0.35, 0.75)
	add_child(body)

	var cap := MeshInstance3D.new()
	var cap_mesh := BoxMesh.new()
	cap_mesh.size = Vector3(1.35, 0.28, 1.35)
	cap.mesh = cap_mesh
	cap.position = pos + Vector3(0, 3.75, 0)
	cap.material_override = _mat(Color(0.55, 0.48, 0.34), 0.55, 0.35)
	add_child(cap)

func _create_crystal(pos: Vector3) -> void:
	var crystal := MeshInstance3D.new()
	var mesh := PrismMesh.new()
	mesh.size = Vector3(0.65, 1.5, 0.65)
	crystal.mesh = mesh
	crystal.position = pos + Vector3(0, 1.0, 0)
	crystal.rotation_degrees.y = 45
	var m := _mat(Color(0.25, 0.75, 1.0), 0.15, 0.2)
	m.emission_enabled = true
	m.emission = Color(0.08, 0.45, 1.0)
	m.emission_energy_multiplier = 2.0
	crystal.material_override = m
	add_child(crystal)

	var light := OmniLight3D.new()
	light.position = pos + Vector3(0, 1.5, 0)
	light.light_color = Color(0.15, 0.5, 1.0)
	light.light_energy = 0.8
	light.omni_range = 5.0
	add_child(light)

func _create_objectives() -> void:
	# Nine defensive towers: three on each of the three lanes.
	for lane_x in [-7.0, 0.0, 7.0]:
		for tower_z in [-2.0, -5.0, -8.0]:
			var tower := Node3D.new()
			tower.name = "RedTower_%s_%s" % [str(lane_x), str(tower_z)]
			tower.set_script(ObjectiveScript)
			tower.position = Vector3(lane_x, 0.0, tower_z)
			add_child(tower)
	var throne := Node3D.new()
	throne.name = "RedThrone"
	throne.set_script(ObjectiveScript)
	throne.set("is_throne", true)
	throne.set("max_health", 5000)
	throne.set("health", 5000)
	throne.position = Vector3(0, 0, -11.2)
	add_child(throne)

func _spawn_wave() -> void:
	for lane_x in [-7.0, 0.0, 7.0]:
		for i in range(3):
			var blue := CharacterBody3D.new()
			blue.name = "BlueMinion"
			blue.set_script(MinionScript)
			blue.set("team", "blue")
			blue.set("lane_x", lane_x)
			blue.position = Vector3(lane_x + (float(i) - 1.0) * 0.55, 0.0, 9.0 + float(i) * 0.7)
			add_child(blue)
			var red := CharacterBody3D.new()
			red.name = "RedMinion"
			red.set_script(MinionScript)
			red.set("team", "red")
			red.set("lane_x", lane_x)
			red.position = Vector3(lane_x + (float(i) - 1.0) * 0.55, 0.0, -9.0 - float(i) * 0.7)
			add_child(red)

func _create_jungle_camps() -> void:
	# Four neutral camps in the forest. Each camp grants a distinct temporary buff.
	var camps := [
		{"name": "EMBER_GUARDIAN", "buff": "ember", "label": "СТРАЖ ПЛАМЕНИ", "color": Color(1.0, 0.30, 0.10), "pos": Vector3(-11.0, 0.0, 5.0)},
		{"name": "FROST_GUARDIAN", "buff": "frost", "label": "ЛЕДЯНОЙ СТРАЖ", "color": Color(0.20, 0.75, 1.0), "pos": Vector3(11.0, 0.0, -5.0)},
		{"name": "WILD_GUARDIAN", "buff": "wild", "label": "ДУХ ЛЕСА", "color": Color(0.25, 0.90, 0.38), "pos": Vector3(-11.0, 0.0, -5.0)},
		{"name": "ARCANE_GUARDIAN", "buff": "arcane", "label": "АРКАННЫЙ ГОЛЕМ", "color": Color(0.72, 0.35, 1.0), "pos": Vector3(11.0, 0.0, 5.0)}
	]
	for camp in camps:
		var monster := CharacterBody3D.new()
		monster.name = str(camp["name"])
		monster.set_script(JungleMonsterScript)
		monster.set("buff_type", str(camp["buff"]))
		monster.set("monster_title", str(camp["label"]))
		monster.set("glow_color", camp["color"])
		monster.position = camp["pos"]
		add_child(monster)

func _load_rank_points() -> void:
	var config := ConfigFile.new()
	if config.load("user://lipa_rank.cfg") == OK:
		rank_points = int(config.get_value("ranked", "points", 0))

func _save_rank_points(change: int) -> void:
	rank_points = maxi(rank_points + change, 0)
	var config := ConfigFile.new()
	config.set_value("ranked", "points", rank_points)
	config.save("user://lipa_rank.cfg")

func _show_mode_menu() -> void:
	get_tree().paused = true
	var layer := get_node("CanvasLayer") as CanvasLayer
	var overlay := Control.new()
	overlay.name = "ModeMenu"
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.process_mode = Node.PROCESS_MODE_ALWAYS
	layer.add_child(overlay)

	var shade := ColorRect.new()
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	shade.color = Color(0.015, 0.025, 0.07, 0.94)
	shade.mouse_filter = Control.MOUSE_FILTER_STOP
	overlay.add_child(shade)

	var panel := PanelContainer.new()
	panel.anchor_left = 0.5
	panel.anchor_right = 0.5
	panel.anchor_top = 0.5
	panel.anchor_bottom = 0.5
	panel.offset_left = -190
	panel.offset_right = 190
	panel.offset_top = -245
	panel.offset_bottom = 245
	overlay.add_child(panel)

	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 14)
	panel.add_child(column)

	var title := Label.new()
	title.text = "LIPA ARENA"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 34)
	title.add_theme_color_override("font_color", Color(0.55, 0.82, 1.0))
	column.add_child(title)

	var subtitle := Label.new()
	subtitle.text = "ВЫБЕРИ РЕЖИМ БОЯ"
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	subtitle.add_theme_font_size_override("font_size", 17)
	column.add_child(subtitle)

	var rank_label := Label.new()
	rank_label.text = "РЕЙТИНГ: %d ОЧКОВ" % rank_points
	rank_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	rank_label.add_theme_color_override("font_color", Color(1.0, 0.78, 0.32))
	column.add_child(rank_label)

	var normal_button := Button.new()
	normal_button.text = "ОБЫЧНЫЙ МАТЧ  •  5 НА 5"
	_style_mode_button(normal_button, Color(0.10, 0.30, 0.58), Color(0.35, 0.72, 1.0))
	normal_button.custom_minimum_size = Vector2(330, 58)
	column.add_child(normal_button)
	normal_button.pressed.connect(_start_game.bind("Обычный матч"))

	var ranked_button := Button.new()
	ranked_button.text = "РАНГОВЫЙ МАТЧ  •  +25 / -15"
	_style_mode_button(ranked_button, Color(0.43, 0.27, 0.08), Color(1.0, 0.72, 0.25))
	ranked_button.custom_minimum_size = Vector2(330, 58)
	column.add_child(ranked_button)
	ranked_button.pressed.connect(_start_game.bind("Ранговый матч"))

	var ai_button := Button.new()
	ai_button.text = "ПРОТИВ КОМПЬЮТЕРА"
	_style_mode_button(ai_button, Color(0.17, 0.22, 0.38), Color(0.55, 0.68, 1.0))
	ai_button.custom_minimum_size = Vector2(330, 58)
	column.add_child(ai_button)
	ai_button.pressed.connect(_start_game.bind("Против компьютера"))

	var note := Label.new()
	note.text = "Одиночная версия: соперники управляются ИИ."
	note.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	note.add_theme_font_size_override("font_size", 12)
	note.add_theme_color_override("font_color", Color(0.68, 0.72, 0.82))
	column.add_child(note)

func _style_mode_button(button: Button, base_color: Color, accent: Color) -> void:
	button.add_theme_font_size_override("font_size", 16)
	button.add_theme_color_override("font_color", Color(0.96, 0.97, 1.0))
	var normal := StyleBoxFlat.new()
	normal.bg_color = base_color
	normal.border_color = accent
	normal.set_border_width_all(2)
	normal.set_corner_radius_all(14)
	normal.content_margin_left = 12.0
	normal.content_margin_right = 12.0
	normal.content_margin_top = 10.0
	normal.content_margin_bottom = 10.0
	button.add_theme_stylebox_override("normal", normal)
	var hover := normal.duplicate() as StyleBoxFlat
	hover.bg_color = base_color.lightened(0.16)
	button.add_theme_stylebox_override("hover", hover)
	var pressed := normal.duplicate() as StyleBoxFlat
	pressed.bg_color = base_color.darkened(0.18)
	button.add_theme_stylebox_override("pressed", pressed)

func _start_game(mode: String) -> void:
	selected_game_mode = mode
	game_started = true
	get_tree().paused = false
	var menu := get_node_or_null("CanvasLayer/ModeMenu")
	if menu != null:
		menu.queue_free()
	var mode_label := Label.new()
	mode_label.text = selected_game_mode.to_upper()
	mode_label.position = Vector2(18, 112)
	mode_label.add_theme_font_size_override("font_size", 13)
	mode_label.add_theme_color_override("font_color", Color(1.0, 0.78, 0.32))
	get_node("CanvasLayer").add_child(mode_label)

func _create_player() -> void:
	player = CharacterBody3D.new()
	player.name = "Kairon"
	player.set_script(PlayerScript)
	player.position = Vector3(0, 0.15, 7)
	add_child(player)

	var camera := Camera3D.new()
	camera.position = Vector3(0, 13, 17)
	camera.rotation_degrees = Vector3(-36, 0, 0)
	camera.current = true
	player.add_child(camera)

func _create_enemies() -> void:
	for i in range(5):
		var enemy := CharacterBody3D.new()
		enemy.name = "RedBot%d" % i
		enemy.set_script(EnemyScript)
		enemy.position = Vector3(-5.0 + float(i) * 2.5, 0.15, -7.0 - float(i % 2) * 1.4)
		add_child(enemy)

func _create_allies() -> void:
	for i in range(4):
		var ally := CharacterBody3D.new()
		ally.name = "BlueAlly%d" % i
		ally.set_script(AllyScript)
		ally.position = Vector3(-2.2 + float(i) * 1.45, 0.15, 8.5 + float(i % 2) * 1.3)
		ally.set("lane_offset", Vector3(-2.0 + float(i) * 1.3, 0, 2.0))
		add_child(ally)

func _create_hud() -> void:
	var layer := CanvasLayer.new()
	layer.name = "CanvasLayer"
	add_child(layer)

	var joystick := Control.new()
	joystick.set_script(JoystickScript)
	joystick.position = Vector2(24, 0)
	joystick.anchor_top = 1.0
	joystick.anchor_bottom = 1.0
	joystick.offset_top = -205
	joystick.offset_bottom = -25
	joystick.custom_minimum_size = Vector2(180, 180)
	layer.add_child(joystick)

	# Large touch targets for comfortable play on phone screens.
	var attack := Button.new()
	attack.text = "АТАКА"
	attack.custom_minimum_size = Vector2(96, 92)
	attack.add_theme_font_size_override("font_size", 17)
	attack.anchor_left = 1.0
	attack.anchor_right = 1.0
	attack.anchor_top = 1.0
	attack.anchor_bottom = 1.0
	attack.offset_left = -108
	attack.offset_right = -12
	attack.offset_top = -116
	attack.offset_bottom = -24
	layer.add_child(attack)
	attack.pressed.connect(player.attack)

	var skill_1 := Button.new()
	skill_1.text = "НАВ 1"
	skill_1.custom_minimum_size = Vector2(82, 82)
	skill_1.add_theme_font_size_override("font_size", 15)
	skill_1.anchor_left = 1.0
	skill_1.anchor_right = 1.0
	skill_1.anchor_top = 1.0
	skill_1.anchor_bottom = 1.0
	skill_1.offset_left = -198
	skill_1.offset_right = -116
	skill_1.offset_top = -106
	skill_1.offset_bottom = -24
	layer.add_child(skill_1)
	skill_1.pressed.connect(player.use_skill_1)

	var skill_2 := Button.new()
	skill_2.text = "НАВ 2"
	skill_2.custom_minimum_size = Vector2(82, 82)
	skill_2.add_theme_font_size_override("font_size", 15)
	skill_2.anchor_left = 1.0
	skill_2.anchor_right = 1.0
	skill_2.anchor_top = 1.0
	skill_2.anchor_bottom = 1.0
	skill_2.offset_left = -288
	skill_2.offset_right = -206
	skill_2.offset_top = -106
	skill_2.offset_bottom = -24
	layer.add_child(skill_2)
	skill_2.pressed.connect(player.use_skill_2)

	var ultimate := Button.new()
	ultimate.text = "УЛЬТА"
	ultimate.custom_minimum_size = Vector2(82, 82)
	ultimate.add_theme_font_size_override("font_size", 15)
	ultimate.anchor_left = 1.0
	ultimate.anchor_right = 1.0
	ultimate.anchor_top = 1.0
	ultimate.anchor_bottom = 1.0
	ultimate.offset_left = -378
	ultimate.offset_right = -296
	ultimate.offset_top = -106
	ultimate.offset_bottom = -24
	layer.add_child(ultimate)
	ultimate.pressed.connect(player.use_ultimate)

	var title := Label.new()
	title.text = "LIPA ARENA  •  ЗАТЕРЯННОЕ КОРОЛЕВСТВО"
	title.position = Vector2(18, 12)
	title.add_theme_font_size_override("font_size", 18)
	title.add_theme_color_override("font_color", Color(0.75, 0.85, 1.0))
	layer.add_child(title)

	health_text = Label.new()
	health_text.text = "КАЙРОН  500 / 500 HP"
	health_text.position = Vector2(18, 42)
	health_text.add_theme_font_size_override("font_size", 16)
	health_text.add_theme_color_override("font_color", Color(0.65, 0.86, 1.0))
	layer.add_child(health_text)

	health_bar = ProgressBar.new()
	health_bar.position = Vector2(18, 66)
	health_bar.size = Vector2(220, 18)
	health_bar.max_value = 500
	health_bar.value = 500
	health_bar.show_percentage = false
	layer.add_child(health_bar)

	var hero_picker := OptionButton.new()
	hero_picker.position = Vector2(18, 92)
	hero_picker.custom_minimum_size = Vector2(180, 42)
	for hero_title in ["Кайрон", "Элиара", "Рейн", "Нокса", "Гардон", "Бьёрн"]:
		hero_picker.add_item(hero_title)
	layer.add_child(hero_picker)
	hero_picker.item_selected.connect(_on_hero_selected)

	player.health_changed.connect(_update_health_ui)
	player.player_defeated.connect(_show_defeat)

	var team_label := Label.new()
	team_label.text = "СИНИЕ 5  ×  КРАСНЫЕ 5"
	team_label.anchor_left = 0.5
	team_label.anchor_right = 0.5
	team_label.offset_left = -95
	team_label.offset_right = 95
	team_label.offset_top = 14
	team_label.offset_bottom = 40
	team_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	team_label.add_theme_font_size_override("font_size", 15)
	team_label.add_theme_color_override("font_color", Color(0.85, 0.88, 1.0))
	layer.add_child(team_label)

	var map := Control.new()
	map.set_script(load("res://scripts/minimap.gd"))
	map.anchor_left = 1.0
	map.anchor_right = 1.0
	map.offset_left = -174
	map.offset_right = -14
	map.offset_top = 50
	map.offset_bottom = 166
	map.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.add_child(map)

func _update_health_ui(current: int, maximum: int) -> void:
	if is_instance_valid(health_bar):
		health_bar.max_value = maximum
		health_bar.value = current
	if is_instance_valid(health_text):
		health_text.text = "%s  %d / %d HP" % [player.hero_name, current, maximum]

func _on_hero_selected(index: int) -> void:
	if is_instance_valid(player) and player.has_method("set_hero"):
		player.set_hero(index)
		_update_health_ui(player.health, player.max_health)

func _show_defeat() -> void:
	if selected_game_mode == "Ранговый матч":
		_save_rank_points(-15)
	var message := Label.new()
	message.text = "ПОРАЖЕНИЕ"
	message.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	message.add_theme_font_size_override("font_size", 42)
	message.add_theme_color_override("font_color", Color(1.0, 0.28, 0.2))
	get_node("CanvasLayer").add_child(message)


func _create_lane_paths() -> void:
	# Three broad stone roads, kept clear for minions and heroes.
	for lane_x in [-7.0, 0.0, 7.0]:
		var road := MeshInstance3D.new()
		var road_mesh := BoxMesh.new()
		road_mesh.size = Vector3(3.4, 0.10, 38.0)
		road.mesh = road_mesh
		road.position = Vector3(lane_x, -0.035, 0.0)
		road.material_override = _mat(Color(0.43, 0.42, 0.38), 0.08, 0.96)
		add_child(road)
		for side in [-1.0, 1.0]:
			var edge := MeshInstance3D.new()
			var edge_mesh := BoxMesh.new()
			edge_mesh.size = Vector3(0.12, 0.035, 37.5)
			edge.mesh = edge_mesh
			edge.position = Vector3(lane_x + side * 1.42, 0.035, 0.0)
			edge.material_override = _mat(Color(0.62, 0.53, 0.34), 0.25, 0.65)
			add_child(edge)

func _create_river_and_bridges() -> void:
	# A shallow decorative river crosses the arena; bridges align with all three lanes.
	var river := MeshInstance3D.new()
	var river_mesh := BoxMesh.new()
	river_mesh.size = Vector3(33.0, 0.045, 2.0)
	river.mesh = river_mesh
	river.position = Vector3(0.0, -0.075, 0.0)
	var water := _mat(Color(0.035, 0.30, 0.48, 0.92), 0.35, 0.20)
	water.emission_enabled = true
	water.emission = Color(0.015, 0.12, 0.22)
	water.emission_energy_multiplier = 0.45
	river.material_override = water
	add_child(river)

	for lane_x in [-7.0, 0.0, 7.0]:
		var bridge := MeshInstance3D.new()
		var bridge_mesh := BoxMesh.new()
		bridge_mesh.size = Vector3(3.45, 0.20, 2.75)
		bridge.mesh = bridge_mesh
		bridge.position = Vector3(lane_x, 0.045, 0.0)
		bridge.material_override = _mat(Color(0.62, 0.55, 0.43), 0.08, 0.92)
		add_child(bridge)
		for side in [-1.0, 1.0]:
			var rail := MeshInstance3D.new()
			var rail_mesh := BoxMesh.new()
			rail_mesh.size = Vector3(0.16, 0.28, 2.65)
			rail.mesh = rail_mesh
			rail.position = Vector3(lane_x + side * 1.58, 0.22, 0.0)
			rail.material_override = _mat(Color(0.34, 0.37, 0.46), 0.45, 0.55)
			add_child(rail)

func _create_forest_border() -> void:
	# Dense, layered jungle canopy along both outer sides of the three-lane arena.
	var trunk_mat := _mat(Color(0.22, 0.12, 0.075), 0.0, 1.0)
	var leaf_mats := [
		_mat(Color(0.035, 0.19, 0.09), 0.0, 0.92),
		_mat(Color(0.055, 0.29, 0.12), 0.0, 0.88),
		_mat(Color(0.12, 0.36, 0.14), 0.0, 0.9),
		_mat(Color(0.18, 0.40, 0.16), 0.0, 0.95)
	]
	for side in [-1.0, 1.0]:
		for row in range(3):
			var tree_x: float = side * (13.8 + float(row) * 2.35)
			for index in range(9):
				var z := -19.0 + float(index) * 4.7 + float(row % 2) * 1.9
				if absf(z) < 2.4 and row == 0:
					continue
				var tree := Node3D.new()
				tree.position = Vector3(tree_x, 0.0, z)
				tree.rotation_degrees.y = float((index * 37 + row * 19) % 360)
				add_child(tree)

				var trunk := MeshInstance3D.new()
				var trunk_mesh := CylinderMesh.new()
				trunk_mesh.top_radius = 0.18 + float(index % 3) * 0.035
				trunk_mesh.bottom_radius = 0.34 + float(index % 2) * 0.06
				trunk_mesh.height = 2.8 + float(index % 3) * 0.35
				trunk.mesh = trunk_mesh
				trunk.position.y = trunk_mesh.height * 0.5
				trunk.material_override = trunk_mat
				tree.add_child(trunk)

				for crown_index in range(4):
					var crown := MeshInstance3D.new()
					var crown_mesh := SphereMesh.new()
					crown_mesh.radius = 1.35 - float(crown_index % 2) * 0.16
					crown_mesh.height = 2.0
					crown.mesh = crown_mesh
					crown.position = Vector3(
						cos(float(crown_index) * 1.57) * 0.68,
						2.45 + float(crown_index % 2) * 0.72,
						sin(float(crown_index) * 1.57) * 0.68
					)
					crown.scale = Vector3(1.0, 0.82, 1.0)
					crown.material_override = leaf_mats[(index + row + crown_index) % leaf_mats.size()]
					tree.add_child(crown)

				# Hanging roots and small branches give trunks a less geometric silhouette.
				for branch_index in range(3):
					var branch := MeshInstance3D.new()
					var branch_mesh := CylinderMesh.new()
					branch_mesh.top_radius = 0.055
					branch_mesh.bottom_radius = 0.12
					branch_mesh.height = 1.0
					branch.mesh = branch_mesh
					branch.position = Vector3(0.0, 1.65, 0.0)
					branch.rotation_degrees = Vector3(0.0, float(branch_index) * 120.0, 32.0)
					branch.material_override = trunk_mat
					tree.add_child(branch)

	# Bush clusters mark jungle entrances and safe pockets beside each lane.
	for side in [-1.0, 1.0]:
		for z in [-13.0, -7.0, 0.0, 7.0, 13.0]:
			var bush_group := Node3D.new()
			bush_group.position = Vector3(side * 10.0, 0.0, z)
			add_child(bush_group)
			for part in range(5):
				var bush := MeshInstance3D.new()
				var bush_mesh := SphereMesh.new()
				bush_mesh.radius = 0.72 + float(part % 2) * 0.12
				bush_mesh.height = 1.15
				bush.mesh = bush_mesh
				bush.position = Vector3(float(part - 2) * 0.52, 0.45, float((part % 2) - 0.5) * 0.62)
				bush.material_override = leaf_mats[(part + 1) % leaf_mats.size()]
				bush_group.add_child(bush)

	# Rocky outcrops and broken columns at the four corners.
	for corner_x in [-1.0, 1.0]:
		for corner_z in [-1.0, 1.0]:
			var rock_cluster := Node3D.new()
			rock_cluster.position = Vector3(corner_x * 18.0, 0.0, corner_z * 18.0)
			add_child(rock_cluster)
			for rock_index in range(4):
				var rock := MeshInstance3D.new()
				var rock_mesh := SphereMesh.new()
				rock_mesh.radius = 0.8 + float(rock_index % 2) * 0.35
				rock_mesh.height = 1.1
				rock.mesh = rock_mesh
				rock.position = Vector3(float(rock_index % 2) * 1.1, 0.45, float(rock_index - 2) * 0.65)
				rock.scale = Vector3(1.35, 0.8, 1.0)
				rock.material_override = _mat(Color(0.24, 0.29, 0.25), 0.04, 0.96)
				rock_cluster.add_child(rock)

func _create_ground_details() -> void:
	# Low-poly grass, flowers and mossy stones make the jungle feel less empty.
	var grass_materials := [
		_mat(Color(0.12, 0.34, 0.16), 0.0, 1.0),
		_mat(Color(0.18, 0.42, 0.19), 0.0, 1.0),
		_mat(Color(0.25, 0.46, 0.20), 0.0, 1.0)
	]
	var flower_materials := [
		_mat(Color(1.0, 0.78, 0.30), 0.0, 0.8),
		_mat(Color(0.82, 0.48, 0.82), 0.0, 0.8),
		_mat(Color(0.90, 0.88, 0.72), 0.0, 0.8)
	]
	for side in [-1.0, 1.0]:
		for row in range(9):
			var z := -14.0 + float(row) * 3.5
			for offset in [-1.1, 0.0, 1.1]:
				var tuft := Node3D.new()
				tuft.position = Vector3(side * (11.8 + absf(offset)), 0.0, z + offset * 0.45)
				add_child(tuft)
				for blade in range(3):
					var grass := MeshInstance3D.new()
					var blade_mesh := CylinderMesh.new()
					blade_mesh.top_radius = 0.015
					blade_mesh.bottom_radius = 0.075
					blade_mesh.height = 0.48 + float((row + blade) % 3) * 0.12
					grass.mesh = blade_mesh
					grass.position = Vector3(float(blade - 1) * 0.10, blade_mesh.height * 0.5, 0.0)
					grass.rotation_degrees = Vector3(0.0, float(blade) * 55.0, float(blade - 1) * 13.0)
					grass.material_override = grass_materials[(row + blade) % grass_materials.size()]
					tuft.add_child(grass)
			if row % 2 == 0:
				var flower := MeshInstance3D.new()
				var flower_mesh := SphereMesh.new()
				flower_mesh.radius = 0.10
				flower_mesh.height = 0.16
				flower.mesh = flower_mesh
				flower.position = Vector3(side * 10.9, 0.18, z + 0.8)
				flower.material_override = flower_materials[row % flower_materials.size()]
				add_child(flower)

	# Mossy stones and small ruins decorate the jungle edges without blocking lanes.
	for side in [-1.0, 1.0]:
		for z in [-11.5, -6.5, -1.5, 3.5, 8.5, 13.0]:
			var stone := MeshInstance3D.new()
			var stone_mesh := SphereMesh.new()
			stone_mesh.radius = 0.48
			stone_mesh.height = 0.62
			stone.mesh = stone_mesh
			stone.position = Vector3(side * 12.7, 0.28, z)
			stone.scale = Vector3(1.35, 0.72, 0.9)
			stone.material_override = _mat(Color(0.27, 0.32, 0.27), 0.05, 1.0)
			add_child(stone)

	# Small reflective stepping stones near the river banks.
	for lane_x in [-7.0, 0.0, 7.0]:
		for side in [-1.0, 1.0]:
			var pebble := MeshInstance3D.new()
			var pebble_mesh := CylinderMesh.new()
			pebble_mesh.top_radius = 0.22
			pebble_mesh.bottom_radius = 0.28
			pebble_mesh.height = 0.10
			pebble.mesh = pebble_mesh
			pebble.position = Vector3(lane_x + side * 2.15, 0.015, side * 1.45)
			pebble.material_override = _mat(Color(0.42, 0.48, 0.48), 0.18, 0.42)
			add_child(pebble)

func _create_lane_lamps() -> void:
	# Warm lights mark the approaches to the river bridges.
	for lane_x in [-7.0, 0.0, 7.0]:
		for side in [-1.0, 1.0]:
			var lamp := MeshInstance3D.new()
			var lamp_mesh := CylinderMesh.new()
			lamp_mesh.top_radius = 0.10
			lamp_mesh.bottom_radius = 0.16
			lamp_mesh.height = 0.75
			lamp.mesh = lamp_mesh
			lamp.position = Vector3(lane_x + side * 2.15, 0.38, side * 1.85)
			lamp.material_override = _mat(Color(0.38, 0.31, 0.22), 0.35, 0.55)
			add_child(lamp)

			var flame := MeshInstance3D.new()
			var flame_mesh := SphereMesh.new()
			flame_mesh.radius = 0.20
			flame_mesh.height = 0.38
			flame.mesh = flame_mesh
			flame.position = lamp.position + Vector3(0.0, 0.48, 0.0)
			var glow := _mat(Color(1.0, 0.58, 0.20), 0.0, 0.25)
			glow.emission_enabled = true
			glow.emission = Color(1.0, 0.28, 0.06)
			glow.emission_energy_multiplier = 1.4
			flame.material_override = glow
			add_child(flame)


func _create_arena_landmarks() -> void:
	# Natural riverbanks: layered stones and reeds soften the straight river edge.
	var bank_mat := _mat(Color(0.30, 0.36, 0.29), 0.02, 1.0)
	var reed_mat := _mat(Color(0.22, 0.43, 0.17), 0.0, 1.0)
	for side in [-1.0, 1.0]:
		for i in range(18):
			var z := -1.9 + float(i) * 0.22
			var stone := MeshInstance3D.new()
			var stone_mesh := SphereMesh.new()
			stone_mesh.radius = 0.22 + float(i % 3) * 0.07
			stone_mesh.height = 0.28
			stone.mesh = stone_mesh
			stone.position = Vector3(side * (16.0 + float(i % 2) * 0.25), -0.01, z)
			stone.scale = Vector3(1.6, 0.65, 0.9)
			stone.material_override = bank_mat
			add_child(stone)

	# Ancient jungle shrines sit beside, not on, the playable lanes.
	for side in [-1.0, 1.0]:
		for z in [-14.0, -4.5, 4.5, 14.0]:
			var shrine := Node3D.new()
			shrine.position = Vector3(side * 10.9, 0.0, z)
			shrine.rotation_degrees.y = side * -12.0
			add_child(shrine)

			var plinth := MeshInstance3D.new()
			var plinth_mesh := BoxMesh.new()
			plinth_mesh.size = Vector3(1.8, 0.35, 1.5)
			plinth.mesh = plinth_mesh
			plinth.position.y = 0.18
			plinth.material_override = _mat(Color(0.34, 0.37, 0.31), 0.08, 0.92)
			shrine.add_child(plinth)

			for pillar_side in [-1.0, 1.0]:
				var pillar := MeshInstance3D.new()
				var pillar_mesh := CylinderMesh.new()
				pillar_mesh.top_radius = 0.18
				pillar_mesh.bottom_radius = 0.27
				pillar_mesh.height = 1.75
				pillar.mesh = pillar_mesh
				pillar.position = Vector3(pillar_side * 0.62, 1.05, 0.0)
				pillar.material_override = _mat(Color(0.40, 0.43, 0.35), 0.12, 0.86)
				shrine.add_child(pillar)

			var lintel := MeshInstance3D.new()
			var lintel_mesh := BoxMesh.new()
			lintel_mesh.size = Vector3(1.75, 0.28, 0.48)
			lintel.mesh = lintel_mesh
			lintel.position = Vector3(0.0, 2.0, 0.0)
			lintel.material_override = _mat(Color(0.46, 0.44, 0.34), 0.10, 0.82)
			shrine.add_child(lintel)

			var moss := MeshInstance3D.new()
			var moss_mesh := SphereMesh.new()
			moss_mesh.radius = 0.38
			moss_mesh.height = 0.25
			moss.mesh = moss_mesh
			moss.position = Vector3(0.0, 0.42, 0.0)
			moss.scale = Vector3(1.8, 0.5, 1.1)
			moss.material_override = reed_mat
			shrine.add_child(moss)

	# Small patches of varied ground color break up the flat green floor.
	var patch_colors := [
		Color(0.13, 0.29, 0.14),
		Color(0.17, 0.33, 0.15),
		Color(0.22, 0.36, 0.16)
	]
	for side in [-1.0, 1.0]:
		for i in range(7):
			var patch := MeshInstance3D.new()
			var patch_mesh := SphereMesh.new()
			patch_mesh.radius = 1.0
			patch_mesh.height = 0.12
			patch.mesh = patch_mesh
			patch.position = Vector3(side * (11.0 + float(i % 3) * 1.3), -0.045, -15.0 + float(i) * 4.8)
			patch.scale = Vector3(1.8, 0.18, 1.15)
			patch.material_override = _mat(patch_colors[i % patch_colors.size()], 0.0, 1.0)
			add_child(patch)
