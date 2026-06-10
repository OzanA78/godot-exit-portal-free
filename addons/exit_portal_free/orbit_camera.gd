extends Camera3D
## Orbit camera — drag with the mouse (hold left or right button) to rotate around
## the target, scroll wheel to zoom. Smoothly follows like the game's camera.

## Kullanıcı kameraya elle müdahale ettiğinde (drag veya zoom) yayılır.
signal user_took_control
signal zoomed_out
signal zoomed_in

## World-space point the camera looks at and orbits around.
@export var target: Vector3 = Vector3(0, 1.2, -10.5)
@export var distance: float = 13.0
@export var min_distance: float = 4.0
@export var max_distance: float = 22.0
@export var zoom_speed: float = 1.0
@export var mouse_sensitivity: float = 0.008
## Higher = snappier, lower = floatier. Matches the game's follow_speed feel.
@export var follow_speed: float = 8.0
## Auto-rotate around the target (for showcase/GIF). Any mouse drag cancels it.
@export var auto_spin: bool = false
## Auto-spin speed (degrees/second).
@export var auto_spin_speed: float = 14.0

var yaw: float = 0.0
var pitch: float = 0.5
var pitch_min: float = 0.05
var pitch_max: float = 1.45
var _breathe_t: float = 1.0
var _breathe_wait: float = 0.0
var _breathe_out: bool = true
var _breathe_max: float = 13.0
var _breathe_min: float = 9.0
var _breathe_min_pitch: float = 0.5
var _breathe_max_pitch: float = 0.5
var _spin_offset: float = 0.0
var _current_distance: float = 13.0
var _intro_t: float = 0.0   # 0→1 arası büyür, follow_speed'i yavaştan normale getirir

func _ready() -> void:
	_breathe_max = distance
	global_position = _desired_position()
	look_at(target, Vector3.UP)

func reset_to_max() -> void:
	_breathe_t = 1.0
	_breathe_out = true
	_breathe_wait = 0.0
	_spin_offset = 0.0
	pitch = _breathe_max_pitch
	_current_distance = _breathe_max
	distance = _breathe_max
	_intro_t = 0.0

func _unhandled_input(event: InputEvent) -> void:
	# Hold left/right mouse to capture and rotate
	if event is InputEventMouseButton and (event.button_index == MOUSE_BUTTON_LEFT or event.button_index == MOUSE_BUTTON_RIGHT):
		if event.pressed:
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
		elif not Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT) and not Input.is_mouse_button_pressed(MOUSE_BUTTON_RIGHT):
			Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		auto_spin = false  # user took control
		user_took_control.emit()
		yaw -= event.relative.x * mouse_sensitivity
		pitch += event.relative.y * mouse_sensitivity
		pitch = clampf(pitch, pitch_min, pitch_max)

	if event is InputEventMouseButton:
		# If mouse is over UI, don't zoom (prevents wheel leak from lists/scrolls)
		if get_viewport().gui_get_hovered_control():
			return

		if event.button_index == MOUSE_BUTTON_WHEEL_UP and event.pressed:
			distance = maxf(min_distance, distance - zoom_speed)
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN and event.pressed:
			distance = minf(max_distance, distance + zoom_speed)
			_breathe_max = distance

func _process(delta: float) -> void:
	if auto_spin:
		_spin_offset += deg_to_rad(auto_spin_speed * delta)
		if _breathe_wait > 0.0:
			_breathe_wait -= delta
		else:
			if _breathe_out:
				_breathe_t -= delta * 0.5
				if _breathe_t <= 0.0:
					_breathe_t = 0.0
					_breathe_out = false
					_breathe_wait = 3.0
			else:
				_breathe_t += delta * 0.25
				if _breathe_t >= 1.0:
					_breathe_t = 1.0
					_breathe_out = true
					zoomed_out.emit()
		var t_ease: float = _breathe_t * _breathe_t * (3.0 - 2.0 * _breathe_t)
		distance = lerp(_breathe_min, _breathe_max, t_ease)
		yaw = _spin_offset
		pitch = lerp(_breathe_min_pitch, _breathe_max_pitch, t_ease)
	if _intro_t < 1.0:
		_intro_t = minf(_intro_t + delta * 0.4, 1.0)
	var effective_speed: float = lerp(1.0, follow_speed, _intro_t * _intro_t)
	global_position = global_position.lerp(_desired_position(), effective_speed * delta)
	look_at(target, Vector3.UP)

func _desired_position() -> Vector3:
	var offset := Vector3(
		sin(yaw) * cos(pitch) * distance,
		sin(pitch) * distance,
		cos(yaw) * cos(pitch) * distance
	)
	return target + offset
