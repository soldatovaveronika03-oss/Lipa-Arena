extends CharacterBody3D

var target: Node3D
var health: int = 120
var max_health: int = 120
var speed: float = 1.75
var attack_damage: int = 18
var attack_range: float = 1.75
var attack_cooldown: float = 1.25
var attack_timer: float = 0.0
var label: Label3D
var dead: bool = false
var body_mesh: MeshInstance3D
var control_time: float = 0.0
var saved_speed: float = 1.75

func _ready() -> void:
	add_to_group("enemies")
	var body := MeshInstance3D.new()
	body_mesh = body
	var mesh := CapsuleMesh.new()
	mesh.radius = 0.48
	mesh.height = 1.65
	body.mesh = mesh
	var m := StandardMaterial3D.new()
	m.albedo_color = Color(0.62, 0.08, 0.12)
	m.metallic = 0.35
	body.material_override = m
	body.position.y = 0.85
	add_child(body)

	var crown := MeshInstance3D.new()
	var crown_mesh := SphereMesh.new()
	crown_mesh.radius = 0.22
	crown_mesh.height = 0.34
	crown.mesh = crown_mesh
	crown.position = Vector3(0, 1.78, 0)
	crown.material_override = _glow_mat(Color(1.0, 0.22, 0.12))
	add_child(crown)

	var collision := CollisionShape3D.new()
	var shape := CapsuleShape3D.new()
	shape.radius = 0.48
	shape.height = 1.7
	collision.shape = shape
	collision.position.y = 0.85
	add_child(collision)

	label = Label3D.new()
	label.text = str(health) + " HP"
	label.position.y = 2.15
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.font_size = 42
	label.modulate = Color(1.0, 0.45, 0.4)
	add_child(label)

func _physics_process(delta: float) -> void:
	if control_time > 0.0:
		control_time = maxf(control_time - delta, 0.0)
		if control_time == 0.0:
			speed = saved_speed
	if dead:
		return
	attack_timer = max(attack_timer - delta, 0.0)
	target = _find_target()
	if is_instance_valid(target):
		var direction := target.global_position - global_position
		direction.y = 0.0
		var distance := direction.length()
		if distance > attack_range:
			direction = direction.normalized()
			velocity.x = direction.x * speed
			velocity.z = direction.z * speed
			look_at(Vector3(target.global_position.x, global_position.y, target.global_position.z))
		else:
			velocity.x = 0.0
			velocity.z = 0.0
			if attack_timer <= 0.0 and target.has_method("take_damage"):
				target.call("take_damage", attack_damage)
				attack_timer = attack_cooldown
	else:
		velocity.x = move_toward(velocity.x, 0.0, speed * delta)
		velocity.z = move_toward(velocity.z, 0.0, speed * delta)
	velocity.y = 0.0
	move_and_slide()

func _find_target() -> Node3D:
	var best: Node3D = null
	var best_distance := 999999.0
	for candidate in get_tree().get_nodes_in_group("blue_team"):
		if not is_instance_valid(candidate):
			continue
		if candidate.is_in_group("player") and candidate.get("is_defeated") == true:
			continue
		var d := global_position.distance_to(candidate.global_position)
		if d < best_distance:
			best_distance = d
			best = candidate
	return best

func apply_control(duration: float, speed_factor: float) -> void:
	if dead:
		return
	if control_time <= 0.0:
		saved_speed = speed
	control_time = maxf(control_time, duration)
	speed = saved_speed * clampf(speed_factor, 0.0, 1.0)

func take_damage(amount: int) -> void:
	if dead:
		return
	health = max(health - amount, 0)
	if is_instance_valid(label):
		label.text = str(health) + " HP"
	if is_instance_valid(body_mesh):
		var old_material := body_mesh.material_override as StandardMaterial3D
		var old_color := old_material.albedo_color
		var flash := StandardMaterial3D.new()
		flash.albedo_color = Color(1.0, 0.8, 0.65)
		body_mesh.material_override = flash
		var tween := create_tween()
		tween.tween_interval(0.09)
		tween.tween_callback(func():
			if is_instance_valid(body_mesh) and not dead:
				var normal := StandardMaterial3D.new()
				normal.albedo_color = old_color
				normal.metallic = 0.35
				body_mesh.material_override = normal
		)
	if health <= 0:
		dead = true
		remove_from_group("enemies")
		var tween := create_tween()
		tween.tween_property(self, "scale", Vector3(0.1, 0.1, 0.1), 0.28)
		tween.tween_callback(queue_free)

func _glow_mat(color: Color) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = color
	m.emission_enabled = true
	m.emission = color
	m.emission_energy_multiplier = 1.5
	return m
