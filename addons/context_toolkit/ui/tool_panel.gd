@tool
extends Control

# --- UI 节点引用 ---
@onready var current_workspace_label: Label = $MarginContainer/HBoxContainer/FunctionBar/Panel/MarginContainer/VBoxContainer/CurrentWorkSpaceLabel
@onready var context_folder_selector_button: Button = $MarginContainer/HBoxContainer/FunctionBar/Panel/MarginContainer/VBoxContainer/ContextFolderSelectorButton
@onready var get_folder_structure_button: Button = $MarginContainer/HBoxContainer/FunctionBar/Panel/MarginContainer/VBoxContainer/GetFolderStructureButton
@onready var scene_selector: OptionButton = $MarginContainer/HBoxContainer/FunctionBar/Panel/MarginContainer/VBoxContainer/HBoxContainer/SceneSelector
@onready var get_scene_tree_button: Button = $MarginContainer/HBoxContainer/FunctionBar/Panel/MarginContainer/VBoxContainer/HBoxContainer/GetSceneTreeButton
@onready var script_selector: OptionButton = $MarginContainer/HBoxContainer/FunctionBar/Panel/MarginContainer/VBoxContainer/HBoxContainer2/ScriptSelector
@onready var get_script_code_button: Button = $MarginContainer/HBoxContainer/FunctionBar/Panel/MarginContainer/VBoxContainer/HBoxContainer2/GetScriptCodeButton
@onready var user_input: TextEdit = $MarginContainer/HBoxContainer/ChatBar/Panel/MarginContainer/UserInput
@onready var file_dialog: FileDialog = $FileDialog

# --- 成员变量 ---

# UI层拥有并管理其自己的状态管理器（WorkspaceManager）。
# WorkspaceManager负责处理与UI状态相关的逻辑，如当前工作区路径、文件扫描等。
var workspace_manager: WorkspaceManager
# API Provider（ContextProvider）作为一个无状态的服务被外部（plugin.gd）注入。
# 它负责所有的数据获取和格式化工作，UI层只调用它的方法，不关心其内部实现。
var context_provider: ContextProvider


func _ready() -> void:
	# --- UI 初始化 ---
	get_scene_tree_button.text = "Get Scene Tree"
	get_script_code_button.text = "Get Script Code"
	get_folder_structure_button.text = "Get Folder Structure"
	context_folder_selector_button.text = "Select Workspace"
	
	# --- 状态管理器实例化 ---
	workspace_manager = WorkspaceManager.new()
	# 将其作为子节点添加，以确保它在场景树中，从而使其内部的 get_tree() 调用能够成功。
	# 这对于使用计时器（create_timer）等场景树相关功能至关重要。
	add_child(workspace_manager)
	
	# --- 信号连接 ---
	# 将WorkspaceManager的workspace_scanned信号连接到UI面板的_on_workspace_scanned方法。
	# 当工作区扫描完成时，UI会收到通知并更新。
	workspace_manager.workspace_scanned.connect(_on_workspace_scanned)
	# 连接各个按钮的pressed信号到对应的处理函数。
	context_folder_selector_button.pressed.connect(_on_workspace_selector_pressed)
	get_folder_structure_button.pressed.connect(_on_get_folder_info_pressed)
	get_scene_tree_button.pressed.connect(_on_get_scene_info_pressed)
	get_script_code_button.pressed.connect(_on_get_script_info_pressed)
	# 连接文件对话框的dir_selected信号，当用户选择一个目录后触发。
	file_dialog.dir_selected.connect(_on_workspace_dir_selected)
	
	# --- 初始设置 ---
	# 初始化一个默认的工作区，并触发第一次扫描。
	workspace_manager.switch_workspace("res://addons/context_toolkit")


# 此方法由 plugin.gd 调用，用于注入无状态的API服务（ContextProvider）。
# 这是一种依赖注入的实现，将数据逻辑与UI逻辑解耦。
func set_provider(provider: ContextProvider):
	context_provider = provider


# 此方法由 plugin.gd 连接到Godot编辑器的 filesystem_changed 信号。
# 当项目中的文件发生任何变化（增、删、改）时，此方法会被调用。
func on_filesystem_changed():
	if is_instance_valid(workspace_manager):
		workspace_manager.trigger_debounced_scan()


func _update_workspace_label() -> void:
	current_workspace_label.text = "Current Workspace: %s" % workspace_manager.get_display_name()


func _on_workspace_selector_pressed() -> void:
	file_dialog.file_mode = FileDialog.FILE_MODE_OPEN_DIR
	file_dialog.title = "Select a workspace directory"
	file_dialog.popup_centered()


func _on_workspace_dir_selected(dir: String) -> void:
	workspace_manager.switch_workspace(dir)


func _on_get_scene_info_pressed() -> void:
	if scene_selector.selected < 0 or not is_instance_valid(context_provider): return
	var scene_file_name = scene_selector.get_item_text(scene_selector.selected)
	var full_path = workspace_manager.current_workspace_path.path_join(scene_file_name)
	
	var result = context_provider.get_scene_tree_as_markdown(full_path)
	_handle_provider_result(result)


func _on_get_script_info_pressed() -> void:
	if script_selector.selected < 0 or not is_instance_valid(context_provider): return
	var script_file_name = script_selector.get_item_text(script_selector.selected)
	var full_path = workspace_manager.current_workspace_path.path_join(script_file_name)
	
	var result = context_provider.get_script_content_as_markdown(full_path)
	_handle_provider_result(result)


func _on_get_folder_info_pressed() -> void:
	if not is_instance_valid(context_provider): return
	var current_workspace = workspace_manager.current_workspace_path
	
	var result = context_provider.get_folder_structure_as_markdown(current_workspace)
	_handle_provider_result(result)


# 统一处理来自 ContextProvider 的返回结果（字典）。
func _handle_provider_result(result: Dictionary):
	if result.success:
		_inject_context(result.data)
	else:
		# 使用 .get() 方法安全地访问字典，以防 "error" 键不存在
		_inject_context("[ERROR: %s]" % result.get("error", "Unknown error occurred."))


# 将最终的字符串注入到用户输入框（TextEdit）。
func _inject_context(context_md: String) -> void:
	user_input.text = MessageBuilder.build_message(user_input.text, context_md)
	user_input.grab_focus()
	var last_line = user_input.get_line_count() - 1
	user_input.set_caret_line(last_line)
	user_input.set_caret_column(user_input.get_line(last_line).length())


# 监听来自 WorkspaceManager 的 workspace_scanned 信号，以更新UI。
func _on_workspace_scanned(scan_result: Dictionary):
	_update_workspace_label()
	var scene_files = scan_result.scenes
	var script_files = scan_result.scripts
	
	scene_selector.clear()
	if scene_files.is_empty():
		scene_selector.add_item("No scene files found")
		scene_selector.disabled = true
	else:
		for scene_file in scene_files:
			scene_selector.add_item(scene_file)
		scene_selector.disabled = false
		
	script_selector.clear()
	if script_files.is_empty():
		script_selector.add_item("No script files found")
		script_selector.disabled = true
	else:
		for script_file in script_files:
			script_selector.add_item(script_file)
		script_selector.disabled = false
