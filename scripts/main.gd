extends Node3D

const PlayerScript = preload("res://scripts/player.gd")
const EnemyScript = preload("res://scripts/enemy.gd")
const AllyScript = preload("res://scripts/ally.gd")
const JoystickScript = preload("res://scripts/virtual_joystick.gd")

var player: CharacterBody3D
var health_bar: ProgressBar
var health_text: Label
var victory_shown: bool = false

func _ready() -> void:
	_create_environment()
	_create_arena()
	_create_player()
	_create_enemies()
	_create_allies()
	_create_hud()

func _process(_delta: float) -> void:
	if not victory_shown and get_tree().get_nodes_in_group("enemies").is_empty():
		victory_shown = true
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
	sky_mat.sky_top_color = Color(0.025, 0.035, 0.12)
	sky_mat.sky_horizon_color = Color(0.16, 0.12, 0.24)
	sky_mat.ground_bottom_color = Color(0.025, 0.025, 0.05)
	sky_mat.ground_horizon_color = Color(0.12, 0.09, 0.16)
	sky.sky_material = sky_mat
	e.sky = sky
	e.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	e.ambient_light_color = Color(0.55, 0.58, 0.82)
	e.ambient_light_energy = 0.65
	e.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	env.environment = e
	add_child(env)

	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-48, -32, 0)
	sun.light_color = Color(0.72, 0.78, 1.0)
	sun.light_energy = 1.35
	sun.shadow_enabled = true
	add_child(sun)

func _create_arena() -> void:
	var floor := MeshInstance3D.new()
	var plane := PlaneMesh.new()
	plane.size = Vector2(34, 34)
	floor.mesh = plane
	floor.material_override = _mat(Color(0.13, 0.16, 0.22), 0.15, 0.9)
	floor.position.y = -0.12
	add_child(floor)

	# Ancient stone lanes and luminous rune lines.
	for i in range(-3, 4):
		var line := MeshInstance3D.new()
		var box := BoxMesh.new()
		box.size = Vector3(0.055, 0.018, 30.0)
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

	var attack := Button.new()
	attack.text = "АТАКА"
	attack.custom_minimum_size = Vector2(78, 56)
	attack.anchor_left = 1.0
	attack.anchor_right = 1.0
	attack.anchor_top = 1.0
	attack.anchor_bottom = 1.0
	attack.offset_left = -90
	attack.offset_right = -14
	attack.offset_top = -80
	attack.offset_bottom = -24
	layer.add_child(attack)
	attack.pressed.connect(player.attack)

	var skill_1 := Button.new()
	skill_1.text = "НАВ 1"
	skill_1.custom_minimum_size = Vector2(70, 56)
	skill_1.anchor_left = 1.0
	skill_1.anchor_right = 1.0
	skill_1.anchor_top = 1.0
	skill_1.anchor_bottom = 1.0
	skill_1.offset_left = -168
	skill_1.offset_right = -96
	skill_1.offset_top = -80
	skill_1.offset_bottom = -24
	layer.add_child(skill_1)
	skill_1.pressed.connect(player.use_skill_1)

	var skill_2 := Button.new()
	skill_2.text = "НАВ 2"
	skill_2.custom_minimum_size = Vector2(70, 56)
	skill_2.anchor_left = 1.0
	skill_2.anchor_right = 1.0
	skill_2.anchor_top = 1.0
	skill_2.anchor_bottom = 1.0
	skill_2.offset_left = -244
	skill_2.offset_right = -172
	skill_2.offset_top = -80
	skill_2.offset_bottom = -24
	layer.add_child(skill_2)
	skill_2.pressed.connect(player.use_skill_2)

	var ultimate := Button.new()
	ultimate.text = "УЛЬТА"
	ultimate.custom_minimum_size = Vector2(70, 56)
	ultimate.anchor_left = 1.0
	ultimate.anchor_right = 1.0
	ultimate.anchor_top = 1.0
	ultimate.anchor_bottom = 1.0
	ultimate.offset_left = -320
	ultimate.offset_right = -248
	ultimate.offset_top = -80
	ultimate.offset_bottom = -24
	layer.add_child(ultimate)
	ultimate.pressed.connect(player.use_ultimate)

	var title := Label.new()
	title.text = "LIPA ARENA  •  ДРЕВНИЕ РУИНЫ"
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
	var message := Label.new()
	message.text = "ПОРАЖЕНИЕ"
	message.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	message.add_theme_font_size_override("font_size", 42)
	message.add_theme_color_override("font_color", Color(1.0, 0.28, 0.2))
	get_node("CanvasLayer").add_child(message)
