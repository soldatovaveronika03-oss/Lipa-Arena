extends Node3D

var max_health: int = 1800
var health: int = 1800
var attack_range: float = 7.0
var attack_damage: int = 28
var attack_cooldown: float = 1.4
var attack_timer: float = 0.0
var is_throne: bool = false
var health_label: Label3D
var core: MeshInstance3D
var dead: bool = false

func _ready() -> void:
	add_to_group("enemy_objectives")
	if is_throne:
		add_to_group("enemy_throne")
	_build_visuals()

func _build_visuals() -> void:
	var base := MeshInstance3D.new()
	var base_mesh := CylinderMesh.new()
	base_mesh.top_radius = 1.15 if not is_throne else 2.0
	base_mesh.bottom_radius = 1.45 if not is_throne else 2.35
	base_mesh.height = 0.55
	base.mesh = base_mesh
	base.position.y = 0.28
	base.material_override = _mat(Color(0.20, 0.12, 0.22), 0.55)
	add_child(base)

	core = MeshInstance3D.new()
	var core_mesh := PrismMesh.new()
	core_mesh.size = Vector3(1.05, 2.8, 1.05) if not is_throne else Vector3(2.4, 4.2, 2.4)
	core.mesh = core_mesh
	core.position.y = 1.8 if not is_throne else 2.45
	core.material_override = _glow_mat(Color(1.0, 0.12, 0.19) if not is_throne else Color(1.0, 0.35, 0.08))
	add_child(core)

	var ring := MeshInstance3D.new()
	var ring_mesh := TorusMesh.new()
	ring_mesh.inner_radius = 1.0 if not is_throne else 1.7
	ring_mesh.outer_radius = 1.18 if not is_throne else 1.95
	ring.mesh = ring_mesh
	ring.position.y = 0.62
	ring.material_override = _mat(Color(0.72, 0.25, 0.18), 0.8)
	add_child(ring)

	health_label = Label3D.new()
	health_label.text = ("TRON  " if is_throne else "BASHNYA  ") + str(health) + " HP"
	health_label.position.y = 4.2 if is_throne else 3.2
	health_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	health_label.font_size = 42
	health_label.modulate = Color(1.0, 0.55, 0.48)
	add_child(health_label)

func _physics_process(delta: float) -> void:
	if dead:
		return
	attack_timer = maxf(attack_timer - delta, 0.0)
	var target: Node3D = null
	var best := attack_range
	for candidate in get_tree().get_nodes_in_group("blue_minions"):
		if is_instance_valid(candidate):
			var distance := global_position.distance_to(candidate.global_position)
			if distance < best:
				best = distance
				target = candidate
	var player := get_tree().get_first_node_in_group("player")
	if is_instance_valid(player):
		var distance := global_position.distance_to(player.global_position)
		if distance < best:
			best = distance
			target = player
	if target != null and attack_timer <= 0.0 and target.has_method("take_damage"):
		target.take_damage(attack_damage)
		attack_timer = attack_cooldown

func take_damage(amount: int) -> void:
	if dead:
		return
	health = maxi(health - amount, 0)
	if is_instance_valid(health_label):
		health_label.text = ("TRON  " if is_throne else "BASHNYA  ") + str(health) + " HP"
	if is_instance_valid(core):
		core.scale = Vector3(0.9, 0.9, 0.9)
		var tween := create_tween()
		tween.tween_property(core, "scale", Vector3.ONE, 0.12)
	if health <= 0:
		dead = true
		remove_from_group("enemy_objectives")
		if is_throne:
			remove_from_group("enemy_throne")
			add_to_group("destroyed_enemy_throne")
		var tween := create_tween()
		tween.tween_property(self, "scale", Vector3(0.05, 0.05, 0.05), 0.45)
		tween.tween_callback(queue_free)

func _mat(color: Color, metal: float) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.metallic = metal
	material.roughness = 0.35
	return material

func _glow_mat(color: Color) -> StandardMaterial3D:
	var material := _mat(color, 0.35)
	material.emission_enabled = true
	material.emission = color
	material.emission_energy_multiplier = 2.0
	return material
