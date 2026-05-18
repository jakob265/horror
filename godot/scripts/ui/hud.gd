extends Control


func _ready() -> void:
	$BatteryBG.anchor_left = 0.02
	$BatteryBG.anchor_top = 0.94


func update_battery(level: float) -> void:
	$BatteryBG/Bar.scale.x = clamp(level, 0.01, 1.0)
	if level < 0.15:
		var t := sin(Time.get_ticks_msec() / 1000.0 * 6.0) * 0.5 + 0.5
		$BatteryBG/Bar.color = Color(1.0, 0.31 * t, 0.31 * t, 1.0)
	else:
		$BatteryBG/Bar.color = Color(0.86, 0.86, 0.86, 1.0)
