extends Control

var touch_index: int = -1
var output: Vector2 = Vector2.ZERO
var radius: float = 68.0
var knob_position: Vector2 = Vector2.ZERO

func _ready() -> void:
    add_to_group("virtual_joystick")
    custom_minimum_size = Vector2(180, 180)
    queue_redraw()

func get_output() -> Vector2:
    return output

func _gui_input(event: InputEvent) -> void:
    var center := size * 0.5
    if event is InputEventScreenTouch:
        if event.pressed and touch_index == -1:
            touch_index = event.index
            _update_stick(event.position, center)
        elif not event.pressed and event.index == touch_index:
            touch_index = -1
            output = Vector2.ZERO
            knob_position = center
            queue_redraw()
    elif event is InputEventScreenDrag and event.index == touch_index:
        _update_stick(event.position, center)

func _update_stick(pos: Vector2, center: Vector2) -> void:
    var delta := pos - center
    if delta.length() > radius:
        delta = delta.normalized() * radius
    knob_position = center + delta
    output = Vector2(delta.x / radius, delta.y / radius)
    queue_redraw()

func _draw() -> void:
    var center := size * 0.5
    if knob_position == Vector2.ZERO:
        knob_position = center
    draw_circle(center, radius + 10.0, Color(0.08, 0.12, 0.22, 0.55))
    draw_arc(center, radius + 10.0, 0, TAU, 64, Color(0.35, 0.65, 1.0, 0.8), 4.0)
    draw_circle(knob_position, 34.0, Color(0.25, 0.48, 0.82, 0.9))
    draw_arc(knob_position, 34.0, 0, TAU, 48, Color(0.75, 0.88, 1.0), 3.0)
