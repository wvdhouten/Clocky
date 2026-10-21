extends RefCounted

## Draws country flags as textures in code. Windows has no flag emoji
## (regional-indicator pairs like 🇬🇧 render as the letters "GB"), so we
## paint our own. Rendered 4x and downscaled for smooth edges.

const UK_BLUE := Color("012169")
const UK_RED := Color("c8102e")
const NL_RED := Color("ae1c28")
const NL_BLUE := Color("21468b")
const RO_BLUE := Color("002b7f")
const RO_YELLOW := Color("fcd116")
const RO_RED := Color("ce1126")

static var _cache: Dictionary = {}


static func make(code: String, width: int = 48, height: int = 32) -> Texture2D:
	var key: String = "%s_%dx%d" % [code, width, height]
	if _cache.has(key):
		return _cache[key]
	var ss := 4
	var w: int = width * ss
	var h: int = height * ss
	var img := Image.create(w, h, false, Image.FORMAT_RGBA8)
	for y in h:
		for x in w:
			img.set_pixel(x, y, _pixel(code, x, y, w, h))
	img.resize(width, height, Image.INTERPOLATE_LANCZOS)
	_round_corners(img, height * 0.18)
	var tex := ImageTexture.create_from_image(img)
	_cache[key] = tex
	return tex


static func _pixel(code: String, x: int, y: int, w: int, h: int) -> Color:
	match code:
		"nl":
			if y < h / 3.0:
				return NL_RED
			return Color.WHITE if y < 2.0 * h / 3.0 else NL_BLUE
		"ro":
			if x < w / 3.0:
				return RO_BLUE
			return RO_YELLOW if x < 2.0 * w / 3.0 else RO_RED
		_:
			return _uk_pixel(float(x), float(y), float(w), float(h))


## Simplified Union Jack: white+red diagonals, then white+red cross.
static func _uk_pixel(x: float, y: float, w: float, h: float) -> Color:
	var diag_len: float = sqrt(w * w + h * h)
	var d1: float = abs(x * h - y * w) / diag_len
	var d2: float = abs(x * h + y * w - w * h) / diag_len
	var dc: float = min(abs(y - h / 2.0), abs(x - w / 2.0))
	if dc < h * 0.10:
		return UK_RED
	if dc < h * 0.17:
		return Color.WHITE
	var dd: float = min(d1, d2)
	if dd < h * 0.045:
		return UK_RED
	if dd < h * 0.12:
		return Color.WHITE
	return UK_BLUE


static func _round_corners(img: Image, radius: float) -> void:
	var w: int = img.get_width()
	var h: int = img.get_height()
	for y in h:
		for x in w:
			var cx: float = clamp(x + 0.5, radius, w - radius)
			var cy: float = clamp(y + 0.5, radius, h - radius)
			var d: float = Vector2(x + 0.5 - cx, y + 0.5 - cy).length()
			if d > radius - 1.0:
				var c: Color = img.get_pixel(x, y)
				c.a *= clamp(radius - d, 0.0, 1.0)
				img.set_pixel(x, y, c)
