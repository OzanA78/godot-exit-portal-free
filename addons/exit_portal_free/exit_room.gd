extends Node3D

@export var tile_ew: int = 1
@export var tile_n: int = 1
@export var tile_s: int = 1
@export var floor_tile: int = 1
@export var emission_energy: float = 0.0
@export var wall_texture: Texture2D = null
@export var floor_texture: Texture2D = null
@export var metallic: float = 0.8
@export var roughness: float = 0.3

func _ready() -> void:
	_apply_tiling()
	_apply_floor()

func set_floor_texture(tex: Texture2D) -> void:
	floor_texture = tex
	_apply_floor()

func _apply_floor() -> void:
	var floor_mesh := get_node_or_null("Floor") as MeshInstance3D
	if floor_mesh == null or floor_texture == null or floor_mesh.mesh == null:
		return
	var mat: StandardMaterial3D = floor_mesh.get_surface_override_material(0) as StandardMaterial3D
	if mat == null:
		mat = StandardMaterial3D.new()
	else:
		mat = mat.duplicate() as StandardMaterial3D
	mat.metallic = metallic
	mat.roughness = roughness
	mat.albedo_texture = floor_texture
	var ms: Vector2 = _mesh_uv_size(floor_mesh.mesh)
	var ts: Vector2 = floor_texture.get_size()
	if ms != Vector2.ZERO and ts.x > 0.0 and ts.y > 0.0:
		mat.uv1_scale = _calc_uv(ms, ts, max(floor_tile, 1))
	floor_mesh.set_surface_override_material(0, mat)

func set_emission_energy(energy: float) -> void:
	emission_energy = energy
	_apply_tiling()

func set_metallic(value: float) -> void:
	metallic = clampf(value, 0.0, 1.0)
	_apply_tiling()

func set_roughness(value: float) -> void:
	roughness = clampf(value, 0.0, 1.0)
	_apply_tiling()

func set_wall_texture(tex: Texture2D) -> void:
	wall_texture = tex
	_apply_tiling()

func set_tile_counts(ew: int, n: int, s: int) -> void:
	tile_ew = max(ew, 1)
	tile_n = max(n, 1)
	tile_s = max(s, 1)
	_apply_tiling()

func _tile_for_body(body_name: String) -> int:
	var n := body_name.to_lower()
	if n.begins_with("roomback"):
		return tile_n
	if n.begins_with("roomfront"):
		return tile_s
	return tile_ew

func _apply_tiling() -> void:
	for body in get_children():
		if not (body is StaticBody3D):
			continue
		var body_tile: int = _tile_for_body(body.name)
		for node in body.find_children("*", "MeshInstance3D", true, false):
			var mi: MeshInstance3D = node as MeshInstance3D
			if mi == null or mi.mesh == null:
				continue
			var mat: StandardMaterial3D = mi.get_surface_override_material(0) as StandardMaterial3D
			if mat == null:
				continue
			mat = mat.duplicate() as StandardMaterial3D
			mi.set_surface_override_material(0, mat)
			mat.metallic = metallic
			mat.roughness = roughness
			if wall_texture != null:
				mat.albedo_texture = wall_texture
			if mat.albedo_texture == null:
				continue
			var ms: Vector2 = _mesh_uv_size(mi.mesh)
			var ts: Vector2 = mat.albedo_texture.get_size()
			if ms != Vector2.ZERO and ts.x > 0.0 and ts.y > 0.0:
				mat.uv1_scale = _calc_uv(ms, ts, max(body_tile, 1))
			if emission_energy > 0.0:
				mat.emission_enabled = true
				mat.emission_operator = BaseMaterial3D.EMISSION_OP_ADD
				mat.emission_texture = mat.albedo_texture
				mat.emission_energy_multiplier = emission_energy
			else:
				mat.emission_enabled = false

func _mesh_uv_size(mesh: Mesh) -> Vector2:
	if mesh is BoxMesh:
		var bs: Vector3 = (mesh as BoxMesh).size
		var arr: Array[float] = [bs.x, bs.y, bs.z]
		arr.sort()
		return Vector2(arr[2], arr[1])
	if mesh is PlaneMesh:
		return (mesh as PlaneMesh).size
	if mesh is QuadMesh:
		return (mesh as QuadMesh).size
	return Vector2.ZERO

func _calc_uv(mesh_size: Vector2, tex_size: Vector2, count: int) -> Vector3:
	var tex_landscape: bool = tex_size.x >= tex_size.y
	var mesh_landscape: bool = mesh_size.x >= mesh_size.y
	var tex_long: float = maxf(tex_size.x, tex_size.y)
	var tex_short: float = minf(tex_size.x, tex_size.y)
	var tex_aspect: float = tex_short / tex_long
	var mesh_long: float = maxf(mesh_size.x, mesh_size.y)
	var tile_long: float = mesh_long / float(count)
	var tile_short: float = tile_long * tex_aspect
	if tex_landscape == mesh_landscape:
		if mesh_landscape:
			return Vector3(mesh_size.x / tile_long, mesh_size.y / tile_short, 1.0)
		else:
			return Vector3(mesh_size.x / tile_short, mesh_size.y / tile_long, 1.0)
	else:
		if mesh_landscape:
			return Vector3(mesh_size.x / tile_short, mesh_size.y / tile_long, 1.0)
		else:
			return Vector3(mesh_size.x / tile_long, mesh_size.y / tile_short, 1.0)
