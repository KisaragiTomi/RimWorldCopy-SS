class_name RWTheme

const BG_DARK := Color(0.16, 0.155, 0.14, 0.96)
const BG_MEDIUM := Color(0.22, 0.215, 0.20, 0.93)
const BG_LIGHT := Color(0.30, 0.29, 0.27, 0.90)
const BG_BUTTON := Color(0.25, 0.245, 0.23, 1.0)
const BG_BUTTON_HOVER := Color(0.33, 0.32, 0.28, 1.0)
const BG_BUTTON_PRESSED := Color(0.20, 0.19, 0.17, 1.0)

const BORDER_COLOR := Color(0.50, 0.48, 0.42, 0.85)
const BORDER_HIGHLIGHT := Color(0.85, 0.75, 0.3, 1.0)

const TEXT_WHITE := Color(0.93, 0.92, 0.88, 1.0)
const TEXT_GRAY := Color(0.68, 0.66, 0.60, 1.0)
const TEXT_DARK := Color(0.48, 0.46, 0.42, 1.0)
const TEXT_YELLOW := Color(0.96, 0.87, 0.32, 1.0)
const TEXT_RED := Color(0.9, 0.3, 0.3, 1.0)
const TEXT_GREEN := Color(0.3, 0.85, 0.3, 1.0)
const TEXT_BLUE := Color(0.4, 0.65, 0.95, 1.0)

const HIGHLIGHT_YELLOW := Color(0.85, 0.75, 0.3, 0.15)
const HIGHLIGHT_WHITE := Color(1.0, 1.0, 1.0, 0.08)
const SELECTION_COLOR := Color(0.3, 0.6, 0.3, 0.4)

const MOOD_HAPPY := Color(0.3, 0.75, 0.3, 1.0)
const MOOD_CONTENT := Color(0.55, 0.7, 0.3, 1.0)
const MOOD_NEUTRAL := Color(0.7, 0.7, 0.3, 1.0)
const MOOD_SAD := Color(0.8, 0.5, 0.2, 1.0)
const MOOD_BROKEN := Color(0.8, 0.25, 0.25, 1.0)

const BAR_HEALTH := Color(0.35, 0.72, 0.35, 1.0)
const BAR_FOOD := Color(0.22, 0.62, 0.22, 1.0)
const BAR_REST := Color(0.3, 0.5, 0.82, 1.0)
const BAR_JOY := Color(0.82, 0.72, 0.22, 1.0)
const BAR_RESEARCH := Color(0.3, 0.62, 0.82, 1.0)

const FONT_TINY := 11
const FONT_SMALL := 13
const FONT_MEDIUM := 17
const FONT_LARGE := 22

const MARGIN_WINDOW := 16
const MARGIN_ELEMENT := 4
const SPACING_LIST := 2
const BORDER_WIDTH := 1

const SPEED_PAUSED := 0
const SPEED_NORMAL := 1
const SPEED_FAST := 2
const SPEED_SUPERFAST := 3

const BUTTON_BG_PATH := "res://assets/textures/ui/ButtonBG.png"
const BUTTON_BG_HOVER_PATH := "res://assets/textures/ui/ButtonBGMouseover.png"
const BUTTON_BG_CLICK_PATH := "res://assets/textures/ui/ButtonBGClick.png"

static var _btn_bg_tex: Texture2D
static var _btn_hover_tex: Texture2D
static var _btn_click_tex: Texture2D
static var _textures_loaded := false

static func _ensure_textures() -> void:
	if _textures_loaded:
		return
	_textures_loaded = true
	if ResourceLoader.exists(BUTTON_BG_PATH):
		_btn_bg_tex = load(BUTTON_BG_PATH)
	if ResourceLoader.exists(BUTTON_BG_HOVER_PATH):
		_btn_hover_tex = load(BUTTON_BG_HOVER_PATH)
	if ResourceLoader.exists(BUTTON_BG_CLICK_PATH):
		_btn_click_tex = load(BUTTON_BG_CLICK_PATH)


static func make_texture_button_normal() -> StyleBox:
	_ensure_textures()
	if _btn_bg_tex:
		var sb := StyleBoxTexture.new()
		sb.texture = _btn_bg_tex
		sb.texture_margin_left = 6.0
		sb.texture_margin_top = 6.0
		sb.texture_margin_right = 6.0
		sb.texture_margin_bottom = 6.0
		sb.content_margin_left = 8.0
		sb.content_margin_top = 4.0
		sb.content_margin_right = 8.0
		sb.content_margin_bottom = 4.0
		return sb
	return make_button_normal()


static func make_texture_button_hover() -> StyleBox:
	_ensure_textures()
	if _btn_hover_tex:
		var sb := StyleBoxTexture.new()
		sb.texture = _btn_hover_tex
		sb.texture_margin_left = 6.0
		sb.texture_margin_top = 6.0
		sb.texture_margin_right = 6.0
		sb.texture_margin_bottom = 6.0
		sb.content_margin_left = 8.0
		sb.content_margin_top = 4.0
		sb.content_margin_right = 8.0
		sb.content_margin_bottom = 4.0
		return sb
	return make_button_hover()


static func make_texture_button_pressed() -> StyleBox:
	_ensure_textures()
	if _btn_click_tex:
		var sb := StyleBoxTexture.new()
		sb.texture = _btn_click_tex
		sb.texture_margin_left = 6.0
		sb.texture_margin_top = 6.0
		sb.texture_margin_right = 6.0
		sb.texture_margin_bottom = 6.0
		sb.content_margin_left = 8.0
		sb.content_margin_top = 4.0
		sb.content_margin_right = 8.0
		sb.content_margin_bottom = 4.0
		return sb
	return make_button_pressed()


static func make_stylebox_flat(bg: Color, border: Color = Color.TRANSPARENT, border_w: int = 0, corner: int = 0) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = bg
	sb.border_color = border
	sb.border_width_left = border_w
	sb.border_width_top = border_w
	sb.border_width_right = border_w
	sb.border_width_bottom = border_w
	sb.corner_radius_top_left = corner
	sb.corner_radius_top_right = corner
	sb.corner_radius_bottom_left = corner
	sb.corner_radius_bottom_right = corner
	sb.content_margin_left = 8.0
	sb.content_margin_top = 4.0
	sb.content_margin_right = 8.0
	sb.content_margin_bottom = 4.0
	return sb


static func make_window_panel() -> StyleBoxFlat:
	return make_stylebox_flat(BG_DARK, BORDER_COLOR, BORDER_WIDTH)


static func make_button_normal() -> StyleBoxFlat:
	return make_stylebox_flat(BG_BUTTON, BORDER_COLOR, BORDER_WIDTH)


static func make_button_hover() -> StyleBoxFlat:
	return make_stylebox_flat(BG_BUTTON_HOVER, BORDER_HIGHLIGHT, BORDER_WIDTH)


static func make_button_pressed() -> StyleBoxFlat:
	return make_stylebox_flat(BG_BUTTON_PRESSED, BORDER_COLOR, BORDER_WIDTH)
