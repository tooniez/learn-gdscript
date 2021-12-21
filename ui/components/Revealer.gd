tool
class_name Revealer, "./Revealer.svg"
extends Container

# Duration of the tween animation in seconds.
const ANIM_DURATION := 0.1

const FONTS := {
	normal = preload("../theme/fonts/font_title.tres"),
	small = preload("../theme/fonts/font_title_small.tres"),
}

export var title := "Expand" setget set_title
export var is_expanded := false setget set_is_expanded
export var revealer_height := 32.0 setget set_revealer_height
export var chevron_size := 16.0
export var padding := 24.0
export var first_margin := 5.0
export var children_margin := 2.0
export var use_small_font := false setget set_use_small_font
export var text_color: Color setget set_text_color

var _height := 0.0
# List of nodes living in the revealer.
var _contents := []
onready var _parent := get_parent() as Control

onready var _button: Button = $Button
onready var _chevron: TextureRect = $Button/Chevron
onready var _tween: Tween = $Tween


func _ready() -> void:
	_button.pressed = is_expanded
	_button.connect("toggled", self, "set_is_expanded")
	for child in get_children():
		if child == _button or not child is Control:
			continue
		_contents.append(child)
	# Through the constructor setter call, the _contents variable will be empty,
	# so we need to call this again.
	set_is_expanded(is_expanded)


func _notification(what: int) -> void:
	if what == NOTIFICATION_SORT_CHILDREN:
		sort_children()


func add_child(node: Node, _legible_unique_name := false) -> void:
	.add_child(node)
	_contents.append(node)
	set_is_expanded(is_expanded)
	update_min_size()


func clear_contents() -> void:
	for node in _contents:
		node.queue_free()


func get_contents() -> Array:
	return _contents


func set_is_expanded(new_is_expanded: bool) -> void:
	is_expanded = new_is_expanded

	if not is_inside_tree():
		yield(self, "ready")

	if is_expanded:
		_rotate_chevron(90.0)
	else:
		_rotate_chevron(0.0)

	for node in _contents:
		node.visible = is_expanded


func set_title(new_title: String) -> void:
	title = new_title
	if not is_inside_tree():
		yield(self, "ready")
	_button.text = new_title


func set_revealer_height(new_revealer_height: float) -> void:
	revealer_height = new_revealer_height
	if not is_inside_tree():
		if not is_connected("ready", self, "update_min_size"):
			connect("ready", self, "update_min_size")
	else:
		update_min_size()


func update_min_size() -> void:
	if not is_instance_valid(_parent) or _parent == null:
		return
	var rect_size_x := min(rect_size.x, _parent.rect_size.x)
	_button.rect_size.x = rect_size_x
	if _tween.is_inside_tree():
		_tween.stop(self, "rect_min_size:y")
		_tween.interpolate_property(
			self, "rect_min_size:y", rect_min_size.y, _height, ANIM_DURATION
		)


func sort_children() -> void:
	var top := _button.rect_size.y
	var index := 0
	for node in _contents:
		if not node.visible:
			continue
		var margin := first_margin if index == 0 else children_margin
		top = _fit_child(node, top + margin, padding)
		index += 1
	_height = top
	update_min_size()


func set_use_small_font(value: bool) -> void:
	use_small_font = value
	if not is_inside_tree():
		yield(self, "ready")
	_button.add_font_override("font", FONTS.small if use_small_font else FONTS.normal)


func set_text_color(value: Color) -> void:
	text_color = value
	if not is_inside_tree():
		if not is_connected("ready", self, "update_min_size"):
			connect("ready", _button, "add_color_override", ["font_color", text_color])
	else:
		_button.add_color_override("font_color", text_color)


func _rotate_chevron(rotation_degrees: float, time := ANIM_DURATION) -> void:
	if not _tween.is_inside_tree():
		_chevron.rect_rotation = rotation_degrees
		return
	_tween.stop_all()
	_tween.interpolate_property(
		_chevron, "rect_rotation", _chevron.rect_rotation, rotation_degrees, time
	)
	_tween.start()


func _fit_child(control: Control, top := 0.0, node_padding := 0.0) -> float:
	var position := Vector2(node_padding, top)
	var height := control.rect_size.y
	var size := Vector2(rect_size.x - node_padding, height)
	var rect := Rect2(position, size)
	fit_child_in_rect(control, rect)
	control.rect_size.x = size.x
	return top + height
