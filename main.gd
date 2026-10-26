extends Node2D

# Worldfront prototype: two capitals, tiny civilians, and automatic gathering.
const MAP_RECT := Rect2(36, 72, 1028, 590)
const RED := Color("#e84b4b")
const BLUE := Color("#4389f5")
const LAND := Color("#7bbd67")
const DARK_LAND := Color("#68a957")
const WOOD := Color("#8a5a35")
const LEAF := Color("#287a43")
const STONE := Color("#929ca5")

var capitals := {
	"red": Vector2(125, 365),
	"blue": Vector2(975, 365)
}
var stock := {
	"red": {"wood": 0, "stone": 0},
	"blue": {"wood": 0, "stone": 0}
}
var civilians: Array[Dictionary] = []
var resources: Array[Dictionary] = []
var elapsed := 0.0

func _ready() -> void:
	_make_resources()
	_make_civilians()
	queue_redraw()

func _make_resources() -> void:
	resources = [
		{"kind": "tree", "pos": Vector2(300, 185), "amount": 80},
		{"kind": "tree", "pos": Vector2(385, 475), "amount": 80},
		{"kind": "tree", "pos": Vector2(520, 300), "amount": 80},
		{"kind": "tree", "pos": Vector2(720, 500), "amount": 80},
		{"kind": "tree", "pos": Vector2(805, 180), "amount": 80},
		{"kind": "rock", "pos": Vector2(275, 505), "amount": 80},
		{"kind": "rock", "pos": Vector2(565, 485), "amount": 80},
		{"kind": "rock", "pos": Vector2(760, 300), "amount": 80}
	]

func _make_civilians() -> void:
	for team in ["red", "blue"]:
		for i in range(5):
			var offset := Vector2(randf_range(-25.0, 25.0), randf_range(-40.0, 40.0))
			civilians.append({
				"team": team,
				"pos": capitals[team] + offset,
				"state": "gather",
				"target": -1,
				"carry": "",
				"wait": randf_range(0.0, 1.0),
				"wander": Vector2.ZERO
			})

func _process(delta: float) -> void:
	elapsed += delta
	for person in civilians:
		_update_civilian(person, delta)
	queue_redraw()

func _update_civilian(person: Dictionary, delta: float) -> void:
	var team: String = person["team"]
	var pos: Vector2 = person["pos"]

	if person["state"] == "return":
		var base: Vector2 = capitals[team]
		if pos.distance_to(base) < 25.0:
			if person["carry"] != "":
				stock[team][person["carry"]] += 1
			person["carry"] = ""
			person["state"] = "gather"
			person["target"] = -1
			person["wait"] = randf_range(0.15, 0.8)
		else:
			person["pos"] = pos.move_toward(base, 55.0 * delta)
		return

	if float(person["wait"]) > 0.0:
		person["wait"] = float(person["wait"]) - delta
		return

	var target_index: int = int(person["target"])
	if target_index < 0 or target_index >= resources.size() or int(resources[target_index]["amount"]) <= 0:
		target_index = _choose_resource(pos)
		person["target"] = target_index
		if target_index == -1:
			person["wander"] = capitals[team] + Vector2(randf_range(-80.0, 80.0), randf_range(-80.0, 80.0))
			person["state"] = "wander"
			return

	if person["state"] == "wander":
		var wander_target: Vector2 = person["wander"]
		if pos.distance_to(wander_target) < 8.0:
			person["state"] = "gather"
			person["wait"] = 0.3
		else:
			person["pos"] = pos.move_toward(wander_target, 28.0 * delta)
		return

	var target_pos: Vector2 = resources[target_index]["pos"]
	if pos.distance_to(target_pos) > 19.0:
		person["pos"] = pos.move_toward(target_pos, 43.0 * delta)
	else:
		person["wait"] = 1.2
		var kind: String = resources[target_index]["kind"]
		resources[target_index]["amount"] = int(resources[target_index]["amount"]) - 1
		person["carry"] = "wood" if kind == "tree" else "stone"
		person["state"] = "return"

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
	draw_rect(Rect2(Vector2.ZERO, Vector2(1100, 700)), Color("#243c2a"))
	draw_rect(MAP_RECT, LAND)
	for i in range(18):
		var x := 65.0 + float((i * 137) % 950)
		var y := 95.0 + float((i * 83) % 535)
		draw_circle(Vector2(x, y), 34.0, Color(DARK_LAND, 0.16))
	draw_rect(MAP_RECT, Color("#d4d9c2"), false, 4.0)

	_draw_top_bar()
	_draw_resources()
	_draw_capital("red")
	_draw_capital("blue")
	_draw_civilians()

func _draw_top_bar() -> void:
	draw_rect(Rect2(0, 0, 1100, 58), Color("#18231c"))
	draw_string(ThemeDB.fallback_font, Vector2(22, 25), "WORLDFRONT", HORIZONTAL_ALIGNMENT_LEFT, -1, 20, Color.WHITE)
	draw_string(ThemeDB.fallback_font, Vector2(22, 45), "Tiny world prototype  •  civilians gather automatically", HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color("#c4d4c6"))
	draw_string(ThemeDB.fallback_font, Vector2(500, 25), "RED  |  Wood: %d   Stone: %d" % [stock["red"]["wood"], stock["red"]["stone"]], HORIZONTAL_ALIGNMENT_LEFT, -1, 15, RED)
	draw_string(ThemeDB.fallback_font, Vector2(790, 25), "BLUE  |  Wood: %d   Stone: %d" % [stock["blue"]["wood"], stock["blue"]["stone"]], HORIZONTAL_ALIGNMENT_LEFT, -1, 15, BLUE)

func _draw_capital(team: String) -> void:
	var pos: Vector2 = capitals[team]
	var color: Color = RED if team == "red" else BLUE
	draw_circle(pos + Vector2(0, 5), 40.0, Color(0, 0, 0, 0.2))
	draw_circle(pos, 37.0, Color("#f0e9d8"))
	draw_circle(pos, 31.0, color)
	draw_rect(Rect2(pos + Vector2(-15, -16), Vector2(30, 31)), Color("#f5e9d3"))
	draw_rect(Rect2(pos + Vector2(-10, -10), Vector2(20, 25)), color.darkened(0.18))
	draw_colored_polygon(PackedVector2Array([
		pos + Vector2(-23, -13), pos + Vector2(0, -31), pos + Vector2(23, -13)
	]), Color("#f5e9d3"))
	draw_string(ThemeDB.fallback_font, pos + Vector2(-42, 57), team.to_upper() + " CAPITAL", HORIZONTAL_ALIGNMENT_CENTER, 84, 12, color)

func _draw_resources() -> void:
	for resource in resources:
		var pos: Vector2 = resource["pos"]
		if resource["kind"] == "tree":
			draw_rect(Rect2(pos + Vector2(-4, 1), Vector2(8, 19)), WOOD)
			draw_circle(pos + Vector2(0, -7), 18, LEAF)
			draw_circle(pos + Vector2(-11, 0), 12, Color("#32894a"))
			draw_circle(pos + Vector2(10, 1), 12, Color("#32894a"))
		else:
			var points := PackedVector2Array([
				pos + Vector2(-17, 8), pos + Vector2(-12, -9), pos + Vector2(0, -17),
				pos + Vector2(15, -8), pos + Vector2(18, 7), pos + Vector2(5, 14)
			])
			var outline := points.duplicate()
			outline.append(points[0])
			draw_colored_polygon(points, STONE)
			draw_polyline(outline, Color("#6d7880"), 2.0)
		if int(resource["amount"]) <= 0:
			draw_circle(pos, 20, Color(0, 0, 0, 0.12))

func _draw_civilians() -> void:
	for person in civilians:
		var pos: Vector2 = person["pos"]
		var color: Color = RED if person["team"] == "red" else BLUE
		var bob := sin(elapsed * 8.0 + pos.x * 0.1) * 2.0
		draw_line(pos + Vector2(-4, 5), pos + Vector2(-7, 12 + bob), Color("#302c2b"), 2.5)
		draw_line(pos + Vector2(4, 5), pos + Vector2(7, 12 - bob), Color("#302c2b"), 2.5)
		draw_line(pos + Vector2(-8, -1), pos + Vector2(-14, 3 + bob), Color("#f3d0ad"), 2.5)
		draw_line(pos + Vector2(8, -1), pos + Vector2(14, 3 - bob), Color("#f3d0ad"), 2.5)
		draw_circle(pos + Vector2(-14, 3 + bob), 2.5, Color("#f3d0ad"))
		draw_circle(pos + Vector2(14, 3 - bob), 2.5, Color("#f3d0ad"))
		draw_circle(pos + Vector2(0, 1), 9.5, color)
		draw_circle(pos + Vector2(-3, -2), 1.5, Color.WHITE)
		draw_circle(pos + Vector2(3, -2), 1.5, Color.WHITE)
		if person["carry"] != "":
			draw_circle(pos + Vector2(0, -13), 4.0, WOOD if person["carry"] == "wood" else STONE)
