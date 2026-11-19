extends Node3D

const TEAM_BLUE := Color(0.12, 0.48, 1.0)
const TEAM_RED := Color(0.95, 0.18, 0.16)
const HERO_NAMES := ["KAIRON", "ELIARA", "RAIN", "NOXA", "GARDON"]

var player: CharacterBody3D
var enemies: Array[CharacterBody3D] = []
var allies: Array[CharacterBody3D] = []
var joystick_origin := Vector2.ZERO
var joystick_vector := Vector2.ZERO
var joystick_active := false
var attack_cooldown := 0.0
var skill_cooldown := 0.0
var status_label: Label

func _ready() -> void:
	_build_world()
	_build_hud()
	_spawn_teams()

func _build_world() -> void:
	var world := WorldEnvironment.new()
	var env := Environment.new()
	env.background_mode = Environment.BG_SKY
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.55, 0.62, 0.78)
	env.ambient_light_energy = 0.7
	world.environment = env
	add_child(world)

	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-55, -25, 0)
	sun.light_energy = 1.2
	add_child(sun)

	var floor := MeshInstance3D.new()
	var floor_mesh := BoxMesh.new()
	floor_mesh.size = Vector3(42, 0.5, 30)
	floor.mesh = floor_mesh
	floor.position.y = -0.3
	floor.material_override = _material(Color(0.12, 0.22, 0.19))
	add_child(floor)

	_add_box(Vector3(0, 0.02, 0), Vector3(5, 0.08, 30), Color(0.34, 0.31, 0.25))
	_add_box(Vector3(-13, 0.03, 0), Vector3(0.35, 0.1, 30), Color(0.08, 0.42, 0.35))
	_add_box(Vector3(13, 0.03, 0), Vector3(0.35, 0.1, 30), Color(0.55, 0.16, 0.15))
	_add_base(Vector3(-17, 0.8, 0), TEAM_BLUE, "BLUE CORE")
	_add_base(Vector3(17, 0.8, 0), TEAM_RED, "RED CORE")
	for z in [-9.0, 0.0, 9.0]:
		_add_tower(Vector3(-10, 0.0, z), TEAM_BLUE)
		_add_tower(Vector3(10, 0.0, z), TEAM_RED)

	var camera := Camera3D.new()
	camera.position = Vector3(0, 25, 21)
	camera.rotation_degrees = Vector3(-48, 0, 0)
	camera.current = true
	camera.fov = 55
	add_child(camera)

func _add_box(pos: Vector3, size: Vector3, color: Color) -> void:
	var node := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = size
	node.mesh = mesh
	node.position = pos
	node.material_override = _material(color)
	add_child(node)

func _add_base(pos: Vector3, color: Color, label_text: String) -> void:
	var base := MeshInstance3D.new()
	var mesh := CylinderMesh.new()
	mesh.top_radius = 2.2
	mesh.bottom_radius = 2.6
	mesh.height = 1.5
	base.mesh = mesh
	base.position = pos
	base.material_override = _material(color)
	add_child(base)

func _add_tower(pos: Vector3, color: Color) -> void:
	var tower := MeshInstance3D.new()
	var mesh := CylinderMesh.new()
	mesh.top_radius = 0.55
	mesh.bottom_radius = 0.9
	mesh.height = 3.0
	tower.mesh = mesh
	tower.position = pos + Vector3(0, 1.5, 0)
	tower.material_override = _material(color.lightened(0.15))
	add_child(tower)

func _material(color: Color) -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.roughness = 0.82
	return mat

func _make_unit(unit_name: String, color: Color, pos: Vector3, is_player: bool) -> CharacterBody3D:
	var unit := CharacterBody3D.new()
	unit.name = unit_name
	unit.position = pos
	var body := MeshInstance3D.new()
	var capsule := CapsuleMesh.new()
	capsule.radius = 0.48 if is_player else 0.4
	capsule.height = 1.8 if is_player else 1.5
	body.mesh = capsule
	body.material_override = _material(color)
	unit.add_child(body)
	var collider := CollisionShape3D.new()
	var shape := CapsuleShape3D.new()
	shape.radius = 0.42
	shape.height = 1.6
	collider.shape = shape
	unit.add_child(collider)
	add_child(unit)
	return unit

func _spawn_teams() -> void:
	player = _make_unit("KAIRON", TEAM_BLUE.lightened(0.25), Vector3(-5, 1, 0), true)
	for i in range(4):
		allies.append(_make_unit(HERO_NAMES[i + 1], TEAM_BLUE, Vector3(-7 - (i % 2), 1, -6 + i * 4), false))
	for i in range(5):
		enemies.append(_make_unit("ENEMY_%d" % (i + 1), TEAM_RED, Vector3(7 + (i % 2), 1, -8 + i * 4), false))

func _build_hud() -> void:
	var layer := CanvasLayer.new()
	add_child(layer)
	var panel := ColorRect.new()
	panel.color = Color(0.025, 0.04, 0.08, 0.78)
	panel.anchor_left = 0.0
	panel.anchor_top = 0.0
	panel.anchor_right = 1.0
	panel.offset_bottom = 58
	layer.add_child(panel)
	var title := Label.new()
	title.text = "VEYRAX  •  ARENA PROTOTYPE     5 VS 5"
	title.position = Vector2(18, 16)
	title.add_theme_font_size_override("font_size", 21)
	title.add_theme_color_override("font_color", Color(0.85, 0.92, 1.0))
	panel.add_child(title)

	status_label = Label.new()
	status_label.text = "KAIRON  |  Move with left side • Attack / Skill on right"
	status_label.anchor_left = 0.0
	status_label.anchor_top = 1.0
	status_label.offset_left = 18
	status_label.offset_top = -42
	status_label.add_theme_color_override("font_color", Color.WHITE)
	layer.add_child(status_label)

	var attack := Button.new()
	attack.text = "ATTACK"
	attack.anchor_left = 1.0
	attack.anchor_top = 1.0
	attack.anchor_right = 1.0
	attack.anchor_bottom = 1.0
	attack.offset_left = -150
	attack.offset_top = -105
	attack.offset_right = -25
	attack.offset_bottom = -35
	attack.pressed.connect(_attack)
	layer.add_child(attack)

	var skill := Button.new()
	skill.text = "SKILL"
	skill.anchor_left = 1.0
	skill.anchor_top = 1.0
	skill.anchor_right = 1.0
	skill.anchor_bottom = 1.0
	skill.offset_left = -280
	skill.offset_top = -95
	skill.offset_right = -165
	skill.offset_bottom = -35
	skill.pressed.connect(_skill)
	layer.add_child(skill)

func _input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		if event.pressed and event.position.x < get_viewport().get_visible_rect().size.x * 0.48:
			joystick_active = true
			joystick_origin = event.position
			joystick_vector = Vector2.ZERO
		elif not event.pressed:
			joystick_active = false
			joystick_vector = Vector2.ZERO
	elif event is InputEventScreenDrag and joystick_active:
		joystick_vector = (event.position - joystick_origin).limit_length(90) / 90.0

func _physics_process(delta: float) -> void:
	if not is_instance_valid(player):
		return
	attack_cooldown = maxf(0.0, attack_cooldown - delta)
	skill_cooldown = maxf(0.0, skill_cooldown - delta)
	var direction := joystick_vector
	if Input.is_key_pressed(KEY_W): direction.y -= 1.0
	if Input.is_key_pressed(KEY_S): direction.y += 1.0
	if Input.is_key_pressed(KEY_A): direction.x -= 1.0
	if Input.is_key_pressed(KEY_D): direction.x += 1.0
	var move := Vector3(direction.x, 0, direction.y).normalized()
	player.velocity.x = move.x * 7.0
	player.velocity.z = move.z * 7.0
	player.velocity.y -= 22.0 * delta
	player.move_and_slide()
	player.position.x = clampf(player.position.x, -19.0, 19.0)
	player.position.z = clampf(player.position.z, -13.0, 13.0)
	for enemy in enemies:
		if not is_instance_valid(enemy):
			continue
		var to_player := player.global_position - enemy.global_position
		to_player.y = 0
		if to_player.length() > 1.8:
			enemy.velocity.x = to_player.normalized().x * 2.2
			enemy.velocity.z = to_player.normalized().z * 2.2
		else:
			enemy.velocity.x = 0
			enemy.velocity.z = 0
		enemy.velocity.y -= 22.0 * delta
		enemy.move_and_slide()

func _nearest_enemy() -> CharacterBody3D:
	var nearest: CharacterBody3D
	var best := 4.5
	for enemy in enemies:
		if is_instance_valid(enemy):
			var distance := player.global_position.distance_to(enemy.global_position)
			if distance < best:
				best = distance
				nearest = enemy
	return nearest

func _attack() -> void:
	if attack_cooldown > 0.0:
		return
	attack_cooldown = 0.55
	var target := _nearest_enemy()
	if target:
		enemies.erase(target)
		target.queue_free()
		status_label.text = "HIT! Enemy defeated. Remaining: %d" % enemies.size()
	else:
		status_label.text = "No enemy in range — move closer!"

func _skill() -> void:
	if skill_cooldown > 0.0:
		return
	skill_cooldown = 4.0
	var target := _nearest_enemy()
	if target:
		enemies.erase(target)
		target.queue_free()
		status_label.text = "KAIRON SKILL! Target eliminated. Remaining: %d" % enemies.size()
	else:
		status_label.text = "SKILL READY — approach an enemy!"
