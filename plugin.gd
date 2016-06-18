tool
extends EditorPlugin

var AutoTileLayer = load("res://addons/autotile/layer.gd")
var icon = load("res://addons/autotile/icon.png")
var current
var current_undo = {}
var editing = false

func _enter_tree():
	add_custom_type("AutoTileLayer", "StaticBody2D", AutoTileLayer, icon)

func _exit_tree():
	remove_custom_type("AutoTileLayer")

func _on_editor_start():
	current_undo = {}
	for pos in current.data:
		current_undo[pos] = 0

func _on_editor_finish():
	var current_do = {}
	for pos in current.data:
		current_do[pos] = 0
	var undoredo = get_undo_redo()
	undoredo.create_action("autotile_draw")
	undoredo.add_undo_method(current, "_set_data", current_undo)
	undoredo.add_do_method(current, "_set_data", current_do)
	undoredo.commit_action()

func handles(object):
	if object extends AutoTileLayer:
		return true

func forward_input_event(event):
	if current != null:
		return current._editor_input(event)

func edit(object):
	current = object
	current.editor_enabled = true
	current.connect("editor_start", self, "_on_editor_start")
	current.connect("editor_finish", self, "_on_editor_finish")

func make_visible(visible):
	if visible == false and current != null:
		current.editor_enabled = false
		current.disconnect("editor_start", self, "_on_editor_start")
		current.disconnect("editor_finish", self, "_on_editor_finish")
		current.update()
		current = null
