extends Node
# Discord Rich Presence, driven through the optional GDExtension addon
# "Discord Rich Presence" (vaporvee) which exposes a global "DiscordRPC"
# singleton with the native binaries that actually speak Discord's IPC.
#
# This wrapper finds that singleton at runtime and feeds it a per-room status.
# Without the addon installed, or without an App ID set, it is a silent no-op,
# so the game always runs normally.
#
# SETUP (one-time, all inside the Godot editor + Discord):
#   1. Editor -> AssetLib tab -> search "Discord Rich Presence" (vaporvee's
#      GDExtension) -> Download -> Install. Then Project > Project Settings >
#      Plugins -> enable it. Installing from AssetLib gets binaries that match
#      YOUR Godot version + OS, which is why we don't ship them in the repo.
#   2. https://discord.com/developers/applications -> New Application. Name it
#      exactly what you want shown after "Playing " (e.g. VESPER). Copy its
#      Application ID into APP_ID below (keep it quoted).
#   3. (Optional) Rich Presence > Art Assets -> upload an image keyed "logo".
#   4. Run the Discord desktop app. In Discord: User Settings > Activity
#      Privacy > "Share your detected activities" must be ON.

const APP_ID := "0"          # <-- your Discord Application ID (digits, quoted)
const APP_NAME := "VESPER"
const LARGE_IMAGE := "logo"  # an Art Asset key from the dev portal (optional)

const ACT_LABELS := {
	"act1": "The Surface",
	"act2": "The Dormitory Wing",
	"act3": "The Mess & Infirmary",
	"act4": "The Sample Labs",
	"act5": "The Generator Hall",
	"act6": "Cold Storage",
	"act7": "The Drill Shaft",
	"act8": "The Ice Caves",
	"act9": "The Sealed Chamber",
	"act10": "Dawn",
}

var _rpc: Node = null
var _start := 0


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_start = int(Time.get_unix_time_from_system())
	# Defer so the addon's own autoload is guaranteed to exist regardless of
	# autoload ordering.
	call_deferred("_late_init")


func _late_init() -> void:
	_rpc = get_node_or_null("/root/DiscordRPC")
	if _rpc == null or not APP_ID.is_valid_int() or APP_ID == "0":
		_rpc = null
		set_process(false)
		return
	_rpc.set("app_id", int(APP_ID))
	if not SceneRouter.scene_changed.is_connected(_on_scene_changed):
		SceneRouter.scene_changed.connect(_on_scene_changed)
	set_menu_state()


func _process(_dt: float) -> void:
	if _rpc != null and _rpc.has_method("run_callbacks"):
		_rpc.call("run_callbacks")


# --- Public ---------------------------------------------------------------

func set_menu_state() -> void:
	_apply("In the main menu", APP_NAME)


func set_state(details: String, state: String) -> void:
	_apply(details, state)


# --- Internals ------------------------------------------------------------

func _on_scene_changed(act_name: String) -> void:
	_apply(ACT_LABELS.get(act_name, "Exploring Vesper Station"), "Aboard Vesper")


func _apply(details: String, state: String) -> void:
	if _rpc == null:
		return
	_rpc.set("details", details)
	_rpc.set("state", state)
	_rpc.set("large_image", LARGE_IMAGE)
	_rpc.set("large_image_text", APP_NAME)
	_rpc.set("start_timestamp", _start)
	if _rpc.has_method("refresh"):
		_rpc.call("refresh")
