extends CharacterBody3D

signal health_changed(current: int, maximum: int)
signal player_defeated

const JoystickPath = NodePath("../CanvasLayer/VirtualJoystick")
var speed: float = 6.0
var health: int = 500
var max_health: int = 500
var is_defeated: bool = false
var hurt_time: float = 0.0
var attack_ready: bool = true
var skill_ready: bool = true
var skill_1_ready: bool = true
var skill_2_ready: bool = true
var ultimate_ready: bool = true
var hero_index: int = 0
var hero_name: String = "КАЙРОН"
var damage_reduction: float = 0.0
var damage_reduction_time: float = 0.0
var speed_boost_time: float = 0.0
var original_speed: float = 6.0
var visual_root: Node3D
# The sword is a Node3D container holding several MeshInstance3D parts.
var sword: Node3D
var cape: MeshInstance3D
var left_leg: Node3D
var right_leg: Node3D
var walk_time: float = 0.0
var attack_pose: bool = false

func _ready() -> void:
	original_speed = speed
	_build_hero()
	var collision := CollisionShape3D.new()
	var shape := CapsuleShape3D.new()
	shape.radius = 0.48
	shape.height = 1.8
	collision.shape = shape
	collision.position.y = 0.9
	add_child(collision)
	add_to_group("player")
	add_to_group("blue_team")
	health_changed.emit(health, max_health)

func _build_hero() -> void:
	visual_root = Node3D.new()
	add_child(visual_root)

	var blue := _material(Color(0.035, 0.13, 0.38), 0.72)
	var blue_light := _material(Color(0.10, 0.32, 0.72), 0.68)
	var gold := _material(Color(1.0, 0.62, 0.12), 0.82)
	var silver := _material(Color(0.68, 0.80, 0.96), 0.88)
	var dark := _material(Color(0.018, 0.035, 0.085), 0.3)
	var skin := _material(Color(0.48, 0.29, 0.20), 0.0)
	var glow := _glow_material(Color(0.12, 0.72, 1.0))

	# Layered breastplate and waist armor.
	_add_capsule(Vector3(0, 1.08, 0), Vector3(0.82, 1.02, 0.55), blue)
	_add_box(Vector3(0, 1.47, -0.285), Vector3(0.68, 0.52, 0.10), blue_light)
	_add_box(Vector3(0, 1.18, -0.34), Vector3(0.58, 0.12, 0.08), gold)
	_add_box(Vector3(0, 0.78, 0), Vector3(0.82, 0.22, 0.62), dark)
	_add_box(Vector3(0, 0.78, -0.33), Vector3(0.32, 0.25, 0.08), gold)
	_add_sphere(Vector3(0, 1.38, -0.39), 0.105, glow)

	# Helmet: enclosed knight helm, brow, cheek guards and glowing visor.
	_add_sphere(Vector3(0, 2.02, 0), 0.36, silver)
	_add_box(Vector3(0, 2.10, -0.02), Vector3(0.62, 0.18, 0.56), blue)
	_add_box(Vector3(0, 1.94, -0.29), Vector3(0.48, 0.22, 0.13), dark)
	_add_box(Vector3(0, 1.98, -0.365), Vector3(0.34, 0.045, 0.025), glow)
	_add_box(Vector3(-0.24, 1.82, -0.22), Vector3(0.13, 0.28, 0.18), blue_light)
	_add_box(Vector3(0.24, 1.82, -0.22), Vector3(0.13, 0.28, 0.18), blue_light)
	_add_cone(Vector3(0, 2.42, 0.02), 0.12, 0.48, gold)
	_add_cone(Vector3(-0.34, 2.12, 0.02), 0.09, 0.30, gold)
	_add_cone(Vector3(0.34, 2.12, 0.02), 0.09, 0.30, gold)

	# Broad pauldrons with raised gold trim and small armor spikes.
	for side in [-1.0, 1.0]:
		_add_sphere(Vector3(side * 0.55, 1.62, 0), 0.32, blue_light)
		_add_sphere(Vector3(side * 0.55, 1.70, -0.06), 0.25, gold)
		_add_sphere(Vector3(side * 0.55, 1.70, -0.105), 0.19, blue)
		_add_cone(Vector3(side * 0.72, 1.91, 0.02), 0.10, 0.34, gold)
		_add_capsule(Vector3(side * 0.62, 1.20, 0), Vector3(0.24, 0.62, 0.24), silver)
		_add_box(Vector3(side * 0.22, 0.35, 0), Vector3(0.29, 0.58, 0.34), blue)
		_add_box(Vector3(side * 0.22, 0.13, -0.09), Vector3(0.38, 0.22, 0.52), dark)
		_add_box(Vector3(side * 0.22, 0.43, -0.19), Vector3(0.31, 0.13, 0.08), gold)

	# Blue royal cloak, attached behind the shoulders.
	cape = _add_box(Vector3(0, 1.05, 0.40), Vector3(0.82, 1.35, 0.13), _material(Color(0.018, 0.055, 0.20), 0.25))
	_add_box(Vector3(0, 1.58, 0.325), Vector3(0.66, 0.12, 0.12), gold)

	# Sword: silver blade, blue luminous fuller, gold crossguard and pommel.
	sword = Node3D.new()
	sword.position = Vector3(0.78, 1.08, -0.18)
	sword.rotation_degrees.z = -24
	visual_root.add_child(sword)
	var blade := _make_box(Vector3(0.11, 1.22, 0.075), silver)
	blade.position.y = 0.58
	sword.add_child(blade)
	var fuller := _make_box(Vector3(0.035, 0.88, 0.082), glow)
	fuller.position = Vector3(0, 0.60, -0.045)
	sword.add_child(fuller)
	var guard := _make_box(Vector3(0.42, 0.11, 0.16), gold)
	guard.position.y = 0.08
	sword.add_child(guard)
	var grip := _make_box(Vector3(0.12, 0.30, 0.12), dark)
	grip.position.y = -0.12
	sword.add_child(grip)
	_add_sphere(Vector3(0.78, 0.89, -0.18), 0.095, gold)

	# Heavy kite shield with a bright crest.
	_add_box(Vector3(-0.76, 1.12, -0.03), Vector3(0.20, 0.92, 0.66), gold)
	_add_box(Vector3(-0.79, 1.14, -0.10), Vector3(0.16, 0.80, 0.56), blue)
	_add_box(Vector3(-0.89, 1.14, -0.395), Vector3(0.035, 0.42, 0.035), gold)
	_add_box(Vector3(-0.89, 1.14, -0.395), Vector3(0.035, 0.07, 0.035), glow)
	_add_sphere(Vector3(-0.90, 1.14, -0.40), 0.13, gold)

	# Leg pivots for a simple walk cycle.
	left_leg = Node3D.new()
	right_leg = Node3D.new()
	left_leg.position = Vector3(-0.22, 0.62, 0)
	right_leg.position = Vector3(0.22, 0.62, 0)
	visual_root.add_child(left_leg)
	visual_root.add_child(right_leg)
	_add_box(Vector3(0, -0.28, 0), Vector3(0.27, 0.58, 0.32), blue)
	_add_box(Vector3(0, -0.54, -0.08), Vector3(0.34, 0.20, 0.48), silver)
	# The pivoted legs are decorative overlays; main armor remains stable.

func _material(color: Color, metal: float) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = color
	m.metallic = metal
	m.roughness = 0.30
	return m

func _glow_material(color: Color) -> StandardMaterial3D:
	var m := _material(color, 0.35)
	m.emission_enabled = true
	m.emission = color
	m.emission_energy_multiplier = 2.4
	return m

func _make_box(size: Vector3, mat: Material) -> MeshInstance3D:
	var n := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = size
	n.mesh = mesh
	n.material_override = mat
	return n

func _add_box(pos: Vector3, size: Vector3, mat: Material) -> MeshInstance3D:
	var n := _make_box(size, mat)
	n.position = pos
	visual_root.add_child(n)
	return n

func _add_sphere(pos: Vector3, radius: float, mat: Material) -> MeshInstance3D:
	var n := MeshInstance3D.new()
	var mesh := SphereMesh.new()
	mesh.radius = radius
	mesh.height = radius * 2.0
	n.mesh = mesh
	n.position = pos
	n.material_override = mat
	visual_root.add_child(n)
	return n

func _add_capsule(pos: Vector3, size: Vector3, mat: Material) -> MeshInstance3D:
	var n := MeshInstance3D.new()
	var mesh := CapsuleMesh.new()
	mesh.radius = min(size.x, size.z) * 0.5
	mesh.height = size.y
	n.mesh = mesh
	n.position = pos
	n.material_override = mat
	visual_root.add_child(n)
	return n

func _add_cone(pos: Vector3, radius: float, height: float, mat: Material) -> MeshInstance3D:
	var n := MeshInstance3D.new()
	var mesh := CylinderMesh.new()
	mesh.top_radius = 0.015
	mesh.bottom_radius = radius
	mesh.height = height
	n.mesh = mesh
	n.position = pos
	n.material_override = mat
	visual_root.add_child(n)
	return n

func _process(delta: float) -> void:
	if damage_reduction_time > 0.0:
		damage_reduction_time = maxf(damage_reduction_time - delta, 0.0)
		if damage_reduction_time == 0.0:
			damage_reduction = 0.0
	if speed_boost_time > 0.0:
		speed_boost_time = maxf(speed_boost_time - delta, 0.0)
		if speed_boost_time == 0.0:
			speed = original_speed
	if is_defeated:
		return
	var stick := get_tree().get_first_node_in_group("virtual_joystick")
	var input_dir := Vector2.ZERO
	if stick != null and stick.has_method("get_output"):
		input_dir = stick.get_output()
	if input_dir.length() < 0.05:
		input_dir = Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	var direction := Vector3(input_dir.x, 0, input_dir.y)
	if direction.length() > 0.05:
		velocity.x = direction.x * speed
		velocity.z = direction.z * speed
		visual_root.rotation.y = atan2(direction.x, direction.z)
		walk_time += delta * 9.0
		visual_root.position.y = abs(sin(walk_time)) * 0.045
		if cape != null:
			cape.rotation.x = sin(walk_time * 0.5) * 0.08
	else:
		velocity.x = move_toward(velocity.x, 0.0, speed * 5.0 * delta)
		velocity.z = move_toward(velocity.z, 0.0, speed * 5.0 * delta)
		visual_root.position.y = move_toward(visual_root.position.y, 0.0, delta * 0.15)
		if cape != null:
			cape.rotation.x = move_toward(cape.rotation.x, 0.0, delta * 0.2)
	if left_leg != null and right_leg != null:
		var moving := Vector2(velocity.x, velocity.z).length() > 0.2
		var swing := sin(walk_time) * 0.32 if moving else 0.0
		left_leg.rotation.x = swing
		right_leg.rotation.x = -swing
	velocity.y = 0
	move_and_slide()

func take_damage(amount: int) -> void:
	if is_defeated:
		return
	health = max(health - int(round(float(amount) * (1.0 - damage_reduction))), 0)
	health_changed.emit(health, max_health)
	hurt_time = 0.18
	if visual_root != null:
		var original_scale := visual_root.scale
		var tween := create_tween()
		tween.tween_property(visual_root, "scale", original_scale * Vector3(0.94, 1.04, 0.94), 0.07)
		tween.tween_property(visual_root, "scale", original_scale, 0.12)
		_swing_effect(Color(1.0, 0.18, 0.12), 0.8)
	if health <= 0:
		is_defeated = true
		velocity = Vector3.ZERO
		var death_tween := create_tween()
		death_tween.tween_property(visual_root, "rotation_degrees:z", 82.0, 0.35)
		death_tween.parallel().tween_property(visual_root, "position:y", -0.45, 0.45)
		death_tween.tween_callback(func(): player_defeated.emit())

func restore_health(amount: int) -> void:
	if is_defeated:
		return
	health = min(health + amount, max_health)
	health_changed.emit(health, max_health)

func attack() -> void:
	if is_defeated or not attack_ready:
		return
	attack_ready = false
	_damage_nearby(25, 2.8)
	_swing_effect(Color(0.55, 0.82, 1.0), 1.7)
	if sword != null:
		sword.rotation_degrees.z = 34
		await get_tree().create_timer(0.16).timeout
		sword.rotation_degrees.z = -24
	await get_tree().create_timer(0.45).timeout
	attack_ready = true

func set_hero(index: int) -> void:
	hero_index = clampi(index, 0, 5)
	var names := ["КАЙРОН", "ЭЛИАРА", "РЕЙН", "НОКСА", "ГАРДОН", "БЬЁРН"]
	var hp := [500, 430, 420, 450, 650, 760]
	var move_speeds := [6.0, 5.7, 6.3, 6.8, 5.0, 4.5]
	hero_name = names[hero_index]
	max_health = hp[hero_index]
	health = max_health
	original_speed = move_speeds[hero_index]
	speed = original_speed
	health_changed.emit(health, max_health)

func use_skill_1() -> void:
	if is_defeated or not skill_1_ready:
		return
	skill_1_ready = false
	match hero_index:
		0: # Kairon: dash and cleave
			_dash_forward(3.2)
			_damage_nearby(70, 4.2)
			_swing_effect(Color(0.18, 0.65, 1.0), 3.0)
		1: # Eliara: ice spear
			_damage_nearest(82, 10.0)
			_freeze_nearest(1.5)
			_swing_effect(Color(0.35, 0.88, 1.0), 2.7)
		2: # Rain: piercing shot
			_damage_in_front(75, 12.0, 0.72)
			_swing_effect(Color(1.0, 0.76, 0.24), 2.4)
		3: # Noxa: shadow strike
			_shadow_strike(88)
			_swing_effect(Color(0.66, 0.22, 1.0), 2.8)
		4: # Gardon: seismic slam
			_damage_nearby(68, 5.5)
			_control_nearby(1.2, 0.25)
			_swing_effect(Color(0.55, 0.82, 0.48), 3.8)
		5: # Bjorn: thunder hammer
			_damage_nearby(90, 5.8)
			_control_nearby(1.0, 0.2)
			_swing_effect(Color(0.2, 0.85, 1.0), 4.0)
	await get_tree().create_timer(7.0).timeout
	skill_1_ready = true

func use_skill_2() -> void:
	if is_defeated or not skill_2_ready:
		return
	skill_2_ready = false
	match hero_index:
		0: # Iron will
			_apply_guard(0.45, 3.0)
			speed = original_speed * 1.12
			speed_boost_time = 3.0
		1: # Elemental mirror
			_apply_guard(0.60, 3.5)
		2: # Hunter instinct
			speed = original_speed * 1.55
			speed_boost_time = 4.0
			_damage_nearby(22, 3.0)
		3: # Veil of darkness
			_apply_guard(0.35, 2.5)
			speed = original_speed * 1.65
			speed_boost_time = 2.5
		4: # Impregnable fortress
			_apply_guard(0.65, 4.0)
			for ally in get_tree().get_nodes_in_group("blue_team"):
				if ally != self and is_instance_valid(ally) and global_position.distance_to(ally.global_position) <= 5.0 and ally.has_method("restore_health"):
					ally.restore_health(55)
		5: # Stone blood
			_apply_guard(0.70, 4.0)
		_swing_effect(_hero_color(), 2.5)
	await get_tree().create_timer(10.0).timeout
	skill_2_ready = true

func use_ultimate() -> void:
	if is_defeated or not ultimate_ready:
		return
	ultimate_ready = false
	match hero_index:
		0: # King's rage
			_damage_nearby(155, 7.0)
			_control_nearby(0.8, 0.35)
		1: # Blizzard
			_damage_nearby(125, 8.5)
			_control_nearby(2.0, 0.0)
		2: # Sky barrage
			_damage_nearby(145, 9.0)
		3: # Death mark: focus the nearest enemy with a burst
			_damage_nearest(230, 14.0)
			_damage_nearby(65, 4.0)
		4: # Colossal verdict
			_damage_nearby(135, 8.0)
			_control_nearby(2.0, 0.0)
		5: # Titanfall
			_dash_forward(4.0)
			_damage_nearby(190, 9.0)
			_control_nearby(1.6, 0.0)
	_swing_effect(_hero_color(), 5.0)
	await get_tree().create_timer(28.0).timeout
	ultimate_ready = true

# Backwards-compatible alias for older UI connections.
func use_skill() -> void:
	use_skill_1()

func _hero_color() -> Color:
	var colors := [Color(0.12, 0.65, 1.0), Color(0.35, 0.88, 1.0), Color(1.0, 0.76, 0.24), Color(0.66, 0.22, 1.0), Color(0.55, 0.82, 0.48), Color(0.2, 0.85, 1.0)]
	return colors[hero_index]

func _apply_guard(amount: float, duration: float) -> void:
	damage_reduction = amount
	damage_reduction_time = duration

func _dash_forward(distance: float) -> void:
	var forward := -visual_root.global_transform.basis.z.normalized()
	global_position += forward * distance

func _damage_nearest(amount: int, radius: float) -> void:
	var target: Node3D = null
	var best := radius
	for enemy in _get_attack_targets():
		if is_instance_valid(enemy):
			var d := global_position.distance_to(enemy.global_position)
			if d < best:
				best = d
				target = enemy
	if target != null and target.has_method("take_damage"):
		target.take_damage(amount)

func _damage_in_front(amount: int, radius: float, dot_min: float) -> void:
	var forward := -visual_root.global_transform.basis.z.normalized()
	for enemy in _get_attack_targets():
		if not is_instance_valid(enemy):
			continue
		var offset := enemy.global_position - global_position
		offset.y = 0.0
		if offset.length() <= radius and offset.length() > 0.01 and forward.dot(offset.normalized()) >= dot_min:
			if enemy.has_method("take_damage"):
				enemy.take_damage(amount)

func _shadow_strike(amount: int) -> void:
	var target: Node3D = null
	var best := 14.0
	for enemy in get_tree().get_nodes_in_group("enemies"):
		if is_instance_valid(enemy):
			var d := global_position.distance_to(enemy.global_position)
			if d < best:
				best = d
				target = enemy
	if target != null:
		var away := (global_position - target.global_position).normalized()
		global_position = target.global_position + away * 1.5
		if target.has_method("take_damage"):
			target.take_damage(amount)

func _freeze_nearest(duration: float) -> void:
	var target: Node3D = null
	var best := 10.0
	for enemy in get_tree().get_nodes_in_group("enemies"):
		if is_instance_valid(enemy):
			var d := global_position.distance_to(enemy.global_position)
			if d < best:
				best = d
				target = enemy
	if target != null and target.has_method("apply_control"):
		target.apply_control(duration, 0.0)

func _control_nearby(duration: float, speed_factor: float) -> void:
	for enemy in get_tree().get_nodes_in_group("enemies"):
		if is_instance_valid(enemy) and global_position.distance_to(enemy.global_position) <= 9.0 and enemy.has_method("apply_control"):
			enemy.apply_control(duration, speed_factor)

func play_victory_pose() -> void:
	if is_defeated or visual_root == null:
		return
	var tween := create_tween()
	tween.tween_property(visual_root, "rotation_degrees:z", -8.0, 0.22)
	if sword != null:
		tween.parallel().tween_property(sword, "rotation_degrees:z", -105.0, 0.28)
	if cape != null:
		tween.parallel().tween_property(cape, "rotation_degrees:x", -0.22, 0.3)

func _get_attack_targets() -> Array:
	var targets: Array = get_tree().get_nodes_in_group("enemies")
	targets.append_array(get_tree().get_nodes_in_group("enemy_objectives"))
	return targets

func _damage_nearby(amount: int, radius: float) -> void:
	for enemy in _get_attack_targets():
		if is_instance_valid(enemy) and global_position.distance_to(enemy.global_position) <= radius:
			if enemy.has_method("take_damage"):
				enemy.take_damage(amount)

func _swing_effect(color: Color, scale_value: float) -> void:
	var fx := MeshInstance3D.new()
	var mesh := SphereMesh.new()
	mesh.radius = 0.55
	mesh.height = 1.1
	fx.mesh = mesh
	fx.position = Vector3(0, 1.1, -1.0)
	var m := StandardMaterial3D.new()
	m.albedo_color = Color(color.r, color.g, color.b, 0.45)
	m.emission_enabled = true
	m.emission = color
	m.emission_energy_multiplier = 2.0
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	fx.material_override = m
	visual_root.add_child(fx)
	fx.scale = Vector3.ONE * scale_value
	var tween := create_tween()
	tween.tween_property(fx, "scale", Vector3.ONE * 0.1, 0.22)
	tween.tween_callback(fx.queue_free)
