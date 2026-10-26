extends Node2D

# Worldfront - stable, self-contained Godot 4 prototype.
const W: int = 1440
const H: int = 900
const RED: Color = Color("#d94a48")
const BLUE: Color = Color("#4388e8")
var font: Font

var red_wood: int = 0
var red_stone: int = 0
var blue_wood: int = 0
var blue_stone: int = 0
var elapsed: float = 0.0
var workers: Array[Dictionary] = []
var trees: Array[Vector2] = [
    Vector2(320, 230), Vector2(430, 680), Vector2(550, 360),
    Vector2(730, 580), Vector2(900, 230), Vector2(1080, 680), Vector2(1170, 350)
]
var rocks: Array[Vector2] = [
    Vector2(285, 630), Vector2(610, 690), Vector2(800, 300), Vector2(1015, 510)
]

func _ready() -> void:
    font = ThemeDB.fallback_font
    randomize()
    for team in ["red", "blue"]:
        for i in range(7):
            var home: Vector2 = Vector2(135, 465) if team == "red" else Vector2(1305, 465)
            workers.append({
                "team": team,
                "pos": home + Vector2(randf_range(-25.0, 25.0), randf_range(-45.0, 45.0)),
                "target": Vector2.ZERO,
                "carrying": false,
                "kind": "wood",
                "wait": randf_range(0.0, 1.5),
                "phase": randf_range(0.0, TAU),
                "stamina": randf_range(65.0, 100.0),
                "style": i % 4,
                "resting": false
            })
    queue_redraw()

func _process(delta: float) -> void:
    elapsed += delta
    for worker in workers:
        update_worker(worker, delta)
    queue_redraw()

func update_worker(worker: Dictionary, delta: float) -> void:
    var team: String = str(worker["team"])
    var pos: Vector2 = worker["pos"]
    var home: Vector2 = Vector2(135, 465) if team == "red" else Vector2(1305, 465)
    worker["phase"] = float(worker["phase"]) + delta * 7.0
    if float(worker["wait"]) > 0.0:
        worker["wait"] = float(worker["wait"]) - delta
        if bool(worker["resting"]):
            worker["stamina"] = minf(100.0, float(worker["stamina"]) + delta * 18.0)
        if float(worker["wait"]) <= 0.0:
            worker["resting"] = false
        return

    if float(worker["stamina"]) < 12.0 and not bool(worker["resting"]):
        worker["resting"] = true
        worker["wait"] = 3.5
        return

    if bool(worker["carrying"]):
        if pos.distance_to(home) < 30.0:
            if str(worker["kind"]) == "wood":
                if team == "red":
                    red_wood += 1
                else:
                    blue_wood += 1
            else:
                if team == "red":
                    red_stone += 1
                else:
                    blue_stone += 1
            worker["carrying"] = false
            worker["stamina"] = maxf(0.0, float(worker["stamina"]) - 4.0)
            worker["wait"] = 0.6
            return
        var speed_home: float = 42.0 if str(worker["kind"]) == "stone" else 51.0
        worker["pos"] = pos.move_toward(home, speed_home * delta)
        worker["stamina"] = maxf(0.0, float(worker["stamina"]) - delta * 5.0)
        return

    var target: Vector2 = worker["target"]
    if target == Vector2.ZERO or pos.distance_to(target) < 25.0:
        var options: Array[Vector2] = trees if randf() < 0.68 else rocks
        target = options[randi_range(0, options.size() - 1)]
        worker["target"] = target
        worker["kind"] = "wood" if options == trees else "stone"
    var speed: float = [48.0, 43.0, 65.0, 46.0][int(worker["style"])]
    worker["pos"] = pos.move_toward(target, speed * delta)
    worker["stamina"] = maxf(0.0, float(worker["stamina"]) - delta * 2.0)
    if pos.distance_to(target) < 25.0:
        worker["carrying"] = true
        worker["wait"] = 0.8
        worker["stamina"] = maxf(0.0, float(worker["stamina"]) - 5.0)

func _draw() -> void:
    draw_rect(Rect2(0, 0, W, H), Color("#26352a"))
    draw_rect(Rect2(36, 78, 1368, 786), Color("#789f5d"))
    draw_terrain()
    draw_paths()
    draw_rect(Rect2(36, 78, 1368, 786), Color("#d0c9a9"), false, 4.0)
    draw_rect(Rect2(0, 0, W, 62), Color("#18231c"))
    draw_string(font, Vector2(22, 28), "WORLDFRONT", HORIZONTAL_ALIGNMENT_LEFT, -1, 23, Color.WHITE)
    draw_string(font, Vector2(22, 49), "EARLY SETTLEMENTS  /  GATHER • CARRY • REST", HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color("#c4d4c6"))
    draw_string(font, Vector2(470, 31), "RED   Wood: %d   Stone: %d" % [red_wood, red_stone], HORIZONTAL_ALIGNMENT_LEFT, -1, 17, RED)
    draw_string(font, Vector2(900, 31), "BLUE   Wood: %d   Stone: %d" % [blue_wood, blue_stone], HORIZONTAL_ALIGNMENT_LEFT, -1, 17, BLUE)
    draw_resources()
    draw_capital(Vector2(135, 465), RED, "RED CAPITAL")
    draw_capital(Vector2(1305, 465), BLUE, "BLUE CAPITAL")
    draw_workers()

func draw_terrain() -> void:
    for i in range(100):
        var x: float = 52.0 + float((i * 173 + 41) % 1330)
        var y: float = 95.0 + float((i * 97 + 19) % 745)
        var c: Color = Color("#91c477") if i % 2 == 0 else Color("#638f50")
        draw_circle(Vector2(x, y), 10.0 + float(i % 20), Color(c.r, c.g, c.b, 0.28))
    for i in range(190):
        var x: float = 48.0 + float((i * 67 + 23) % 1340)
        var y: float = 90.0 + float((i * 131 + 11) % 755)
        draw_line(Vector2(x, y), Vector2(x + 2.0, y - 4.0 - float(i % 4)), Color("#426c3d"), 1.4)
        if i % 13 == 0:
            draw_circle(Vector2(x + 5.0, y - 2.0), 2.0, Color("#e7d98b"))

func draw_paths() -> void:
    var left_path: PackedVector2Array = PackedVector2Array([Vector2(135, 490), Vector2(160, 560), Vector2(370, 570), Vector2(720, 590)])
    var right_path: PackedVector2Array = PackedVector2Array([Vector2(1305, 490), Vector2(1270, 560), Vector2(1050, 570), Vector2(720, 590)])
    draw_polyline(left_path, Color("#987a50"), 18.0, true)
    draw_polyline(left_path, Color("#b59a6d"), 10.0, true)
    draw_polyline(right_path, Color("#987a50"), 18.0, true)
    draw_polyline(right_path, Color("#b59a6d"), 10.0, true)
    var stream: PackedVector2Array = PackedVector2Array([
        Vector2(690, 90), Vector2(665, 180), Vector2(700, 260), Vector2(670, 345),
        Vector2(705, 430), Vector2(680, 520), Vector2(720, 620), Vector2(700, 780), Vector2(735, 855)
    ])
    draw_polyline(stream, Color("#4e886e"), 24.0, true)
    draw_polyline(stream, Color("#6ba8a0"), 14.0, true)

func draw_resources() -> void:
    for tree in trees:
        draw_rect(Rect2(tree + Vector2(-5, 2), Vector2(10, 25)), Color("#68452c"))
        draw_colored_polygon(PackedVector2Array([tree + Vector2(0, -40), tree + Vector2(-24, -5), tree + Vector2(24, -5)]), Color("#28583a"))
        draw_colored_polygon(PackedVector2Array([tree + Vector2(0, -25), tree + Vector2(-29, 10), tree + Vector2(29, 10)]), Color("#347247"))
        draw_colored_polygon(PackedVector2Array([tree + Vector2(0, -12), tree + Vector2(-31, 18), tree + Vector2(31, 18)]), Color("#3e824b"))
    for rock in rocks:
        var points: PackedVector2Array = PackedVector2Array([
            rock + Vector2(-22, 10), rock + Vector2(-18, -8), rock + Vector2(-4, -19),
            rock + Vector2(13, -14), rock + Vector2(24, 0), rock + Vector2(18, 14), rock + Vector2(-4, 18)
        ])
        draw_colored_polygon(points, Color("#6f7b7c"))
        draw_colored_polygon(PackedVector2Array([rock + Vector2(-13, -4), rock + Vector2(-4, -14), rock + Vector2(8, -10), rock + Vector2(0, -1)]), Color("#aab4ad"))

func draw_capital(pos: Vector2, color: Color, label: String) -> void:
    draw_circle(pos + Vector2(0, 7), 52.0, Color(0.0, 0.0, 0.0, 0.2))
    draw_circle(pos, 48.0, Color("#e6d9b8"))
    draw_circle(pos, 40.0, color.darkened(0.22))
    draw_rect(Rect2(pos + Vector2(-19, -18), Vector2(38, 34)), Color("#eee1c1"))
    draw_rect(Rect2(pos + Vector2(-12, -10), Vector2(24, 26)), color.darkened(0.18))
    draw_colored_polygon(PackedVector2Array([pos + Vector2(-29, -14), pos + Vector2(0, -39), pos + Vector2(29, -14)]), Color("#eee1c1"))
    draw_string(font, pos + Vector2(-48, 67), label, HORIZONTAL_ALIGNMENT_CENTER, 96, 13, color)

func draw_workers() -> void:
    for worker in workers:
        var pos: Vector2 = worker["pos"]
        var color: Color = RED if str(worker["team"]) == "red" else BLUE
        var phase: float = float(worker["phase"])
        var step: float = sin(phase * (1.0 + float(worker["style"]) * 0.12)) * 4.0
        var tired: bool = float(worker["stamina"]) < 30.0
        draw_rect(Rect2(pos + Vector2(-9, 10), Vector2(18, 4)), Color(0.0, 0.0, 0.0, 0.2))
        if bool(worker["resting"]):
            draw_rect(Rect2(pos + Vector2(-10, 4), Vector2(20, 7)), color.darkened(0.15))
            draw_rect(Rect2(pos + Vector2(-6, -9), Vector2(12, 12)), Color("#d9a47c"))
            draw_rect(Rect2(pos + Vector2(-7, -12), Vector2(14, 5)), Color("#493326"))
        else:
            draw_rect(Rect2(pos + Vector2(-7 + step, 5), Vector2(6, 10)), Color("#3d3b3a"))
            draw_rect(Rect2(pos + Vector2(1 - step, 5), Vector2(6, 10)), Color("#3d3b3a"))
            draw_rect(Rect2(pos + Vector2(-9, -7), Vector2(18, 15)), color.darkened(0.1))
            draw_rect(Rect2(pos + Vector2(-6, -19), Vector2(12, 12)), Color("#d9a47c") if int(worker["style"]) != 3 else Color("#a96f4e"))
            draw_rect(Rect2(pos + Vector2(-7, -22), Vector2(14, 5)), Color("#493326"))
            draw_rect(Rect2(pos + Vector2(-4, -15), Vector2(2, 2)), Color("#302b27"))
            draw_rect(Rect2(pos + Vector2(3, -15), Vector2(2, 2)), Color("#302b27"))
            if bool(worker["carrying"]):
                var bundle: Color = Color("#9a693e") if str(worker["kind"]) == "wood" else Color("#9ca7a6")
                draw_rect(Rect2(pos + Vector2(5, -9), Vector2(10, 9)), bundle)
        if tired:
            draw_rect(Rect2(pos + Vector2(-10, -30), Vector2(20, 3)), Color("#3b3b35"))
            draw_rect(Rect2(pos + Vector2(-10, -30), Vector2(20.0 * float(worker["stamina"]) / 100.0, 3)), Color("#e5c45f"))
