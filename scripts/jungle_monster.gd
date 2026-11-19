extends CharacterBody3D

@export var monster_title: String = "ЛЕСНОЙ СТРАЖ"
@export var buff_type: String = "ember"
@export var glow_color: Color = Color(1.0, 0.35, 0.12)

var max_health: int = 900
var health: int = 900
var move_speed: float = 2.1
var attack_damage: int = 24
var attack_range: float = 1.8
var attack_timer: float = 0.0
var respawn_timer: float = 0.0
var dead: bool = false
var body_mesh: MeshInstance3D
var health_label: Label3D
var collision: CollisionShape3D
var home_position: Vector3

func _ready() -> void:
	home_position = global_position
	add_to_group("neutral_monsters")
	_build_monster()

func _process(delta: float) -> void:
	if not dead:
		return
	respawn_timer = maxf(respawn_timer - delta, 0.0)
	if respawn_timer <= 0.0:
		dead = false
		health = max_health
		visible = true
		scale = Vector3.ONE
		collision.disabled = false
		add_to_group("neutral_monsters")
		health_label.text = "%s  %d HP" % [monster_title, health]

func _build_monster() -> void:
	body_mesh = MeshInstance3D.new()
	var body := CapsuleMesh.new()
	body.radius = 0.82
	body.height = 2.2
	body_mesh.mesh = body
	var material := StandardMaterial3D.new()
	material.albedo_color = glow_color.darkened(0.55)
	material.metallic = 0.38
	material.roughness = 0.32
	body_mesh.material_override = material
	body_mesh.position.y = 1.05
	add_child(body_mesh)

	var core := MeshInstance3D.new()
	var core_mesh := SphereMesh.new()
	core_mesh.radius = 0.34
	core_mesh.height = 0.68
	core.mesh = core_mesh
	core.position = Vector3(0.0, 1.45, -0.58)
	var core_mat := StandardMaterial3D.new()
	core_mat.albedo_color = glow_color
	core_mat.emission_enabled = true
	core_mat.emission = glow_color
	core_mat.emission_energy_multiplier = 2.8
	core.material_override = core_mat
	add_child(core)

	for side in [-1.0, 1.0]:
		var horn := MeshInstance3D.new()
		var horn_mesh := CylinderMesh.new()
		horn_mesh.top_radius = 0.02
		horn_mesh.bottom_radius = 0.22
		horn_mesh.height = 0.85
		horn.mesh = horn_mesh
		horn.position = Vector3(side * 0.52, 1.9, 0.0)
		horn.rotation_degrees.z = side * -28.0
		horn.material_override = core_mat
		add_child(horn)

	collision = CollisionShape3D.new()
	var shape := CapsuleShape3D.new()
	shape.radius = 0.82
	shape.height = 2.2
	collision.shape = shape
	collision.position.y = 1.05
	add_child(collision)

	health_label = Label3D.new()
	health_label.text = "%s  %d HP" % [monster_title, health]
	health_label.position.y = 2.65
	health_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	health_label.font_size = 32
	health_label.modulate = glow_color.lightened(0.45)
	add_child(health_label)

func _physics_process(delta: float) -> void:
	if dead:
		return
	attack_timer = maxf(attack_timer - delta, 0.0)
	var target := _find_target()
	if not is_instance_valid(target):
		var home_offset := home_position - global_position
		home_offset.y = 0.0
		if home_offset.length() > 0.8:
			var home_direction := home_offset.normalized()
			velocity.x = home_direction.x * move_speed
			velocity.z = home_direction.z * move_speed
		else:
			velocity.x = move_toward(velocity.x, 0.0, move_speed * delta)
			velocity.z = move_toward(velocity.z, 0.0, move_speed * delta)
	else:
		var direction := target.global_position - global_position
		direction.y = 0.0
		var distance := direction.length()
		if distance > attack_range:
			direction = direction.normalized()
			velocity.x = direction.x * move_speed
			velocity.z = direction.z * move_speed
			look_at(Vector3(target.global_position.x, global_position.y, target.global_position.z))
		else:
			velocity.x = 0.0
			velocity.z = 0.0
			if attack_timer <= 0.0 and target.has_method("take_damage"):
				target.take_damage(attack_damage)
				attack_timer = 1.45
	velocity.y = 0.0
	move_and_slide()

func _find_target() -> Node3D:
	var nearest: Node3D = null
	var nearest_distance := 4.5
	var candidates: Array = get_tree().get_nodes_in_group("blue_team")
	candidates.append_array(get_tree().get_nodes_in_group("enemies"))
	for candidate in candidates:
		if not is_instance_valid(candidate) or candidate == self:
			continue
		if candidate.is_in_group("player") and candidate.get("is_defeated") == true:
			continue
		var distance := global_position.distance_to(candidate.global_position)
		if distance < nearest_distance:
			nearest_distance = distance
			nearest = candidate
	return nearest

func take_damage(amount: int) -> void:
	if dead:
		return
	health = maxi(health - amount, 0)
	health_label.text = "%s  %d HP" % [monster_title, health]
	if health <= 0:
		dead = true
		remove_from_group("neutral_monsters")
		respawn_timer = 35.0
		var hero := get_tree().get_first_node_in_group("player")
		if is_instance_valid(hero) and global_position.distance_to(hero.global_position) <= 10.0 and hero.has_method("apply_jungle_buff"):
			hero.apply_jungle_buff(buff_type, 30.0)
		visible = false
		collision.disabled = true
		velocity = Vector3.ZERO
