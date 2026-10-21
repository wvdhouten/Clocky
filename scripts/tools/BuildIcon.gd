extends SceneTree

## Renders res://icon.svg at every size Windows uses and packs them into
## assets/icon/clocky.ico (PNG-compressed ICO entries). Optionally writes
## an enlarged preview sheet for checking how it reads at small sizes.
##   godot --headless --path . --script res://scripts/tools/BuildIcon.gd -- [preview_dir]

const SIZES := [16, 24, 32, 48, 64, 128, 256]
const OUT_ICO := "res://assets/icon/clocky.ico"


func _init() -> void:
	var svg: String = FileAccess.get_file_as_string("res://icon.svg")
	var pngs: Array[PackedByteArray] = []
	var images: Array[Image] = []
	for s in SIZES:
		var img := Image.new()
		var err := img.load_svg_from_string(svg, float(s) / 256.0)
		if err != OK or img.get_width() != s:
			push_error("render failed at %d px (err %d, got %d)" % [s, err, img.get_width()])
			quit(1)
			return
		images.append(img)
		pngs.append(img.save_png_to_buffer())

	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT_ICO.get_base_dir()))
	var f := FileAccess.open(OUT_ICO, FileAccess.WRITE)
	f.store_16(0)  # reserved
	f.store_16(1)  # type: icon
	f.store_16(SIZES.size())
	var offset: int = 6 + 16 * SIZES.size()
	for i in SIZES.size():
		var s: int = SIZES[i]
		f.store_8(0 if s >= 256 else s)  # width (0 means 256)
		f.store_8(0 if s >= 256 else s)  # height
		f.store_8(0)   # palette colours
		f.store_8(0)   # reserved
		f.store_16(1)  # colour planes
		f.store_16(32) # bits per pixel
		f.store_32(pngs[i].size())
		f.store_32(offset)
		offset += pngs[i].size()
	for png in pngs:
		f.store_buffer(png)
	f.close()
	print("wrote %s (%d sizes)" % [OUT_ICO, SIZES.size()])
	_android_icons(svg)

	var args := OS.get_cmdline_user_args()
	if args.size() > 0:
		_preview(images, args[0])
	quit()


## Android launcher icons. Adaptive icons (Android 8+) are a 432px
## foreground over a 432px background, masked by the launcher to a circle,
## squircle, etc. Only the central ~61% is guaranteed visible, so the owl
## clock (which fills its whole square, ear tips in the corners) is drawn
## at 212px in the middle of a transparent foreground.
func _android_icons(svg: String) -> void:
	var dir := "res://assets/icon/android"
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(dir))

	var legacy := Image.new()
	legacy.load_svg_from_string(svg, 192.0 / 256.0)
	legacy.save_png(dir.path_join("icon_192.png"))

	var art := Image.new()
	art.load_svg_from_string(svg, 212.0 / 256.0)
	var fg := Image.create(432, 432, false, Image.FORMAT_RGBA8)
	fg.fill(Color(0, 0, 0, 0))
	fg.blend_rect(art, Rect2i(Vector2i.ZERO, art.get_size()), Vector2i((432 - 212) / 2, (432 - 212) / 2))
	fg.save_png(dir.path_join("adaptive_foreground_432.png"))

	# Sky-blue background, matching the app's sky.
	var bg := Image.create(432, 432, false, Image.FORMAT_RGBA8)
	for y in 432:
		bg.fill_rect(Rect2i(0, y, 432, 1), Color("79c6f6").lerp(Color("bfe6ff"), y / 431.0))
	bg.save_png(dir.path_join("adaptive_background_432.png"))
	print("wrote Android icons in ", dir)
	_adaptive_preview(fg, bg)


var _android_preview: Image


## How the adaptive icon looks under a circle mask (the strictest common
## launcher shape), kept for the preview sheet.
func _adaptive_preview(fg: Image, bg: Image) -> void:
	var out := Image.create(432, 432, false, Image.FORMAT_RGBA8)
	out.fill(Color(0, 0, 0, 0))
	# Launchers show the inner 72/108 of the canvas, then mask it.
	var view := Rect2i(72, 72, 288, 288)
	var composed: Image = bg.duplicate()
	composed.blend_rect(fg, Rect2i(0, 0, 432, 432), Vector2i.ZERO)
	var crop := composed.get_region(view)
	crop.resize(432, 432, Image.INTERPOLATE_BILINEAR)
	for y in 432:
		for x in 432:
			if Vector2(x - 215.5, y - 215.5).length() <= 216.0:
				out.set_pixel(x, y, crop.get_pixel(x, y))
	_android_preview = out


## Each size enlarged 4x with nearest-neighbour on a light and a dark strip,
## like it would look in Explorer / on the taskbar.
func _preview(images: Array[Image], dir: String) -> void:
	var pad := 16
	var w := pad
	for img in images:
		w += img.get_width() * 2 + pad
	var h: int = 256 * 2 * 2 + pad * 3
	var sheet := Image.create(w, h, false, Image.FORMAT_RGBA8)
	sheet.fill(Color("f3f3f3"))
	sheet.fill_rect(Rect2i(0, h / 2, w, h / 2), Color("202020"))
	var x := pad
	for img in images:
		var big: Image = img.duplicate()
		big.resize(img.get_width() * 2, img.get_height() * 2, Image.INTERPOLATE_NEAREST)
		for row in 2:
			var y: int = pad + row * (h / 2)
			sheet.blend_rect(big, Rect2i(Vector2i.ZERO, big.get_size()), Vector2i(x, y))
		x += big.get_width() + pad
	DirAccess.make_dir_recursive_absolute(dir)
	sheet.save_png(dir.path_join("icon_preview.png"))
	print("preview: ", dir.path_join("icon_preview.png"))
	if _android_preview:
		_android_preview.save_png(dir.path_join("android_adaptive_circle_preview.png"))
		print("preview: ", dir.path_join("android_adaptive_circle_preview.png"))
