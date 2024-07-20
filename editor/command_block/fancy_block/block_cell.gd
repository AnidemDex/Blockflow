@tool
extends PanelContainer

var debug_style:StyleBox

var debug:bool = false:
	set(value):
		debug = value
		var i := randi_range(0, 15)
		debug_style = get_theme_stylebox("sub_inspector_bg"+str(i), "Editor")
		queue_redraw()

func _get_minimum_size() -> Vector2:
	return Vector2(16, 16)

func _notification(what):
	match what:
		NOTIFICATION_DRAW:
			if debug:
				draw_style_box(debug_style, Rect2(Vector2(), size))

func _init() -> void:
	name = "BlockCell"
