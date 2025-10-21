@tool
extends EditorPlugin

# --- 成员变量 ---
var panel_instance: Control
var context_provider: ContextProvider
var panel_scene = preload("res://addons/context_toolkit/ui/tool_panel.tscn")


# --- 公共API访问器 ---
# 这是一个为其他插件提供访问 ContextProvider 实例的公共函数。
# 返回一个无状态的API Provider实例，其他插件可以通过这个实例来获取上下文信息。
func get_context_provider() -> ContextProvider:
	return context_provider


# --- Godot生命周期函数 ---

func _enter_tree() -> void:
	# 1. 实例化无状态的API Provider
	# 直接使用全局的 class_name (ContextProvider) 进行实例化，无需 load()。
	# ContextProvider 负责处理所有数据获取和格式化的逻辑。
	context_provider = ContextProvider.new()
	
	# 2. 实例化UI面板
	panel_instance = panel_scene.instantiate()
	panel_instance.name = "ContextToolKit" # 为UI节点设置一个唯一的名称
	
	# 3. 将面板添加到编辑器底部，并连接其ready信号，以便进行后续设置
	# ready 信号在节点及其所有子节点都进入场景树并完成初始化时发出。
	panel_instance.ready.connect(_on_panel_ready, CONNECT_ONE_SHOT)
	add_control_to_bottom_panel(panel_instance, "Context ToolKit")


func _exit_tree() -> void:
	var filesystem: EditorFileSystem = EditorInterface.get_resource_filesystem() # 获取资源文件系统，用于监听文件变化
	
	# 在退出时，断开之前建立的信号连接，防止悬空引用（dangling reference）或内存泄漏
	if is_instance_valid(filesystem) and is_instance_valid(panel_instance):
		if filesystem.filesystem_changed.is_connected(panel_instance.on_filesystem_changed):
			filesystem.filesystem_changed.disconnect(panel_instance.on_filesystem_changed)
			print(">>>> Context ToolKit: Filesystem watcher disconnected. <<<<")
	
	# 按顺序清理UI和数据实例，确保资源正确释放
	if is_instance_valid(panel_instance):
		remove_control_from_bottom_panel(panel_instance)
		panel_instance.free()
	
	if is_instance_valid(context_provider):
		context_provider.free() # 别忘了释放 ContextProvider 实例的内存


# 当UI面板完全准备好（即其 _ready() 函数被调用后）时，此函数被调用
func _on_panel_ready() -> void:
	# 检查面板实例是否仍然有效，以防止在面板被释放后尝试访问它
	if not is_instance_valid(panel_instance):
		return
	
	# 将无状态的API Provider注入到UI面板中，供其内部使用
	# UI面板 (tool_panel.gd) 将通过这个 Provider 来获取各种上下文数据。
	if is_instance_valid(context_provider) and panel_instance.has_method("set_provider"):
		panel_instance.set_provider(context_provider)
	
	var filesystem: EditorFileSystem = EditorInterface.get_resource_filesystem() # 获取文件系统
	
	# 确保文件系统和面板方法都有效
	if is_instance_valid(filesystem) and panel_instance.has_method("on_filesystem_changed"):
		# 将文件系统变动信号直接连接到UI面板的方法上。
		# 这样，当项目文件系统发生变化时（如文件被创建、删除、修改），UI面板可以收到通知并更新其显示。
		var error_code: Error = filesystem.filesystem_changed.connect(panel_instance.on_filesystem_changed)
		
		if error_code == OK: # 检查信号连接是否成功
			print(">>>> Context ToolKit: Signal connection to UI panel SUCCEEDED. <<<<")
		else:
			print(">>>> Context ToolKit: Signal connection FAILED with error code: %s <<<<" % error_code)
	else:
		print(">>>> Context ToolKit: ERROR - Could not get a valid filesystem object or panel is missing method. <<<<")
