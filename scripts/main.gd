extends Control

const APP_TITLE := "NURBS Studio"
const FILE_EXTENSION := "nurbs.json"

var curve: NurbsCurve2D
var canvas: NurbsCanvas
var inspector_title: Label
var point_fields: Array[SpinBox] = []
var degree_spin: SpinBox
var tessellation_spin: SpinBox
var knot_edit: LineEdit
var knot_error: Label
var curve_info: Label
var status_label: Label
var file_dialog: FileDialog
var export_dialog: FileDialog
var tool_buttons: Array[Button] = []

var current_path := ""
var dirty := false
var _updating_ui := false
var _edit_snapshot: Dictionary = {}
var _undo_stack: Array[Dictionary] = []
var _redo_stack: Array[Dictionary] = []


func _ready() -> void:
	_build_theme()
	_build_interface()
	_build_dialogs()
	_new_document(false)
	get_window().title = APP_TITLE
	call_deferred("_finish_startup")


func _finish_startup() -> void:
	canvas.fit_curve()
	canvas.grab_focus()


func _build_theme() -> void:
	var app_theme := Theme.new()
	app_theme.default_font_size = 14
	app_theme.set_stylebox("panel", "PanelContainer", _style_box(Color("0b111b"), 0, Color("1e293b"), 1))
	app_theme.set_stylebox("normal", "Button", _style_box(Color("151f2e"), 6, Color("26364b"), 1))
	app_theme.set_stylebox("hover", "Button", _style_box(Color("1d2d41"), 6, Color("3b82a8"), 1))
	app_theme.set_stylebox("pressed", "Button", _style_box(Color("102d3c"), 6, Color("38bdf8"), 1))
	app_theme.set_stylebox("focus", "Button", _style_box(Color.TRANSPARENT, 6, Color("7dd3fc"), 1))
	app_theme.set_stylebox("normal", "LineEdit", _style_box(Color("0e1622"), 5, Color("26364b"), 1))
	app_theme.set_stylebox("focus", "LineEdit", _style_box(Color("101c2a"), 5, Color("38bdf8"), 1))
	app_theme.set_stylebox("read_only", "LineEdit", _style_box(Color("0c121b"), 5, Color("1e293b"), 1))
	app_theme.set_color("font_color", "Label", Color("cbd5e1"))
	app_theme.set_color("font_color", "Button", Color("dbeafe"))
	app_theme.set_color("font_hover_color", "Button", Color.WHITE)
	app_theme.set_color("font_pressed_color", "Button", Color("7dd3fc"))
	app_theme.set_color("font_color", "LineEdit", Color("e2e8f0"))
	app_theme.set_color("font_color", "SpinBox", Color("e2e8f0"))
	app_theme.set_color("font_color", "CheckButton", Color("cbd5e1"))
	theme = app_theme


func _style_box(fill: Color, radius: int, border: Color, border_width: int) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = fill
	style.corner_radius_top_left = radius
	style.corner_radius_top_right = radius
	style.corner_radius_bottom_left = radius
	style.corner_radius_bottom_right = radius
	style.border_color = border
	style.border_width_left = border_width
	style.border_width_top = border_width
	style.border_width_right = border_width
	style.border_width_bottom = border_width
	style.content_margin_left = 9.0
	style.content_margin_right = 9.0
	style.content_margin_top = 6.0
	style.content_margin_bottom = 6.0
	return style


func _build_interface() -> void:
	var root := VBoxContainer.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.add_theme_constant_override("separation", 0)
	add_child(root)

	var title_bar := _build_title_bar()
	root.add_child(title_bar)
	var toolbar := _build_toolbar()
	root.add_child(toolbar)

	var workspace := HSplitContainer.new()
	workspace.size_flags_vertical = Control.SIZE_EXPAND_FILL
	workspace.split_offset = 1000
	root.add_child(workspace)

	canvas = NurbsCanvas.new()
	canvas.custom_minimum_size = Vector2(640, 400)
	canvas.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	canvas.size_flags_vertical = Control.SIZE_EXPAND_FILL
	canvas.selection_changed.connect(_on_selection_changed)
	canvas.curve_changed.connect(_on_curve_changed)
	canvas.edit_started.connect(_on_edit_started)
	canvas.edit_finished.connect(_on_edit_finished)
	canvas.pointer_status.connect(_on_pointer_status)
	workspace.add_child(canvas)

	var inspector := _build_inspector()
	inspector.custom_minimum_size.x = 280
	workspace.add_child(inspector)

	var status_bar := PanelContainer.new()
	status_bar.custom_minimum_size.y = 30
	var status_margin := MarginContainer.new()
	status_margin.add_theme_constant_override("margin_left", 12)
	status_margin.add_theme_constant_override("margin_right", 12)
	status_margin.add_theme_constant_override("margin_top", 5)
	status_margin.add_theme_constant_override("margin_bottom", 5)
	status_bar.add_child(status_margin)
	status_label = Label.new()
	status_label.text = "Ready"
	status_label.add_theme_font_size_override("font_size", 12)
	status_label.add_theme_color_override("font_color", Color("94a3b8"))
	status_margin.add_child(status_label)
	root.add_child(status_bar)


func _build_title_bar() -> Control:
	var panel := PanelContainer.new()
	panel.custom_minimum_size.y = 48
	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 16)
	margin.add_theme_constant_override("margin_right", 16)
	margin.add_theme_constant_override("margin_top", 8)
	margin.add_theme_constant_override("margin_bottom", 8)
	panel.add_child(margin)
	var row := HBoxContainer.new()
	margin.add_child(row)
	var brand := Label.new()
	brand.text = "NURBS  /  STUDIO"
	brand.add_theme_font_size_override("font_size", 18)
	brand.add_theme_color_override("font_color", Color("7dd3fc"))
	brand.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(brand)
	var hint := Label.new()
	hint.text = "2D rational curve modeler"
	hint.add_theme_color_override("font_color", Color("64748b"))
	row.add_child(hint)
	return panel


func _build_toolbar() -> Control:
	var panel := PanelContainer.new()
	panel.custom_minimum_size.y = 52
	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 10)
	margin.add_theme_constant_override("margin_right", 10)
	margin.add_theme_constant_override("margin_top", 7)
	margin.add_theme_constant_override("margin_bottom", 7)
	panel.add_child(margin)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 6)
	margin.add_child(row)
	row.add_child(_button("New", _new_document.bind(true), "Ctrl+N"))
	row.add_child(_button("Open", _show_open_dialog, "Ctrl+O"))
	row.add_child(_button("Save", _save_document, "Ctrl+S"))
	row.add_child(_button("Export SVG", _show_export_dialog, "Ctrl+E"))
	row.add_child(VSeparator.new())
	row.add_child(_button("Undo", _undo, "Ctrl+Z"))
	row.add_child(_button("Redo", _redo, "Ctrl+Shift+Z"))
	row.add_child(VSeparator.new())

	var group := ButtonGroup.new()
	for definition in [["Select", NurbsCanvas.ToolMode.SELECT, "V"], ["Add point", NurbsCanvas.ToolMode.ADD, "A"], ["Delete", NurbsCanvas.ToolMode.DELETE, "X"]]:
		var button := Button.new()
		button.text = definition[0]
		button.toggle_mode = true
		button.button_group = group
		button.tooltip_text = "%s tool  [%s]" % [definition[0], definition[2]]
		button.pressed.connect(_set_tool.bind(definition[1]))
		tool_buttons.append(button)
		row.add_child(button)
	tool_buttons[0].button_pressed = true
	row.add_child(VSeparator.new())
	row.add_child(_button("Fit", _fit_view, "F"))
	var grid_toggle := CheckButton.new()
	grid_toggle.text = "Grid"
	grid_toggle.button_pressed = true
	grid_toggle.toggled.connect(_toggle_grid)
	row.add_child(grid_toggle)
	var snap_toggle := CheckButton.new()
	snap_toggle.text = "Snap"
	snap_toggle.toggled.connect(_toggle_snap)
	row.add_child(snap_toggle)
	var curvature_toggle := CheckButton.new()
	curvature_toggle.text = "Curvature"
	curvature_toggle.button_pressed = true
	curvature_toggle.tooltip_text = "Show curvature spikes; longer and warmer means a sharper bend"
	curvature_toggle.toggled.connect(_toggle_curvature)
	row.add_child(curvature_toggle)
	return panel


func _build_inspector() -> Control:
	var panel := PanelContainer.new()
	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 16)
	margin.add_theme_constant_override("margin_right", 16)
	margin.add_theme_constant_override("margin_top", 18)
	margin.add_theme_constant_override("margin_bottom", 16)
	panel.add_child(margin)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 10)
	margin.add_child(column)

	var heading := Label.new()
	heading.text = "CURVE"
	heading.add_theme_font_size_override("font_size", 12)
	heading.add_theme_color_override("font_color", Color("7dd3fc"))
	column.add_child(heading)
	curve_info = Label.new()
	curve_info.text = ""
	column.add_child(curve_info)
	column.add_child(_field_label("Tessellation vertices"))
	tessellation_spin = SpinBox.new()
	tessellation_spin.min_value = 3
	tessellation_spin.max_value = 512
	tessellation_spin.step = 1
	tessellation_spin.value = canvas.tessellation_vertex_count
	tessellation_spin.tooltip_text = "Exact vertex count for the adaptive maximum-error polyline"
	tessellation_spin.value_changed.connect(_on_tessellation_vertex_count_changed)
	column.add_child(tessellation_spin)
	column.add_child(_field_label("Degree"))
	degree_spin = SpinBox.new()
	degree_spin.min_value = 1
	degree_spin.max_value = 12
	degree_spin.step = 1
	degree_spin.value_changed.connect(_on_degree_changed)
	column.add_child(degree_spin)
	column.add_child(_field_label("Knot vector"))
	knot_edit = LineEdit.new()
	knot_edit.placeholder_text = "0, 0, 0, 1, 1, 1"
	knot_edit.tooltip_text = "A nondecreasing list with point count + degree + 1 values"
	knot_edit.text_submitted.connect(_apply_knots.unbind(1))
	column.add_child(knot_edit)
	var knot_actions := HBoxContainer.new()
	knot_actions.add_child(_button("Apply knots", _apply_knots))
	knot_actions.add_child(_button("Uniform", _make_uniform))
	column.add_child(knot_actions)
	knot_error = Label.new()
	knot_error.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	knot_error.add_theme_font_size_override("font_size", 11)
	knot_error.add_theme_color_override("font_color", Color("fb7185"))
	column.add_child(knot_error)
	column.add_child(HSeparator.new())

	inspector_title = Label.new()
	inspector_title.text = "CONTROL POINT"
	inspector_title.add_theme_font_size_override("font_size", 12)
	inspector_title.add_theme_color_override("font_color", Color("fbbf24"))
	column.add_child(inspector_title)
	for definition in [["X", -100000.0, 100000.0, 0.1], ["Y", -100000.0, 100000.0, 0.1], ["Weight", 0.01, 1000.0, 0.05]]:
		column.add_child(_field_label(definition[0]))
		var spin := SpinBox.new()
		spin.min_value = definition[1]
		spin.max_value = definition[2]
		spin.step = definition[3]
		spin.allow_greater = true
		spin.allow_lesser = definition[0] != "Weight"
		spin.value_changed.connect(_on_point_field_changed)
		point_fields.append(spin)
		column.add_child(spin)
	column.add_child(_button("Remove selected point", _delete_selected, "Delete"))
	var spacer := Control.new()
	spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	column.add_child(spacer)
	var help := Label.new()
	help.text = "Mouse wheel  Zoom\nMiddle / right drag  Pan\nLeft drag  Move point\nCurvature spikes point into bends\nCtrl+Z  Undo"
	help.add_theme_font_size_override("font_size", 12)
	help.add_theme_color_override("font_color", Color("64748b"))
	column.add_child(help)
	return panel


func _build_dialogs() -> void:
	file_dialog = FileDialog.new()
	file_dialog.access = FileDialog.ACCESS_FILESYSTEM
	file_dialog.use_native_dialog = false
	file_dialog.filters = PackedStringArray(["*.nurbs.json ; NURBS Studio document"])
	file_dialog.file_selected.connect(_on_file_selected)
	add_child(file_dialog)
	export_dialog = FileDialog.new()
	export_dialog.access = FileDialog.ACCESS_FILESYSTEM
	export_dialog.file_mode = FileDialog.FILE_MODE_SAVE_FILE
	export_dialog.use_native_dialog = false
	export_dialog.filters = PackedStringArray(["*.svg ; Scalable Vector Graphics"])
	export_dialog.file_selected.connect(_export_svg)
	add_child(export_dialog)


func _button(text_value: String, action: Callable, tooltip := "") -> Button:
	var button := Button.new()
	button.text = text_value
	button.tooltip_text = tooltip
	button.pressed.connect(action)
	return button


func _field_label(text_value: String) -> Label:
	var label := Label.new()
	label.text = text_value
	label.add_theme_font_size_override("font_size", 12)
	label.add_theme_color_override("font_color", Color("94a3b8"))
	return label


func _new_document(confirm_if_dirty := true) -> void:
	# New is intentionally immediate; all geometry edits remain recoverable via undo.
	var previous := curve.to_dictionary() if curve != null else {}
	curve = NurbsCurve2D.new([
		Vector2(-320, -80),
		Vector2(-180, 180),
		Vector2(20, -150),
		Vector2(190, 170),
		Vector2(340, 20),
	])
	curve.weights[2] = 1.5
	canvas.set_curve(curve)
	current_path = ""
	dirty = false
	_undo_stack.clear()
	_redo_stack.clear()
	if not previous.is_empty() and confirm_if_dirty:
		_undo_stack.append(previous)
	_refresh_ui()
	_update_window_title()
	status_label.text = "New document"
	call_deferred("_fit_view")


func _set_tool(mode: NurbsCanvas.ToolMode) -> void:
	canvas.set_tool(mode)
	for index in range(tool_buttons.size()):
		tool_buttons[index].button_pressed = index == mode


func _fit_view() -> void:
	canvas.fit_curve()


func _toggle_grid(value: bool) -> void:
	canvas.show_grid = value
	canvas.queue_redraw()


func _toggle_snap(value: bool) -> void:
	canvas.snap_enabled = value
	status_label.text = "Grid snapping %s" % ("on" if value else "off")


func _toggle_curvature(value: bool) -> void:
	canvas.show_curvature = value
	canvas.queue_redraw()
	status_label.text = "Curvature comb %s" % ("shown" if value else "hidden")


func _on_tessellation_vertex_count_changed(value: float) -> void:
	if _updating_ui:
		return
	canvas.set_tessellation_vertex_count(int(value))
	status_label.text = "Tessellation: %d vertices" % canvas.tessellation_vertex_count


func _on_selection_changed(_index: int) -> void:
	_refresh_ui()


func _on_curve_changed() -> void:
	dirty = true
	canvas.invalidate_tessellation()
	_refresh_ui()
	_update_window_title()


func _on_edit_started() -> void:
	_edit_snapshot = curve.to_dictionary()


func _on_edit_finished() -> void:
	if not _edit_snapshot.is_empty() and curve.to_dictionary() != _edit_snapshot:
		_undo_stack.append(_edit_snapshot)
		if _undo_stack.size() > 100:
			_undo_stack.pop_front()
		_redo_stack.clear()
	_edit_snapshot = {}


func _on_pointer_status(text_value: String) -> void:
	status_label.text = text_value


func _on_degree_changed(value: float) -> void:
	if _updating_ui or curve == null:
		return
	var snapshot := curve.to_dictionary()
	curve.set_degree(int(value))
	_commit_property_change(snapshot)


func _on_point_field_changed(_value: float) -> void:
	if _updating_ui or canvas.selected_index < 0:
		return
	var snapshot := curve.to_dictionary()
	var index := canvas.selected_index
	curve.control_points[index] = Vector2(point_fields[0].value, point_fields[1].value)
	curve.weights[index] = point_fields[2].value
	_commit_property_change(snapshot)


func _apply_knots() -> void:
	var values: Array[float] = []
	for part in knot_edit.text.replace(";", ",").split(",", false):
		if not part.strip_edges().is_valid_float():
			knot_error.text = "Every knot must be a number."
			return
		values.append(part.strip_edges().to_float())
	var snapshot := curve.to_dictionary()
	if not curve.set_custom_knots(values):
		knot_error.text = "Expected %d nondecreasing values with a usable domain." % (curve.control_points.size() + curve.degree + 1)
		return
	knot_error.text = ""
	_commit_property_change(snapshot)


func _make_uniform() -> void:
	var snapshot := curve.to_dictionary()
	curve.regenerate_knots()
	_commit_property_change(snapshot)


func _commit_property_change(snapshot: Dictionary) -> void:
	if curve.to_dictionary() == snapshot:
		return
	_undo_stack.append(snapshot)
	_redo_stack.clear()
	dirty = true
	canvas.invalidate_tessellation()
	_refresh_ui()
	_update_window_title()


func _delete_selected() -> void:
	canvas.delete_selected()


func _undo() -> void:
	if _undo_stack.is_empty():
		status_label.text = "Nothing to undo"
		return
	_redo_stack.append(curve.to_dictionary())
	_restore_snapshot(_undo_stack.pop_back())
	status_label.text = "Undo"


func _redo() -> void:
	if _redo_stack.is_empty():
		status_label.text = "Nothing to redo"
		return
	_undo_stack.append(curve.to_dictionary())
	_restore_snapshot(_redo_stack.pop_back())
	status_label.text = "Redo"


func _restore_snapshot(snapshot: Dictionary) -> void:
	curve = NurbsCurve2D.from_dictionary(snapshot)
	canvas.set_curve(curve)
	dirty = true
	_refresh_ui()
	_update_window_title()


func _refresh_ui() -> void:
	if curve == null:
		return
	_updating_ui = true
	tessellation_spin.value = canvas.tessellation_vertex_count
	degree_spin.max_value = maxi(1, curve.control_points.size() - 1)
	degree_spin.value = curve.degree
	curve_info.text = "%d control points  ·  degree %d" % [curve.control_points.size(), curve.degree]
	var knot_parts: PackedStringArray = []
	for knot in curve.knots:
		knot_parts.append(str(snappedf(knot, 0.001)))
	knot_edit.text = ", ".join(knot_parts)
	var has_selection := canvas.selected_index >= 0 and canvas.selected_index < curve.control_points.size()
	inspector_title.text = "CONTROL POINT %d" % (canvas.selected_index + 1) if has_selection else "CONTROL POINT"
	for field in point_fields:
		field.editable = has_selection
	if has_selection:
		var index := canvas.selected_index
		point_fields[0].value = curve.control_points[index].x
		point_fields[1].value = curve.control_points[index].y
		point_fields[2].value = curve.weights[index]
	else:
		for field in point_fields:
			field.value = 0.0
	_updating_ui = false


func _show_open_dialog() -> void:
	file_dialog.file_mode = FileDialog.FILE_MODE_OPEN_FILE
	file_dialog.title = "Open NURBS document"
	file_dialog.popup_centered_ratio(0.7)


func _save_document() -> void:
	if current_path.is_empty():
		file_dialog.file_mode = FileDialog.FILE_MODE_SAVE_FILE
		file_dialog.title = "Save NURBS document"
		file_dialog.current_file = "untitled.%s" % FILE_EXTENSION
		file_dialog.popup_centered_ratio(0.7)
	else:
		_write_document(current_path)


func _on_file_selected(path: String) -> void:
	if file_dialog.file_mode == FileDialog.FILE_MODE_OPEN_FILE:
		_open_document(path)
	else:
		_write_document(_ensure_extension(path, "." + FILE_EXTENSION))


func _write_document(path: String) -> void:
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		status_label.text = "Could not save: %s" % FileAccess.get_open_error()
		return
	file.store_string(JSON.stringify(curve.to_dictionary(), "  "))
	current_path = path
	dirty = false
	_update_window_title()
	status_label.text = "Saved  %s" % path


func _open_document(path: String) -> void:
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		status_label.text = "Could not open: %s" % FileAccess.get_open_error()
		return
	var parsed = JSON.parse_string(file.get_as_text())
	if not parsed is Dictionary:
		status_label.text = "This file is not a NURBS Studio document"
		return
	var loaded := NurbsCurve2D.from_dictionary(parsed)
	if not loaded.is_valid():
		status_label.text = "The document does not contain a valid curve"
		return
	curve = loaded
	canvas.set_curve(curve)
	current_path = path
	dirty = false
	_undo_stack.clear()
	_redo_stack.clear()
	_refresh_ui()
	_update_window_title()
	canvas.fit_curve()
	status_label.text = "Opened  %s" % path


func _show_export_dialog() -> void:
	export_dialog.current_file = "curve.svg"
	export_dialog.popup_centered_ratio(0.7)


func _export_svg(path: String) -> void:
	path = _ensure_extension(path, ".svg")
	var bounds := curve.get_bounds().grow(40.0)
	if bounds.size.x <= 0.0 or bounds.size.y <= 0.0:
		status_label.text = "Nothing to export"
		return
	var points := curve.tessellate(400)
	var path_data := PackedStringArray()
	for index in range(points.size()):
		var point := points[index] - bounds.position
		var command := "M" if index == 0 else "L"
		path_data.append("%s %.4f %.4f" % [command, point.x, bounds.size.y - point.y])
	var svg := """<svg xmlns="http://www.w3.org/2000/svg" width="%.4f" height="%.4f" viewBox="0 0 %.4f %.4f">
  <path d="%s" fill="none" stroke="#0ea5e9" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"/>
</svg>
""" % [bounds.size.x, bounds.size.y, bounds.size.x, bounds.size.y, " ".join(path_data)]
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		status_label.text = "Could not export SVG"
		return
	file.store_string(svg)
	status_label.text = "Exported  %s" % path


func _ensure_extension(path: String, extension: String) -> String:
	return path if path.to_lower().ends_with(extension) else path + extension


func _update_window_title() -> void:
	var document_name := "Untitled" if current_path.is_empty() else current_path.get_file()
	get_window().title = "%s%s — %s" % ["*" if dirty else "", document_name, APP_TITLE]


func _unhandled_key_input(event: InputEvent) -> void:
	if not event.pressed or event.echo:
		return
	if event.ctrl_pressed:
		match event.keycode:
			KEY_N: _new_document(true)
			KEY_O: _show_open_dialog()
			KEY_S: _save_document()
			KEY_E: _show_export_dialog()
			KEY_Z:
				if event.shift_pressed: _redo()
				else: _undo()
			KEY_Y: _redo()
		return
	match event.keycode:
		KEY_V: _activate_tool(NurbsCanvas.ToolMode.SELECT)
		KEY_A: _activate_tool(NurbsCanvas.ToolMode.ADD)
		KEY_X: _activate_tool(NurbsCanvas.ToolMode.DELETE)
		KEY_F: _fit_view()
		KEY_DELETE, KEY_BACKSPACE: _delete_selected()


func _activate_tool(mode: NurbsCanvas.ToolMode) -> void:
	tool_buttons[mode].button_pressed = true
	_set_tool(mode)
