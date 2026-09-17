extends RefCounted

const BASE_TRAIL_DURATION: float = 6.0
const BASE_SAMPLE_DISTANCE: float = 12.0
const BASE_MIN_SEGMENT_AGE: float = 0.9
const BASE_MIN_PERIMETER: float = 280.0
const BASE_MIN_AREA: float = 20000.0
const BASE_SNAP_RADIUS: float = 40.0
const CLOSURE_COOLDOWN: float = 0.45
const FINISHER_VISUAL_TIME: float = 0.28
const MAX_POINTS: int = 420

var points: PackedVector2Array = PackedVector2Array()
var point_times: PackedFloat32Array = PackedFloat32Array()
var trail_duration: float = BASE_TRAIL_DURATION
var sample_distance: float = BASE_SAMPLE_DISTANCE
var min_segment_age: float = BASE_MIN_SEGMENT_AGE
var min_perimeter: float = BASE_MIN_PERIMETER
var min_area: float = BASE_MIN_AREA
var snap_radius: float = BASE_SNAP_RADIUS
var cooldown_left: float = 0.0
var visual_left: float = 0.0
var active_polygon: PackedVector2Array = PackedVector2Array()
var snap_point: Vector2 = Vector2.INF
var closures: int = 0

func reset(position: Vector2 = Vector2.ZERO, now: float = 0.0) -> void:
	points = PackedVector2Array([position])
	point_times = PackedFloat32Array([now])
	cooldown_left = 0.0
	visual_left = 0.0
	active_polygon = PackedVector2Array()
	snap_point = Vector2.INF

func configure(stats: Dictionary) -> void:
	trail_duration = clampf(BASE_TRAIL_DURATION + float(stats.get("trail_duration", 0.0)), BASE_TRAIL_DURATION, 9.0)
	snap_radius = clampf(BASE_SNAP_RADIUS + float(stats.get("snap_radius", 0.0)), BASE_SNAP_RADIUS, 60.0)

func advance(position: Vector2, now: float, delta: float, enemies: Array) -> Dictionary:
	cooldown_left = maxf(0.0, cooldown_left - delta)
	visual_left = maxf(0.0, visual_left - delta)
	if visual_left <= 0.0:
		active_polygon = PackedVector2Array()
	_expire_old_points(now)
	if points.is_empty():
		reset(position, now)
		return {}
	var previous: Vector2 = points[points.size() - 1]
	if previous.distance_to(position) < sample_distance:
		_update_snap_feedback(position, now)
		return {}
	var closure: Dictionary = _find_closure(previous, position, now) if cooldown_left <= 0.0 else {}
	if not closure.is_empty():
		var polygon: PackedVector2Array = closure.polygon
		active_polygon = polygon.duplicate()
		visual_left = FINISHER_VISUAL_TIME
		cooldown_left = CLOSURE_COOLDOWN
		closures += 1
		var targets: Array = select_targets(polygon, enemies)
		points = PackedVector2Array([position])
		point_times = PackedFloat32Array([now])
		snap_point = Vector2.INF
		return {"polygon": polygon, "targets": targets, "intersection": closure.intersection}
	points.append(position)
	point_times.append(now)
	while points.size() > MAX_POINTS:
		points.remove_at(0)
		point_times.remove_at(0)
	_update_snap_feedback(position, now)
	return {}

func _expire_old_points(now: float) -> void:
	while points.size() > 1 and now - point_times[0] > trail_duration:
		points.remove_at(0)
		point_times.remove_at(0)

func _find_closure(from: Vector2, to: Vector2, now: float) -> Dictionary:
	if points.size() < 4:
		return {}
	var best: Dictionary = {}
	var best_area: float = INF
	for index in range(points.size() - 2):
		if now - point_times[index + 1] < min_segment_age:
			continue
		var hit: Variant = Geometry2D.segment_intersects_segment(from, to, points[index], points[index + 1])
		if hit == null or not hit is Vector2:
			continue
		var polygon := PackedVector2Array([hit])
		for point_index in range(index + 1, points.size()):
			polygon.append(points[point_index])
		polygon.append(to)
		var area: float = polygon_area(polygon)
		if area < min_area or polygon_perimeter(polygon) < min_perimeter or area >= best_area:
			continue
		best_area = area
		best = {"polygon": polygon, "intersection": hit}
	return best

func _update_snap_feedback(position: Vector2, now: float) -> void:
	snap_point = Vector2.INF
	var best_distance: float = snap_radius
	for index in range(maxi(0, points.size() - 2)):
		if now - point_times[index + 1] < min_segment_age:
			continue
		var closest: Vector2 = Geometry2D.get_closest_point_to_segment(position, points[index], points[index + 1])
		var distance: float = closest.distance_to(position)
		if distance < best_distance:
			best_distance = distance
			snap_point = closest

func select_targets(polygon: PackedVector2Array, enemies: Array) -> Array:
	var result: Array = []
	if polygon.size() < 3:
		return result
	for enemy in enemies:
		if not is_instance_valid(enemy) or enemy.dead or enemy.spawn_protection > 0.0:
			continue
		if Geometry2D.is_point_in_polygon(enemy.position, polygon):
			result.append(enemy)
	return result

func polygon_area(polygon: PackedVector2Array) -> float:
	if polygon.size() < 3:
		return 0.0
	var twice_area: float = 0.0
	for index in range(polygon.size()):
		var next: int = (index + 1) % polygon.size()
		twice_area += polygon[index].x * polygon[next].y - polygon[next].x * polygon[index].y
	var area: float = absf(twice_area) * 0.5
	return area if is_finite(area) else 0.0

func polygon_perimeter(polygon: PackedVector2Array) -> float:
	if polygon.size() < 3:
		return 0.0
	var result: float = 0.0
	for index in range(polygon.size()):
		result += polygon[index].distance_to(polygon[(index + 1) % polygon.size()])
	return result if is_finite(result) else 0.0

func memory_ratio(now: float) -> float:
	if point_times.is_empty():
		return 0.0
	return clampf((now - point_times[0]) / trail_duration, 0.0, 1.0)

func draw(canvas: CanvasItem, reduced_effects: bool) -> void:
	if points.size() >= 2:
		canvas.draw_polyline(points, Color(0.28, 0.96, 0.88, 0.58), 4.0, not reduced_effects)
	if snap_point != Vector2.INF:
		var pulse: float = 10.0 if reduced_effects else 13.0 + sin(Time.get_ticks_msec() * 0.012) * 4.0
		canvas.draw_circle(snap_point, pulse, Color(0.72, 1.0, 0.94, 0.32), false, 3.0)
	if active_polygon.size() >= 3 and visual_left > 0.0:
		var alpha: float = visual_left / FINISHER_VISUAL_TIME
		var outline := active_polygon.duplicate()
		outline.append(active_polygon[0])
		canvas.draw_polyline(outline, Color(0.55, 1.0, 0.94, 0.9 * alpha), 7.0, not reduced_effects)
