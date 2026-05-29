extends CharacterBody3D
# First-person player. Mirrors systems/player.py.
# Mouse look, WASD + sprint + crouch, F flashlight w/ battery, head bob.

const BASE_SPEED := 4.5
const SPRINT_MULT := 1.6
const CROUCH_MULT := 0.6
const STAND_HEIGHT := 1.7
const CROUCH_HEIGHT := 1.3
const GRAVITY := 18.0
const MOUSE_SENS_DEFAULT := 0.0028
const BATTERY_LIFE := 110.0  # seconds of light per full cell (no passive recharge)

@onready var head: Node3D = $Head
@onready var camera: Camera3D = $Head/Camera3D
@onready var flashlight: SpotLight3D = $Head/Camera3D/Flashlight
@onready var flashlight_core: SpotLight3D = $Head/Camera3D/FlashlightCore
@onready var col: CollisionShape3D = $CollisionShape3D

var frozen := false
var crouching := false
var bob_phase := 0.0
var breath_phase := 0.0
var flashlight_on := false
var flashlight_battery := 1.0
var mouse_sens := MOUSE_SENS_DEFAULT
var hud: Control = null
var hidden := false
var _hide_overlay: Control = null
var has_gun := false
var ammo := 0
var _gun_view: Node3D = null
var _muzzle: OmniLight3D = null
var _ammo_label: Label = null
var hp := 100.0
var max_hp := 100.0
var _since_hit := 99.0
var _hp_fill: ColorRect = null
var _dmg_flash: ColorRect = null


func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	flashlight.visible = false
	flashlight_core.visible = false


func _unhandled_input(event: InputEvent) -> void:
	if frozen:
		return
	if event is InputEventMouseMotion:
		rotate_y(-event.relative.x * mouse_sens)
		head.rotate_x(-event.relative.y * mouse_sens)
		head.rotation.x = clamp(head.rotation.x, -PI / 2.0 + 0.1, PI / 2.0 - 0.1)


func _physics_process(delta: float) -> void:
	_health_tick(delta)
	if frozen:
		velocity = Vector3.ZERO
		move_and_slide()
		_update_flashlight(delta)
		return

	if hidden:
		# Pinned in place while hiding; look is still free so you can watch.
		velocity.x = 0.0
		velocity.z = 0.0
		if not is_on_floor():
			velocity.y -= GRAVITY * delta
		else:
			velocity.y = -0.1
		move_and_slide()
		_update_flashlight(delta)
		return

	# Movement
	var dir := Vector3.ZERO
	if Input.is_action_pressed("move_forward"): dir.z -= 1
	if Input.is_action_pressed("move_back"):    dir.z += 1
	if Input.is_action_pressed("move_left"):    dir.x -= 1
	if Input.is_action_pressed("move_right"):   dir.x += 1
	if dir.length() > 0:
		GameState.mark_first_move()
	dir = (transform.basis * dir).normalized()
	var sprint := Input.is_action_pressed("sprint")
	crouching = Input.is_action_pressed("crouch")
	var speed := BASE_SPEED
	if sprint and not crouching:
		speed *= SPRINT_MULT
	elif crouching:
		speed *= CROUCH_MULT
	velocity.x = dir.x * speed
	velocity.z = dir.z * speed
	if not is_on_floor():
		velocity.y -= GRAVITY * delta
	else:
		velocity.y = -0.1
	move_and_slide()

	# Smooth head height (crouch)
	var target_y := CROUCH_HEIGHT if crouching else STAND_HEIGHT
	head.position.y = lerp(head.position.y, target_y, min(1.0, delta * 10.0))

	# Head bob / breathing
	var moving := dir.length() > 0.01
	var offset := 0.0
	if moving:
		var amp := 0.028 if sprint else 0.015
		var freq := 11.0 if sprint else 8.0
		bob_phase += delta * freq
		offset = amp * sin(bob_phase)
	else:
		breath_phase += delta * (TAU * 0.28)
		offset = 0.004 * sin(breath_phase)
	head.position.y += offset

	_update_flashlight(delta)


func _update_flashlight(delta: float) -> void:
	# Drains only while on. No passive recharge — refill with a spare battery (R).
	if flashlight_on:
		flashlight_battery = max(0.0, flashlight_battery - delta / BATTERY_LIFE)
		if flashlight_battery <= 0.0:
			flashlight_on = false
			flashlight.visible = false
			flashlight_core.visible = false
	# Brown-out as the cell dies: dim the energy in the last 18%.
	if flashlight_on:
		var t: float = clamp(flashlight_battery / 0.18, 0.30, 1.0)
		flashlight.light_energy = 4.5 * t
		flashlight_core.light_energy = 2.8 * t
	if hud and hud.has_method("update_battery"):
		hud.update_battery(flashlight_battery)


func handle_input(event: InputEvent) -> void:
	if frozen:
		return
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT and not hidden:
		fire()
		return
	if event is InputEventKey and event.pressed and not event.echo:
		if hidden:
			if event.keycode == KEY_E:
				exit_hide()
			return
		if event.keycode == KEY_F:
			toggle_flashlight()
		elif event.keycode == KEY_R:
			reload_battery()


func toggle_flashlight() -> void:
	if flashlight_battery <= 0.0 and not flashlight_on:
		return
	flashlight_on = not flashlight_on
	flashlight.visible = flashlight_on
	flashlight_core.visible = flashlight_on


func reload_battery() -> void:
	if flashlight_battery >= 0.98:
		return
	if InventoryManager.has("spare_battery"):
		InventoryManager.remove("spare_battery", 1)
		flashlight_battery = 1.0


func freeze() -> void:
	frozen = true


func unfreeze() -> void:
	frozen = false
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED


func set_mouse_sensitivity(v: float) -> void:
	mouse_sens = v


func get_collider_rid() -> RID:
	return get_rid()


# --- Health ---------------------------------------------------------------

func take_damage(n: float) -> void:
	if hp <= 0.0:
		return
	hp -= n
	_since_hit = 0.0
	_flash_damage()
	if hp <= 0.0:
		hp = 0.0
		_update_health()
		GameState.catch_player()      # full death -> fade + respawn
		return
	_update_health()


func _health_tick(delta: float) -> void:
	if hud != null and is_instance_valid(hud) and _hp_fill == null:
		_build_health_ui()
	_since_hit += delta
	if hp > 0.0 and hp < max_hp and _since_hit > 3.5:
		hp = minf(max_hp, hp + 9.0 * delta)
		_update_health()


func _build_health_ui() -> void:
	var bg := ColorRect.new()
	bg.color = Color(0.08, 0.08, 0.10, 0.7)
	bg.anchor_top = 1.0
	bg.anchor_bottom = 1.0
	bg.offset_left = 40
	bg.offset_right = 244
	bg.offset_top = -52
	bg.offset_bottom = -34
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hud.add_child(bg)
	_hp_fill = ColorRect.new()
	_hp_fill.color = Color(0.75, 0.16, 0.14)
	_hp_fill.anchor_bottom = 1.0
	_hp_fill.anchor_right = 1.0
	_hp_fill.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bg.add_child(_hp_fill)
	_dmg_flash = ColorRect.new()
	_dmg_flash.set_anchors_preset(Control.PRESET_FULL_RECT)
	_dmg_flash.anchor_right = 1.0
	_dmg_flash.anchor_bottom = 1.0
	_dmg_flash.color = Color(0.6, 0, 0, 0)
	_dmg_flash.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hud.add_child(_dmg_flash)
	_update_health()


func _update_health() -> void:
	if _hp_fill and is_instance_valid(_hp_fill):
		_hp_fill.anchor_right = clampf(hp / max_hp, 0.0, 1.0)


func _flash_damage() -> void:
	if _dmg_flash and is_instance_valid(_dmg_flash):
		_dmg_flash.color = Color(0.6, 0.0, 0.0, 0.45)
		create_tween().tween_property(_dmg_flash, "color", Color(0.6, 0, 0, 0.0), 0.4)


func revive() -> void:
	hp = max_hp
	_since_hit = 99.0
	_update_health()


# --- Hiding ---------------------------------------------------------------

func enter_hide(_data: Dictionary = {}) -> void:
	if hidden:
		return
	hidden = true
	GameState.player_hidden = true
	if flashlight_on:
		toggle_flashlight()
	velocity = Vector3.ZERO
	AudioManager.breath()
	_show_hide_overlay()


func exit_hide() -> void:
	if not hidden:
		return
	hidden = false
	GameState.player_hidden = false
	if _hide_overlay and is_instance_valid(_hide_overlay):
		_hide_overlay.queue_free()
	_hide_overlay = null


func _show_hide_overlay() -> void:
	if hud == null or not is_instance_valid(hud):
		return
	_hide_overlay = Control.new()
	_hide_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	_hide_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_add_hide_bar(0.0, 0.0, 1.0, 0.22)
	_add_hide_bar(0.0, 0.78, 1.0, 1.0)
	_add_hide_bar(0.0, 0.22, 0.19, 0.78)
	_add_hide_bar(0.81, 0.22, 1.0, 0.78)
	_add_hide_bar(0.47, 0.22, 0.50, 0.78)
	var hint := Label.new()
	hint.text = "Hidden    [E] step out"
	hint.add_theme_font_size_override("font_size", 15)
	hint.add_theme_color_override("font_color", Color(0.78, 0.80, 0.85))
	hint.anchor_left = 0.5
	hint.anchor_top = 0.84
	hint.position = Vector2(-72, 0)
	_hide_overlay.add_child(hint)
	hud.add_child(_hide_overlay)


func _add_hide_bar(l: float, t: float, r: float, b: float) -> void:
	var c := ColorRect.new()
	c.color = Color(0, 0, 0, 1)
	c.anchor_left = l
	c.anchor_top = t
	c.anchor_right = r
	c.anchor_bottom = b
	c.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_hide_overlay.add_child(c)


# --- Gun (the finale) -----------------------------------------------------

func equip_gun(n: int) -> void:
	ammo += n
	if not has_gun:
		has_gun = true
		_build_gun_view()
	_update_ammo()


func _build_gun_view() -> void:
	_gun_view = Node3D.new()
	camera.add_child(_gun_view)
	_gun_view.position = Vector3(0.22, -0.20, -0.45)
	var metal := StandardMaterial3D.new()
	metal.albedo_color = Color(0.12, 0.12, 0.14)
	metal.metallic = 0.7
	metal.roughness = 0.4
	for part in [[Vector3(0.08, 0.12, 0.32), Vector3(0, 0, 0)], [Vector3(0.045, 0.05, 0.30), Vector3(0, 0.03, -0.28)], [Vector3(0.06, 0.16, 0.09), Vector3(0, -0.12, 0.10)]]:
		var mi := MeshInstance3D.new()
		var b := BoxMesh.new()
		b.size = part[0]
		mi.mesh = b
		mi.position = part[1]
		mi.material_override = metal
		_gun_view.add_child(mi)
	_muzzle = OmniLight3D.new()
	_muzzle.light_color = Color(1.0, 0.85, 0.5)
	_muzzle.light_energy = 0.0
	_muzzle.omni_range = 4.0
	_muzzle.position = Vector3(0, 0.03, -0.45)
	_gun_view.add_child(_muzzle)
	if hud and is_instance_valid(hud):
		_ammo_label = Label.new()
		_ammo_label.add_theme_font_size_override("font_size", 20)
		_ammo_label.add_theme_color_override("font_color", Color(0.9, 0.85, 0.6))
		_ammo_label.anchor_left = 0.88
		_ammo_label.anchor_top = 0.9
		hud.add_child(_ammo_label)
		var cross := Label.new()
		cross.text = "+"
		cross.add_theme_font_size_override("font_size", 22)
		cross.add_theme_color_override("font_color", Color(0.9, 0.9, 0.9, 0.7))
		cross.anchor_left = 0.5
		cross.anchor_top = 0.5
		cross.position = Vector2(-7, -14)
		hud.add_child(cross)


func _update_ammo() -> void:
	if _ammo_label and is_instance_valid(_ammo_label):
		_ammo_label.text = "AMMO  %d" % ammo


func fire() -> void:
	if not has_gun or hidden or ammo <= 0:
		return
	ammo -= 1
	_update_ammo()
	AudioManager.gunshot()
	if _muzzle:
		_muzzle.light_energy = 3.0
		create_tween().tween_property(_muzzle, "light_energy", 0.0, 0.08)
	if _gun_view:
		_gun_view.position.z = -0.38
		create_tween().tween_property(_gun_view, "position:z", -0.45, 0.10)
	var space := camera.get_world_3d().direct_space_state
	var from := camera.global_position
	var to := from - camera.global_transform.basis.z * 60.0
	var params := PhysicsRayQueryParameters3D.create(from, to)
	params.collide_with_bodies = true
	params.collide_with_areas = true
	params.exclude = [get_collider_rid()]
	var hit := space.intersect_ray(params)
	var endpoint := to
	if not hit.is_empty():
		endpoint = hit["position"]
		var n: Node = hit["collider"]
		while n and not n.has_meta("on_shot"):
			n = n.get_parent()
		if n and n.has_meta("on_shot"):
			var cb: Callable = n.get_meta("on_shot")
			if cb.is_valid():
				cb.call()
	_tracer(_muzzle.global_position if _muzzle else from, endpoint)


func _tracer(from: Vector3, to: Vector3) -> void:
	var dist := from.distance_to(to)
	if dist < 0.05:
		return
	var tr := MeshInstance3D.new()
	var cyl := CylinderMesh.new()
	cyl.top_radius = 0.012
	cyl.bottom_radius = 0.012
	cyl.height = dist
	cyl.radial_segments = 5
	tr.mesh = cyl
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(1.0, 0.9, 0.6)
	mat.emission_enabled = true
	mat.emission = Color(1.0, 0.85, 0.5)
	mat.emission_energy_multiplier = 5.0
	tr.material_override = mat
	var holder := get_tree().current_scene
	if holder == null:
		return
	holder.add_child(tr)
	tr.global_position = (from + to) * 0.5
	tr.look_at(to, Vector3.UP)
	tr.rotate_object_local(Vector3(1, 0, 0), PI / 2.0)
	var t := create_tween()
	t.tween_property(mat, "emission_energy_multiplier", 0.0, 0.13)
	t.tween_callback(tr.queue_free)
