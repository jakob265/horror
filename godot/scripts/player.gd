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
	if frozen:
		velocity = Vector3.ZERO
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
	if event is InputEventKey and event.pressed and not event.echo:
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
