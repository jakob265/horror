extends Node
# Minimal Discord Rich Presence over Discord's local IPC pipe — pure GDScript,
# no native addon. It frames JSON (op + length, little-endian) the way the
# Discord client expects and sends SET_ACTIVITY so the game shows up under your
# profile as "Playing <app name>" with a per-room status line.
#
# SETUP (one-time):
#   1. Create an application at https://discord.com/developers/applications
#      and name it whatever you want shown after "Playing " (e.g. CRESTFALL-9).
#   2. Copy its Application ID and paste it into CLIENT_ID below.
#   3. (Optional) Under Rich Presence > Art Assets, upload an image keyed
#      "crestfall" for the large icon.
#
# Transport notes: works on Windows via the \\.\pipe\discord-ipc-N named pipe,
# which Godot's FileAccess can open directly. On Linux/macOS the IPC endpoint is
# a unix domain socket that FileAccess can't speak, so it stays a no-op there.
# If Discord isn't running, the ID isn't set, or the pipe can't be opened, this
# disables itself silently — it never blocks the game or throws.

const CLIENT_ID := "0000000000000000000"   # <-- your Discord Application ID
const APP_NAME := "CRESTFALL-9"
const LARGE_IMAGE := "crestfall"

const ACT_LABELS := {
	"act1": "Waking in the Cryo Bay",
	"act2": "Decontamination",
	"act_med": "The Medical Bay",
	"act3": "The Residential Corridor",
	"act4": "The Observation Lounge",
	"act_obs": "The Observation Deck",
	"act_mess": "The Crew Mess",
	"act_comms": "The Comms Core",
	"act5": "The Signal Lab",
	"act6": "Hydroponics",
	"act_cargo": "The Cargo Bay",
	"act7": "Engineering",
	"act_eva": "The EVA Airlock",
	"act_storage": "Cryo Storage",
	"act8": "The Bridge",
	"act_maint": "The Maintenance Crawl",
	"act9": "The Final Approach",
	"act10": "The Array Chamber",
}

var _pipe: FileAccess = null
var _connected := false
var _start_unix := 0


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_start_unix = int(Time.get_unix_time_from_system())
	if CLIENT_ID == "0000000000000000000" or CLIENT_ID.strip_edges() == "":
		return                                  # not configured -> stay a no-op
	_try_connect()
	if _connected:
		if not SceneRouter.scene_changed.is_connected(_on_scene_changed):
			SceneRouter.scene_changed.connect(_on_scene_changed)
		set_menu_state()


func _exit_tree() -> void:
	_close()


# --- Public ---------------------------------------------------------------

func set_menu_state() -> void:
	set_state("In the main menu", "Crestfall-9")


func set_state(details: String, state: String) -> void:
	if not _connected:
		return
	var activity := {
		"details": details,
		"state": state,
		"timestamps": {"start": _start_unix},
		"assets": {"large_image": LARGE_IMAGE, "large_text": APP_NAME},
	}
	var payload := {
		"cmd": "SET_ACTIVITY",
		"args": {"pid": OS.get_process_id(), "activity": activity},
		"nonce": str(Time.get_ticks_usec()),
	}
	if not _write_frame(1, payload):
		_close()


# --- Internals ------------------------------------------------------------

func _on_scene_changed(act_name: String) -> void:
	var label: String = ACT_LABELS.get(act_name, "Exploring the station")
	set_state(label, "Aboard Crestfall-9")


func _try_connect() -> void:
	for i in 10:
		var path := _pipe_path(i)
		if path == "":
			break
		var f := FileAccess.open(path, FileAccess.READ_WRITE)
		if f != null:
			_pipe = f
			if _write_frame(0, {"v": 1, "client_id": CLIENT_ID}):
				_connected = true
				return
			_pipe = null
	_connected = false


func _pipe_path(i: int) -> String:
	if OS.get_name() == "Windows":
		return "\\\\.\\pipe\\discord-ipc-%d" % i
	var base := OS.get_environment("XDG_RUNTIME_DIR")
	if base == "":
		base = "/tmp"
	return "%s/discord-ipc-%d" % [base, i]


func _write_frame(op: int, payload: Dictionary) -> bool:
	if _pipe == null:
		return false
	var data := JSON.stringify(payload).to_utf8_buffer()
	var header := PackedByteArray()
	header.resize(8)
	header.encode_u32(0, op)
	header.encode_u32(4, data.size())
	_pipe.store_buffer(header)
	_pipe.store_buffer(data)
	_pipe.flush()
	var err := _pipe.get_error()
	return err == OK or err == ERR_FILE_EOF


func _close() -> void:
	if _pipe != null:
		_pipe.close()
		_pipe = null
	_connected = false
