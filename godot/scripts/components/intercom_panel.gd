class_name IntercomPanel
extends Node3D
# Small wall panel that glows while OLEN is speaking through it.

var led: MeshInstance3D
var led_mat: StandardMaterial3D
var speaking := false
var pulse_phase := 0.0


static func create(position: Vector3, rotation_y: float = 0.0) -> IntercomPanel:
	var p := IntercomPanel.new()
	p.position = position
	p.rotation_degrees = Vector3(0, rotation_y, 0)
	# Body
	var body := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = Vector3(0.32, 0.22, 0.04)
	body.mesh = box
	var body_mat := StandardMaterial3D.new()
	body_mat.albedo_color = Color(0.20, 0.22, 0.24)
	body.material_override = body_mat
	p.add_child(body)
	# LED
	p.led = MeshInstance3D.new()
	var lbox := BoxMesh.new()
	lbox.size = Vector3(0.18, 0.08, 0.02)
	p.led.mesh = lbox
	p.led.position = Vector3(0, 0.05, -0.04)
	p.led_mat = StandardMaterial3D.new()
	p.led_mat.albedo_color = Color(0.16, 0.24, 0.32)
	p.led_mat.emission_enabled = true
	p.led_mat.emission = Color(0.16, 0.24, 0.32)
	p.led_mat.emission_energy_multiplier = 0.5
	p.led.material_override = p.led_mat
	p.add_child(p.led)
	return p


func set_speaking(on: bool) -> void:
	speaking = on
	if not on:
		led_mat.emission = Color(0.16, 0.24, 0.32)
		led_mat.emission_energy_multiplier = 0.5


func _process(delta: float) -> void:
	if speaking:
		pulse_phase += delta * 4.0
		var b := 0.5 + 0.5 * sin(pulse_phase)
		led_mat.emission = Color(0.31 + 0.39 * b, 0.59 + 0.24 * b, 0.86 + 0.14 * b)
		led_mat.emission_energy_multiplier = 1.5 + b
