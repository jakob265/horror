extends Node3D
class_name ChorusEmitter

# Boss fight Phase 2 - the entity reveals its chorus. A crew member's voice
# calls out from a fixed point in the arena, and 2.5 s later a SWEEP attack
# lands there. The voice tells you where NOT to be.

const LINES := [
	"here. by the light. come here.",
	"i can see you. come closer.",
	"this way. it's warmer here.",
	"i'm here. don't you want to see me?",
	"come stand by me. just for a second.",
]

const SPEAKERS := ["Sundqvist", "Renn", "Pak", "Kael", "Frey"]


# Speak from `world_pos` with a tight fade-in/out + faint whisper.
# Returns a tween for sequencing if the caller wants it.
static func speak_at(parent: Node3D, world_pos: Vector3) -> void:
	var label := Label3D.new()
	label.text = "%s: \"%s\"" % [SPEAKERS[randi() % SPEAKERS.size()], LINES[randi() % LINES.size()]]
	label.position = world_pos + Vector3(0, 1.6, 0)
	label.font_size = 26
	label.outline_size = 8
	label.modulate = Color(0.86, 0.78, 0.62, 0.0)
	label.outline_modulate = Color(0, 0, 0, 0.85)
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.shaded = false
	label.no_depth_test = true
	parent.add_child(label)
	AudioManager.whisper_long()
	var tw := parent.create_tween()
	tw.tween_property(label, "modulate:a", 1.0, 0.4)
	tw.tween_interval(1.8)
	tw.tween_property(label, "modulate:a", 0.0, 0.7)
	tw.tween_callback(label.queue_free)
