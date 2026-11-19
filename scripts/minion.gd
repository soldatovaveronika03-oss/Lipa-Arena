extends CharacterBody3D

var team: String = "blue"
var health: int = 150
var speed: float = 2.6
var attack_damage: int = 18
var attack_range: float = 1.7
var attack_cooldown: float = 1.0
var attack_timer: float = 0.0
var dead: bool = false
var lane_x: float = 0.0
var body_mesh: MeshInstance3D

func _ready() -> void:
	if team == "blue":
		add_to_group("blue_minions")
	else:
		add_to_group("red_minions")
	_build_body()

func _build_body() -> void:
	body_mesh = MeshInstance3D.new()
	var capsule := CapsuleMesh.new()
	capsule.radius = 0.30
	capsule.height = 1.2
	body_mesh.mesh = capsule
	var material := StandardMaterial3D.new()
	material.albedo_color = Color(0.12, 0.42, 0.95) if team == "blue" else Color(0.82, 0.12, 0.16)
	material.metallic = 0.35
	body_mesh.material_override = material
	body_mesh.position.y = 0.62
	add_child(body_mesh)
	var collision := CollisionShape3D.new()
	var shape := CapsuleShape3D.new()
	shape.radius = 0.3
	shape.height = 1.2
	collision.shape = shape
	collision.position.y = 0.62
	add_child(collision)

func _physics_process(delta: float) -> void:
	if dead:
		return
	attack_timer = maxf(attack_timer - delta, 0.0)
	var target := _find_target()
	if is_instance_valid(target):
		var offset := target.global_position - global_position
		offset.y = 0.0
		if offset.length() <= attack_range:
			velocity.x = 0.0
			velocity.z = 0.0
			if attack_timer <= 0.0 and target.has_method("take_damage"):
				target.take_damage(attack_damage)
				attack_timer = attack_cooldown
		else:
			var direction := offset.normalized()
			velocity.x = direction.x * speed
			velocity.z = direction.z * speed
			look_at(Vector3(target.global_position.x, global_position.y, target.global_position.z))
	else:
		var destination_z := -46.0 if team == "blue" else 46.0
		var direction_z := signf(destination_z - global_position.z)
		velocity.x = 0.0
		velocity.z = direction_z * speed
	velocity.y = 0.0
	move_and_slide()

func _find_target() -> Node3D:
	var best: Node3D = null
	var best_distance := 999999.0
	var groups: Array = ["red_minions"] if team == "blue" else ["blue_minions"]
	for group_name in groups:
		for candidate in get_tree().get_nodes_in_group(group_name):
			if not is_instance_valid(candidate) or candidate == self:
				continue
			if absf(candidate.global_position.x - lane_x) > 2.6:
				continue
			var distance := global_position.distance_to(candidate.global_position)
			if distance < best_distance:
				best_distance = distance
				best = candidate
	if best != null:
		return best
	if team == "blue":
		var objectives := get_tree().get_nodes_in_group("enemy_objectives")
		var nearest: Node3D = null
		var nearest_distance := 999999.0
		for objective in objectives:
			if is_instance_valid(objective) and absf(objective.global_position.x - lane_x) < 2.7:
				var distance := global_position.distance_to(objective.global_position)
				if distance < nearest_distance:
					nearest_distance = distance
					nearest = objective
		if nearest != null:
			return nearest
	return null

func take_damage(amount: int) -> void:
	if dead:
		return
	health = maxi(health - amount, 0)
	if health <= 0:
		dead = true
		remove_from_group("blue_minions")
		remove_from_group("red_minions")
		var tween := create_tween()
		tween.tween_property(self, "scale", Vector3(0.05, 0.05, 0.05), 0.2)
		tween.tween_callback(queue_free)
