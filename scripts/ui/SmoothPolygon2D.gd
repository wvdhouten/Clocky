extends Polygon2D

## Polygon2D with soft edges on the Compatibility (OpenGL) renderer, where
## neither 2D MSAA nor Polygon2D.antialiased has any effect. Antialiased
## lines DO work there, so we trace the outline with a thin antialiased
## polyline in the same colour, feathering the hard polygon edge.

## Outline width in screen pixels (converted to local units, since the
## node may be scaled).
@export var edge_px: float = 1.2


func _draw() -> void:
	if polygon.size() < 3:
		return
	var pts: PackedVector2Array = polygon.duplicate()
	pts.append(pts[0])
	var s: float = max(get_global_transform().get_scale().x, 0.001)
	draw_polyline(pts, color, edge_px / s, true)
