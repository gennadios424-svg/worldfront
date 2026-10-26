extends Node2D

# Worldfront: larger top-down gathering prototype with animated pixel people.
const MAP_RECT := Rect2(36, 82, 1368, 780)
const RED := Color("#d94a48")
const BLUE := Color("#4388e8")
const LAND := Color("#83b96b")
const WOOD := Color("#80502e")
const LEAF := Color("#2f6e3d")
const STONE := Color("#929b9c")
const SKIN := Color("#d9a47c")

var capitals := {
	"red": Vector2(135, 470),
	"blue": Vector2(1305, 470)
}
var stock := {
	"red": {"wood": 0, "stone": 0},
	"blue": {"wood": 0, "stone": 0}
}
var civilians: Array[Dictionary] = []
var resources: Array[Dictionary] = []
var elapsed := 0.0

func _ready() -> void:
	randomize()
	_make_resources()
	_make_civilians()
	queue_redraw()

func _make_resources() -> void:
	resources = [
		{"kind": "tree", "pos": Vector2(320, 235), "amount": 100},
		{"kind": "tree", "pos": Vector2(425, 680), "amount": 100},
		{"kind": "tree", "pos": Vector2(555, 365), "amount": 100},
		{"kind": "tree", "pos": Vector2(730, 585), "amount": 100},
		{"kind": "tree", "pos": Vector2(900, 235), "amount": 100},
		{"kind": "tree", "pos": Vector2(1080, 680), "amount": 100},
		{"kind": "tree", "pos": Vector2(1170, 360), "amount": 100},
		{"kind": "rock", "pos": Vector2(285, 650), "amount": 100},
		{"kind": "rock", "pos": Vector2(610, 690), "amount": 100},
		{"kind": "rock", "pos": Vector2(800, 300), "amount": 100},
		{"kind": "rock", "pos": Vector2(1015, 510), "amount": 100}
	]

func _make_civilians() -> void:
	for team in ["red", "blue"]:
		for i in range(7):
			var offset := Vector2(randf_range(-35.0, 35.0), randf_range(-65.0, 65.0))
			civilians.append({
				"team": team,
				"pos": capitals[team] + offset,
				"state": "gather",
				"target": -1,
				"carry": "",
				"wait": randf_range(0.0, 1.2),
				"wander": Vector2.ZERO,
				"stamina": randf_range(62.0, 100.0),
				"style": i % 4,
				"phase": randf_range(0.0, TAU),
				"facing": -1 if team == "red" else 1,
				"load": 0
			})

func _process(delta: float) -> void:
	elapsed += delta
	for person in civilians:
		_update_civilian(person, delta)
	queue_redraw()

func _update_civilian(person: Dictionary, delta: float) -> void:
	var team: String = person["team"]
	var pos: Vector2 = person["pos"]
	var state: String = person["state"]

	if state == "rest":
		person["stamina"] = minf(100.0, float(person["stamina"]) + delta * 15.0)
		person["wait"] = float(person["wait"]) - delta
		if float(person["wait"]) <= 0.0 and float(person["stamina"]) >= 48.0:
			person["state"] = "gather"
			person["wait"] = randf_range(0.2, 0.9)
		return

	if state == "return" or float(person["stamina"]) <= 8.0:
		if float(person["stamina"]) <= 8.0 and state != "return":
			person["state"] = "rest"
			person["wait"] = randf_range(2.5, 5.0)
			return
		var base: Vector2 = capitals[team]
		if pos.distance_to(base) < 38.0:
			if person["carry"] != "":
				stock[team][person["carry"]] += 1
			person["carry"] = ""
			person["load"] = 0
			person["state"] = "rest" if float(person["stamina"]) < 35.0 else "gather"
			person["wait"] = randf_range(1.8, 3.6) if float(person["stamina"]) < 35.0 else randf_range(0.4, 1.0)
			return
		_move_person(person, base, delta, true)
		return

	if float(person["wait"]) > 0.0:
		person["wait"] = float(person["wait"]) - delta
		return

	var target_index: int = int(person["target"])
	if target_index < 0 or target_index >= resources.size() or int(resources[target_index]["amount"]) <= 0:
		target_index = _choose_resource(pos)
		person["target"] = target_index
		if target_index == -1:
			person["state"] = "rest"
			person["wait"] = 2.0
			return

	var target_pos: Vector2 = resources[target_index]["pos"]
	if pos.distance_to(target_pos) > 27.0:
		_move_person(person, target_pos, delta, false)
	else:
		person["state"] = "gathering"
		person["wait"] = randf_range(1.0, 1.8)
		person["stamina"] = maxf(0.0, float(person["stamina"]) - 5.0)
		var kind: String = resources[target_index]["kind"]
		resources[target_index]["amount"] = int(resources[target_index]["amount"]) - 1
		person["carry"] = "wood" if kind == "tree" else "stone"
		person["load"] = 1 if kind == "tree" else 2
		person["state"] = "return"

func _move_person(person: Dictionary, target: Vector2, delta: float, carrying: bool) -> void:
	var pos: Vector2 = person["pos"]
	var direction := target - pos
	if absf(direction.x) > 1.0:
		person["facing"] = 1 if direction.x > 0.0 else -1
	var style: int = int(person["style"])
	var speed := [54.0, 47.0, 60.0, 43.0][style]
	if style == 2 and not carrying and float(person["stamina"]) > 55.0:
		speed = 75.0 # This villager sometimes breaks into a jog.
	if carrying:
		speed *= 0.60 if int(person["load"]) == 2 else 0.72
		person["stamina"] = maxf(0.0, float(person["stamina"]) - delta * (7.5 if int(person["load"]) == 2 else 5.0))
	else:
		person["stamina"] = maxf(0.0, float(person["stamina"]) - delta * 2.4)
	person["pos"] = pos.move_toward(target, speed * delta)
	person["phase"] = float(person["phase"]) + delta * (speed / 5.5)

func _choose_resource(from: Vector2) -> int:
	var best_index := -1
	var best_distance := INF
	for i in range(resources.size()):
		if int(resources[i]["amount"]) <= 0:
			continue
		var distance: float = from.distance_to(resources[i]["pos"])
		if distance < best_distance:
			best_distance = distance
			best_index = i
	return best_index

func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, Vector2(1440, 900)), Color("#26352a"))
	draw_rect(MAP_RECT, Color("#789f5d"))
	_draw_terrain()
	_draw_paths()
	draw_rect(MAP_RECT, Color("#d0c9a9"), false, 4.0)
	_draw_top_bar()
	_draw_resources()
	_draw_capital("red")
	_draw_capital("blue")
	_draw_civilians()

func _draw_terrain() -> void:
	# Uneven grassland patches, scattered tufts, flowers, and darker scrub.
	for i in range(105):
		var x := 55.0 + float((i * 173 + 41) % 1325)
		var y := 100.0 + float((i * 97 + 19) % 735)
		var radius := 12.0 + float((i * 7) % 27)
		var patch := Color("#91c477") if i % 3 == 0 else Color("#638f50")
		draw_circle(Vector2(x, y), radius, Color(patch, 0.20))
	for i in range(210):
		var x := 48.0 + float((i * 67 + 23) % 1340)
		var y := 92.0 + float((i * 131 + 11) % 755)
		var tuft_color := Color("#426c3d") if i % 2 == 0 else Color("#b1cb79")
		draw_line(Vector2(x, y), Vector2(x + 2, y - 4 - float(i % 4)), tuft_color, 1.4)
		if i % 11 == 0:
			draw_circle(Vector2(x + 5, y - 2), 2.0, Color("#e7d98b"))

func _draw_paths() -> void:
	# Worn earth tracks radiate from both settlements.
	for team in ["red", "blue"]:
		var base: Vector2 = capitals[team]
		var paths := PackedVector2Array([base + Vector2(0, 25), Vector2(base.x, base.y + 75), Vector2(720, base.y + 95)])
		draw_polyline(paths, Color("#987a50"), 19.0, true)
		draw_polyline(paths, Color("#b59a6d"), 11.0, true)
	# A shallow winding stream gives the map a recognisable natural feature.
	var stream := PackedVector2Array([
		Vector2(690, 90), Vector2(665, 180), Vector2(700, 260),
		Vector2(670, 345), Vector2(705, 430), Vector2(680, 520),
		Vector2(720, 620), Vector2(700, 780), Vector2(735, 855)
	])
	draw_polyline(stream, Color("#4e886e"), 25.0, true)
	draw_polyline(stream, Color("#6ba8a0"), 15.0, true)
	draw_polyline(stream, Color("#a5d0b3"), 2.0, true)

func _draw_top_bar() -> void:
	draw_rect(Rect2(0, 0, 1440, 66), Color("#18231c"))
	draw_string(ThemeDB.fallback_font, Vector2(22, 27), "WORLDFRONT", HORIZONTAL_ALIGNMENT_LEFT, -1, 22, Color.WHITE)
	draw_string(ThemeDB.fallback_font, Vector2(22, 49), "EARLY SETTLEMENTS  /  GATHER • CARRY • REST", HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color("#c4d4c6"))
	draw_string(ThemeDB.fallback_font, Vector2(480, 28), "RED  |  Wood: %d   Stone: %d" % [stock["red"]["wood"], stock["red"]["stone"]], HORIZONTAL_ALIGNMENT_LEFT, -1, 17, RED)
	draw_string(ThemeDB.fallback_font, Vector2(900, 28), "BLUE  |  Wood: %d   Stone: %d" % [stock["blue"]["wood"], stock["blue"]["stone"]], HORIZONTAL_ALIGNMENT_LEFT, -1, 17, BLUE)

func _draw_capital(team: String) -> void:
	var pos: Vector2 = capitals[team]
	var color: Color = RED if team == "red" else BLUE
	draw_circle(pos + Vector2(0, 7), 52.0, Color(0, 0, 0, 0.20))
	draw_circle(pos, 48.0, Color("#e6d9b8"))
	draw_circle(pos, 40.0, color.darkened(0.22))
	draw_rect(Rect2(pos + Vector2(-19, -18), Vector2(38, 34)), Color("#eee1c1"))
	draw_rect(Rect2(pos + Vector2(-12, -10), Vector2(24, 26)), color.darkened(0.18))
	draw_colored_polygon(PackedVector2Array([pos + Vector2(-29, -14), pos + Vector2(0, -39), pos + Vector2(29, -14)]), Color("#eee1c1"))
	draw_rect(Rect2(pos + Vector2(-4, 4), Vector2(8, 12)), color.darkened(0.28))
	draw_string(ThemeDB.fallback_font, pos + Vector2(-48, 67), team.to_upper() + " CAPITAL", HORIZONTAL_ALIGNMENT_CENTER, 96, 13, color)

func _draw_resources() -> void:
	for resource in resources:
		var pos: Vector2 = resource["pos"]
		if resource["kind"] == "tree":
			# Pixel-ish pine with layered blocky foliage.
			draw_rect(Rect2(pos + Vector2(-6, 3), Vector2(12, 27)), Color("#68452c"))
			draw_rect(Rect2(pos + Vector2(-3, 6), Vector2(5, 22)), Color("#8d633d"))
			draw_colored_polygon(PackedVector2Array([pos + Vector2(0, -42), pos + Vector2(-25, -7), pos + Vector2(25, -7)]), Color("#28583a"))
			draw_colored_polygon(PackedVector2Array([pos + Vector2(0, -28), pos + Vector2(-31, 7), pos + Vector2(31, 7)]), Color("#347247"))
			draw_colored_polygon(PackedVector2Array([pos + Vector2(0, -14), pos + Vector2(-34, 18), pos + Vector2(34, 18)]), Color("#3e824b"))
			draw_rect(Rect2(pos + Vector2(-5, -20), Vector2(5, 20)), Color("#5b9650"))
		else:
			var points := PackedVector2Array([
				pos + Vector2(-23, 11), pos + Vector2(-19, -8), pos + Vector2(-5, -20),
				pos + Vector2(12, -16), pos + Vector2(25, 0), pos + Vector2(19, 15), pos + Vector2(-3, 20)
			])
			draw_colored_polygon(points, Color("#6f7b7c"))
			draw_colored_polygon(PackedVector2Array([pos + Vector2(-14, -5), pos + Vector2(-4, -16), pos + Vector2(8, -12), pos + Vector2(0, -2)]), Color("#aab4ad"))
			draw_line(pos + Vector2(-19, 10), pos + Vector2(17, 10), Color("#566466"), 2.0)
		if int(resource["amount"]) <= 0:
			draw_circle(pos, 24, Color(0, 0, 0, 0.18))

func _pixel(pos: Vector2, x: float, y: float, w: float, h: float, color: Color) -> void:
	draw_rect(Rect2(pos + Vector2(x, y), Vector2(w, h)), color)

func _draw_civilians() -> void:
	for person in civilians:
		var pos: Vector2 = person["pos"]
		var team_color: Color = RED if person["team"] == "red" else BLUE
		var state: String = person["state"]
		var phase: float = float(person["phase"])
		var style: int = int(person["style"])
		var face: float = float(person["facing"])
		var moving := state == "return" or state == "gather" or state == "wander"
		var carrying: bool = person["carry"] != ""
		var tired := float(person["stamina"]) < 30.0
		var bob := 0.0
		var leg_a := 0.0
		var leg_b := 0.0
		var arm_a := 0.0
		var arm_b := 0.0
		if moving:
			match style:
				0: # long, steady stride
					leg_a = roundf(sin(phase) * 5.0)
					leg_b = roundf(sin(phase + PI) * 5.0)
					arm_a = -leg_a * 0.65
					arm_b = -leg_b * 0.65
				1: # short shuffling steps
					leg_a = roundf(sin(phase * 1.5) * 2.0)
					leg_b = roundf(sin(phase * 1.5 + PI) * 2.0)
					arm_a = roundf(sin(phase * 1.5) * 2.0)
					arm_b = -arm_a
				2: # bouncy jog
					bob = absf(sin(phase)) * 3.0
					leg_a = roundf(sin(phase) * 6.0)
					leg_b = roundf(sin(phase + PI) * 6.0)
					arm_a = -leg_a
					arm_b = -leg_b
				_: # relaxed uneven gait
					leg_a = roundf(sin(phase * 0.8) * 4.0)
					leg_b = roundf(sin(phase * 0.8 + PI) * 3.0)
					arm_a = roundf(sin(phase * 0.8 + PI) * 2.0)
					arm_b = roundf(sin(phase * 0.8) * 3.0)
		var lean := 2.0 if carrying else 0.0
		if tired and moving:
			lean += 2.0
		if state == "rest":
			# Sit on the ground with bent legs.
			_pixel(pos, -8, 5, 8, 5, Color("#332d2b"))
			_pixel(pos, 1, 5, 8, 5, Color("#332d2b"))
			_pixel(pos, -8, -3, 16, 11, team_color.darkened(0.12))
			_pixel(pos, -5, -13, 10, 10, SKIN)
			_pixel(pos, -7, -16, 14, 5, Color("#4a3025"))
			_pixel(pos, -3, -10, 2, 2, Color("#302c2b"))
			_pixel(pos, 3, -10, 2, 2, Color("#302c2b"))
			if tired:
				_pixel(pos, 9, -18, 3, 3, Color("#bde8f5"))
		else:
			# Shadow and pixel-art legs.
			_pixel(pos, -10, 10 + bob, 20, 4, Color(0, 0, 0, 0.18))
			var leg_color := Color("#3d3b3a")
			_pixel(pos, -7 + leg_a, 5 + bob, 6, 10, leg_color)
			_pixel(pos, -7 + leg_a, 13 + bob, 8, 3, Color("#282b2b"))
			_pixel(pos, 1 + leg_b, 5 + bob, 6, 10, leg_color)
			_pixel(pos, 1 + leg_b, 13 + bob, 8, 3, Color("#282b2b"))
			# Arms: carrying villagers hold their load close and lean forward.
			_pixel(pos, -10 - lean, -5 + bob + arm_a * 0.35, 5, 12, SKIN)
			_pixel(pos, 5 - lean, -5 + bob + arm_b * 0.35, 5, 12, SKIN)
			_pixel(pos, -9 - lean, -7 + bob, 18, 15, team_color.darkened(0.10))
			_pixel(pos, -6 - lean, -5 + bob, 4, 9, team_color.lightened(0.16))
			# Different hair/skin details make the workers less identical.
			var skin := SKIN if style != 3 else Color("#a96f4e")
			_pixel(pos, -6 - lean, -19 + bob, 12, 12, skin)
			var hair := Color("#493326") if style != 2 else Color("#6c4930")
			_pixel(pos, -7 - lean, -22 + bob, 14, 5, hair)
			_pixel(pos, -7 - lean, -18 + bob, 3, 4, hair)
			_pixel(pos, -3 - lean, -15 + bob, 2, 2, Color("#302b27"))
			_pixel(pos, 3 - lean, -15 + bob, 2, 2, Color("#302b27"))
			# Tiny belt and tunic trim.
			_pixel(pos, -8 - lean, 3 + bob, 16, 2, Color("#d3b87a"))
			if carrying:
				var bundle_color := Color("#9a693e") if person["carry"] == "wood" else Color("#9ca7a6")
				_pixel(pos, 4 - lean, -10 + bob, 10, 9, bundle_color)
				_pixel(pos, 5 - lean, -12 + bob, 7, 2, bundle_color.lightened(0.2))
				if int(person["load"]) == 2:
					_pixel(pos, 13 - lean, -6 + bob, 3, 3, Color("#bde8f5"))
			elif tired:
				_pixel(pos, 10, -21 + bob, 3, 3, Color("#bde8f5"))
		# Small stamina bar only appears when a worker is worn out.
		if float(person["stamina"]) < 35.0:
			draw_rect(Rect2(pos + Vector2(-10, -31), Vector2(20, 3)), Color("#3b3b35"))
			draw_rect(Rect2(pos + Vector2(-10, -31), Vector2(20.0 * float(person["stamina"]) / 100.0, 3)), Color("#e5c45f"))
