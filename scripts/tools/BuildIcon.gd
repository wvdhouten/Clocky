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

	var args := OS.get_cmdline_user_args()
	if args.size() > 0:
		_preview(images, args[0])
	quit()


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
