extends Control


func update_battery(level: float) -> void:
	var pct: float = clamp(level, 0.0, 1.0)
	var bar: Panel = $BatteryFrame/Bar
	# Anchor the bar's right edge to the fill percentage.
	bar.anchor_right = pct
	$PercentLabel.text = "%d%%" % int(round(pct * 100.0))
	if pct < 0.15:
		var t: float = sin(Time.get_ticks_msec() / 1000.0 * 6.0) * 0.5 + 0.5
		var style: StyleBoxFlat = bar.get_theme_stylebox("panel") as StyleBoxFlat
		if style:
			style.bg_color = Color(1.0, 0.36 * t, 0.30 * t, 1.0)
		$PercentLabel.modulate = Color(1.0, 0.45 + 0.4 * t, 0.42 + 0.4 * t, 1.0)
	elif pct < 0.35:
		var style2: StyleBoxFlat = bar.get_theme_stylebox("panel") as StyleBoxFlat
		if style2:
			style2.bg_color = Color(0.95, 0.78, 0.42, 1.0)
		$PercentLabel.modulate = Color(0.95, 0.82, 0.62, 1.0)
	else:
		var style3: StyleBoxFlat = bar.get_theme_stylebox("panel") as StyleBoxFlat
		if style3:
			style3.bg_color = Color(0.78, 0.86, 0.96, 1.0)
		$PercentLabel.modulate = Color(0.86, 0.92, 1.0, 1.0)
