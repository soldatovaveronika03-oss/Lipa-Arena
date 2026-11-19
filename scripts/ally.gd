extends CharacterBody3D

var health: int = 220
var speed: float = 2.4
var attack_timer: float = 0.0
var attack_damage: int = 16
var body_mesh: MeshInstance3D
var dead: bool = false
var lane_offset: Vector3 = Vector3.ZERO

func _ready() -> void:
	add_to_group("blue_team")
	body_mesh = MeshInstance3D.new()
	var capsule := CapsuleMesh.new()
	capsule.radius = 0.42
	capsule.height = 1.55
	body_mesh.mesh = capsule
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.12, 0.42, 0.92)
	mat.metallic = 0.45
	body_mesh.material_override = mat
	body_mesh.position.y = 0.8
	add_child(body_mesh)
	var crest := MeshInstance3D.new()
	var crest_mesh := SphereMesh.new()
	crest_mesh.radius = 0.18
	crest.mesh = crest_mesh
	crest.position.y = 1.72
	var cm := StandardMaterial3D.new()
	cm.albedo_color = Color(0.25, 0.8, 1.0)
	cm.emission_enabled = true
	cm.emission = Color(0.1, 0.55, 1.0)
	crest.material_override = cm
	add_child(crest)
	var collision := CollisionShape3D.new()
	var shape := CapsuleShape3D.new()
	shape.radius = 0.42
	shape.height = 1.6
	collision.shape = shape
	collision.position.y = 0.8
	add_child(collision)

func _physics_process(delta: float) -> void:
	if dead:
		return
	attack_timer = max(attack_timer - delta, 0.0)
	var enemy := _nearest_enemy()
	var destination: Vector3
	if is_instance_valid(enemy):
		var dist := global_position.distance_to(enemy.global_position)
		if dist <= 2.0:
			velocity.x = 0.0
			velocity.z = 0.0
			if attack_timer <= 0.0:
				enemy.call("take_damage", attack_damage)
				attack_timer = 1.0
		else:
			destination = enemy.global_position
			_move_toward(destination, delta)
	else:
		var player := get_tree().get_first_node_in_group("player")
		if is_instance_valid(player):
			destination = player.global_position + lane_offset
			if global_position.distance_to(destination) > 2.8:
				_move_toward(destination, delta)
			else:
				velocity.x = move_toward(velocity.x, 0.0, speed * delta)
				velocity.z = move_toward(velocity.z, 0.0, speed * delta)
	velocity.y = 0.0
	move_and_slide()

func _move_toward(destination: Vector3, delta: float) -> void:
	var direction := destination - global_position
	direction.y = 0.0
	if direction.length() > 0.1:
		direction = direction.normalized()
		velocity.x = direction.x * speed
		velocity.z = direction.z * speed
		look_at(Vector3(destination.x, global_position.y, destination.z))

func _nearest_enemy() -> Node3D:
	var best: Node3D = null
	var best_dist := 999999.0
	for enemy in get_tree().get_nodes_in_group("enemies"):
		if is_instance_valid(enemy):
			var d := global_position.distance_to(enemy.global_position)
			if d < best_dist:
				best_dist = d
				best = enemy
	return best

func take_damage(amount: int) -> void:
	if dead:
		return
	health -= amount
	if health <= 0:
		dead = true
		remove_from_group("blue_team")
		var tween := create_tween()
		tween.tween_property(self, "scale", Vector3(0.1, 0.1, 0.1), 0.25)
		tween.tween_callback(queue_free)

func restore_health(amount: int) -> void:
	if dead:
		return
	health = min(health + amount, 220)
