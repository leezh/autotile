tool
extends StaticBody2D

const MASK_TL = 1
const MASK_TOP = 2
const MASK_TR = 4
const MASK_LEFT = 8
const MASK_RIGHT = 16
const MASK_BL = 32
const MASK_BOTTOM = 64
const MASK_BR = 128

const MODE_GROUND = 0
const MODE_WALL = 1

export(Texture) var texture setget _set_texture
export(int, 2, 128) var tile_size = 32 setget _set_tile_size
export(Vector2) var region_offset = Vector2(0, 0) setget _set_region_offset
export(int, "RPG Maker Ground", "RPG Maker Wall") var mode = MODE_GROUND setget _set_mode
export(bool) var solid = false setget _set_solid
var data = {} setget _set_data
var data_cache = []
var data_modified = true
var editor_enabled = false
var editor_hover = Vector2(0, 0)
var editor_modified = false
var min_pos = Vector2(0, 0)
var max_pos = Vector2(0, 0)

func _get_property_list():
	return [{
		"hint": PROPERTY_HINT_NONE,
		"usage": PROPERTY_USAGE_STORAGE,
		"name": "autotile/data",
		"type": TYPE_INT_ARRAY
	}]

func _get(property):
	if property == "autotile/data":
		if data_modified:
			_regen_data()
		return data_cache

func _set(property, value):
	if property == "autotile/data":
		data.clear()
		var i = 0
		while i + 1 < value.size():
			data[Vector2(value[i], value[i + 1])] = 0
			i += 2
		_regen_data()
		return true

func _set_texture(value):
	texture = value
	update()

func _set_tile_size(value):
	tile_size = value
	_regen_data()

func _set_region_offset(value):
	region_offset = value
	update()

func _set_mode(value):
	mode = value
	update()

func _set_solid(value):
	solid = value
	_regen_data()

func _set_data(value):
	data = value
	_regen_data()

func _regen_data():
	var shape
	if solid:
		shape = RectangleShape2D.new()
		shape.set_extents(Vector2(0.5, 0.5) * tile_size)
	clear_shapes()
	data_cache.clear()
	min_pos = Vector2(0, 0)
	max_pos = Vector2(0, 0)
	for pos in data.keys():
		min_pos.x = min(min_pos.x, pos.x)
		min_pos.y = min(min_pos.x, pos.y)
		max_pos.x = max(max_pos.x, pos.x)
		max_pos.y = max(max_pos.x, pos.y)
		data_cache.append(int(pos.x))
		data_cache.append(int(pos.y))
		var mask = 0
		if data.has(pos + Vector2(-1, -1)):
			mask = mask | MASK_TL
		if data.has(pos + Vector2( 0, -1)):
			mask = mask | MASK_TOP
		if data.has(pos + Vector2( 1, -1)):
			mask = mask | MASK_TR
		if data.has(pos + Vector2(-1,  0)):
			mask = mask | MASK_LEFT
		if data.has(pos + Vector2( 1,  0)):
			mask = mask | MASK_RIGHT
		if data.has(pos + Vector2(-1,  1)):
			mask = mask | MASK_BL
		if data.has(pos + Vector2( 0,  1)):
			mask = mask | MASK_BOTTOM
		if data.has(pos + Vector2( 1,  1)):
			mask = mask | MASK_BR
		data[pos] = mask
		if solid:
			var ofs = (pos + Vector2(0.5, 0.5)) * tile_size
			add_shape(shape, Matrix32(0, ofs))
	data_modified = false
	update()

func _get_corner_tl(mask):
	var rect = Rect2(region_offset, Vector2(tile_size, tile_size) / 2)
	rect.pos += Vector2(0, 0)
	var concave = false
	if mask & MASK_LEFT and mask & MASK_TOP:
		if mask & MASK_TL:
			rect.pos.x += tile_size
			rect.pos.y += tile_size
		else:
			rect.pos.x += tile_size
			concave = true
	elif mask & MASK_LEFT:
		rect.pos.x += tile_size
	elif mask & MASK_TOP:
		rect.pos.y += tile_size
	else:
		pass
	if mode == MODE_GROUND and not concave:
		rect.pos.y += tile_size
	return rect

func _get_corner_tr(mask):
	var rect = Rect2(region_offset, Vector2(tile_size, tile_size) / 2)
	rect.pos += Vector2(tile_size / 2, 0)
	var concave = false
	if mask & MASK_RIGHT and mask & MASK_TOP:
		if mask & MASK_TR:
			rect.pos.y += tile_size
		else:
			rect.pos.x += tile_size
			concave = true
	elif mask & MASK_RIGHT:
		pass
	elif mask & MASK_TOP:
		rect.pos.x += tile_size
		rect.pos.y += tile_size
	else:
		rect.pos.x += tile_size
	if mode == MODE_GROUND and not concave:
		rect.pos.y += tile_size
	return rect

func _get_corner_bl(mask):
	var rect = Rect2(region_offset, Vector2(tile_size, tile_size) / 2)
	rect.pos += Vector2(0, tile_size / 2)
	var concave = false
	if mask & MASK_LEFT and mask & MASK_BOTTOM:
		if mask & MASK_BL:
			rect.pos.x += tile_size
		else:
			rect.pos.x += tile_size
			concave = true
	elif mask & MASK_LEFT:
		rect.pos.x += tile_size
		rect.pos.y += tile_size
	elif mask & MASK_BOTTOM:
		pass
	else:
		rect.pos.y += tile_size
	if mode == MODE_GROUND and not concave:
		rect.pos.y += tile_size
	return rect

func _get_corner_br(mask):
	var rect = Rect2(region_offset, Vector2(tile_size, tile_size) / 2)
	rect.pos += Vector2(tile_size / 2, tile_size / 2)
	var concave = false
	if mask & MASK_RIGHT and mask & MASK_BOTTOM:
		if mask & MASK_BR:
			pass
		else:
			rect.pos.x += tile_size
			concave = true
	elif mask & MASK_RIGHT:
		rect.pos.y += tile_size
	elif mask & MASK_BOTTOM:
		rect.pos.x += tile_size
	else:
		rect.pos.x += tile_size
		rect.pos.y += tile_size
	if mode == MODE_GROUND and not concave:
		rect.pos.y += tile_size
	return rect

func _draw():
	if data_modified:
		_regen_data()
	if texture != null:
		for pos in data.keys():
			var ofs = pos * tile_size
			var size = Vector2(0.5, 0.5) * tile_size
			var mask = data[pos]
			draw_texture_rect_region(texture, Rect2(ofs, size), _get_corner_tl(mask))
			ofs.x += size.x
			draw_texture_rect_region(texture, Rect2(ofs, size), _get_corner_tr(mask))
			ofs.y += size.y
			draw_texture_rect_region(texture, Rect2(ofs, size), _get_corner_br(mask))
			ofs.x -= size.x
			draw_texture_rect_region(texture, Rect2(ofs, size), _get_corner_bl(mask))
	if editor_enabled:
		var cursor = Rect2(editor_hover * tile_size, Vector2(1, 1) * tile_size)
		draw_rect(cursor, Color(1, 1, 1, 0.5))

func _init():
	add_user_signal("editor_start")
	add_user_signal("editor_finish")

func _editor_input(event):
	if event.type == InputEvent.MOUSE_MOTION or event.type == InputEvent.MOUSE_BUTTON:
		var pos = Vector2(event.x, event.y) - get_viewport_transform().get_origin()
		pos = pos / get_viewport_transform().get_scale() / tile_size
		var new_hover = Vector2(floor(pos.x), floor(pos.y))
		if editor_hover != new_hover:
			update()
		editor_hover = new_hover
		if event.button_mask & 1:
			if not has_tile(editor_hover):
				if not editor_modified:
					emit_signal("editor_start")
					editor_modified = true
				add_tile(editor_hover)
				data_modified = true
			return true
		elif event.button_mask & 2:
			if has_tile(editor_hover):
				if not editor_modified:
					emit_signal("editor_start")
					editor_modified = true
				remove_tile(editor_hover)
				data_modified = true
			return true
		elif editor_modified:
			editor_modified = false
			emit_signal("editor_finish")

func get_item_rect():
	return Rect2(min_pos, max_pos - min_pos)

func has_tile(pos):
	return data.has(pos)

func add_tile(pos):
	data[pos] = 0
	data_modified = true

func remove_tile(pos):
	data.erase(pos)
	data_modified = true
