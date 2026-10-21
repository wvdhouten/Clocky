extends Control

## Full-screen, click-through overlay for one-shot confetti bursts.
## burst() is fire-and-forget: each emitter frees itself when done.

var _confetti_texture: Texture2D
var _colors: Gradient


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	var img := Image.create(4, 2, false, Image.FORMAT_RGBA8)
	img.fill(Color.WHITE)
	_confetti_texture = ImageTexture.create_from_image(img)

	# Constant interpolation so each piece gets one crisp palette colour.
	_colors = Gradient.new()
	_colors.interpolation_mode = Gradient.GRADIENT_INTERPOLATE_CONSTANT
	_colors.offsets = PackedFloat32Array([0.0, 0.2, 0.4, 0.6, 0.8])
	_colors.colors = PackedColorArray([
		UiTheme.SUN, UiTheme.CORAL, UiTheme.LEAF, UiTheme.MINUTE_BLUE, Color("b388ff")])


func burst(at: Vector2, amount: int = 60, power: float = 1.0) -> void:
	var p := CPUParticles2D.new()
	p.position = at
	p.texture = _confetti_texture
	p.one_shot = true
	p.explosiveness = 0.95
	p.amount = amount
	p.lifetime = 1.8
	p.direction = Vector2(0, -1)
	p.spread = 70.0
	p.initial_velocity_min = 380.0 * power
	p.initial_velocity_max = 720.0 * power
	p.gravity = Vector2(0, 950)
	p.damping_min = 20.0
	p.damping_max = 60.0
	p.angle_min = 0.0
	p.angle_max = 360.0
	p.angular_velocity_min = -420.0
	p.angular_velocity_max = 420.0
	p.scale_amount_min = 2.2
	p.scale_amount_max = 3.6
	p.color_initial_ramp = _colors
	add_child(p)
	p.emitting = true
	p.finished.connect(p.queue_free)


## A bigger celebration: several bursts across the screen.
func shower() -> void:
	for i in 5:
		burst(Vector2(size.x * (0.1 + 0.2 * i), size.y * 0.75), 45, 1.25)
		await get_tree().create_timer(0.12).timeout
