@tool
extends Area3D

const MESH_PATH := "res://addons/exit_portal_free/meshes/wobble.res"

@export var rotation_speed: float = 45.0
@export var glow_color: Color = Color(0.0, 1.0, 0.88):
	set(v):
		glow_color = v
		if is_inside_tree(): _apply_colors()
@export var coin_color_a: Color = Color(0.1, 1.0, 0.2):
	set(v):
		coin_color_a = v
		if is_inside_tree(): _apply_colors()
@export var coin_color_b: Color = Color(1.0, 0.9, 0.0):
	set(v):
		coin_color_b = v
		if is_inside_tree(): _apply_colors()

var _elapsed: float = 0.0
var _portal_mats: Array[ShaderMaterial] = []
var _wobble_disk_a: MeshInstance3D = null
var _wobble_disk_b: MeshInstance3D = null
var _wobble_tilt_deg: float = 25.0
var _wobble_precess_speed: float = 1.5

func _ready() -> void:
	_rebuild()

func _rebuild() -> void:
	for child in get_children():
		if child is CollisionShape3D or child is OmniLight3D:
			continue
		child.queue_free()
	_portal_mats.clear()
	_wobble_disk_a = null
	_wobble_disk_b = null

	var packed: PackedScene = load(MESH_PATH)
	if packed == null:
		return
	var inst: Node3D = packed.instantiate()
	add_child(inst)
	_wire_nodes(inst)
	_apply_colors()

func _wire_nodes(root: Node3D) -> void:
	for node in root.find_children("*", "", true, false):
		if node is MeshInstance3D:
			var mi: MeshInstance3D = node
			if mi.has_meta("wobble_disk_a"):
				_wobble_disk_a = mi
			if mi.has_meta("wobble_disk_b"):
				_wobble_disk_b = mi

func _apply_colors() -> void:
	_portal_mats.clear()
	for node in find_children("*", "", true, false):
		if not (node is MeshInstance3D):
			continue
		var mi: MeshInstance3D = node
		if not mi.has_meta("disk_color_role"):
			continue
		var color: Color
		match mi.get_meta("disk_color_role"):
			"primary":  color = glow_color
			"wobble_a": color = coin_color_a
			"wobble_b": color = coin_color_b
			_:          color = glow_color
		var mat := ShaderMaterial.new()
		mat.shader = load("res://addons/exit_portal_free/portal_disk.gdshader")
		mat.set_shader_parameter("glow_color", color)
		mat.set_shader_parameter("pulse_speed", mi.get_meta("disk_pulse_speed"))
		mat.set_shader_parameter("core_fill",   mi.get_meta("disk_core_fill"))
		mat.set_shader_parameter("base_alpha",  mi.get_meta("disk_base_alpha"))
		mat.set_shader_parameter("ring_width",  mi.get_meta("disk_ring_width"))
		mi.set_surface_override_material(0, mat)
		_portal_mats.append(mat)

func _process(delta: float) -> void:
	if Engine.is_editor_hint():
		return
	_elapsed += delta
	for mat in _portal_mats:
		mat.set_shader_parameter("elapsed", _elapsed)
	if _wobble_disk_a != null and is_instance_valid(_wobble_disk_a):
		var tilt: float = deg_to_rad(_wobble_tilt_deg)
		var phi: float = _elapsed * _wobble_precess_speed
		var nA := Vector3(sin(tilt) * cos(phi), cos(tilt), sin(tilt) * sin(phi))
		var refA := Vector3.UP if absf(nA.dot(Vector3.UP)) < 0.99 else Vector3.RIGHT
		var xA := refA.cross(nA).normalized()
		_wobble_disk_a.basis = Basis(xA, nA.cross(xA).normalized(), nA)
		if _wobble_disk_b != null and is_instance_valid(_wobble_disk_b):
			var nB := Vector3(sin(tilt) * cos(phi), -cos(tilt), sin(tilt) * sin(phi))
			var refB := Vector3.UP if absf(nB.dot(Vector3.UP)) < 0.99 else Vector3.RIGHT
			var xB := refB.cross(nB).normalized()
			_wobble_disk_b.basis = Basis(xB, nB.cross(xB).normalized(), nB)
