# res://addons/context_toolkit/scripts/core/workspace_manager.gd
extends Node
class_name WorkspaceManager


signal workspace_scanned(scan_result: Dictionary) # 定义一个信号，在工作区扫描完成后发出，传递扫描结果

var current_workspace_path: String = ""
var _scan_request_id := 0 # 用于防抖动机制的请求ID，确保只执行最新的扫描请求


# 切换工作区路径并触发一次新的扫描
func switch_workspace(new_path: String):
	current_workspace_path = new_path
	_scan_request_id += 1 # 增加请求ID，使之前的防抖动请求失效
	scan_workspace()


# 带有防抖动功能的扫描触发器
# 防止在短时间内多次触发扫描，例如在文件系统频繁变动时
func trigger_debounced_scan() -> void:
	_scan_request_id += 1
	var current_id = _scan_request_id
	# 等待0.5秒。如果在这期间 _scan_request_id 被再次修改，说明有新的扫描请求，则当前请求作废。
	await Engine.get_main_loop().create_timer(0.5).timeout
	# 检查节点是否仍然有效（未被释放）并且当前请求ID与等待前的ID一致，
	# 只有这样才执行实际的扫描操作。
	if get_tree() and current_id == _scan_request_id:
		scan_workspace()


# 扫描当前工作区，查找场景和脚本文件
func scan_workspace():
	if current_workspace_path.is_empty():
		emit_signal("workspace_scanned", {"scenes": [], "scripts": []})
		return
	
	var scenes = FileSystemScanner.scan_for_files(current_workspace_path, ".tscn")
	var scripts = FileSystemScanner.scan_for_files(current_workspace_path, ".gd")
	
	var relative_scenes = _get_relative_paths(scenes)
	var relative_scripts = _get_relative_paths(scripts)
	
	var result = {
		"scenes": relative_scenes,
		"scripts": relative_scripts
	}
	emit_signal("workspace_scanned", result)


# 辅助函数，将完整路径转换为相对于当前工作区路径的相对路径
func _get_relative_paths(full_paths: Array) -> Array:
	var relative_paths: Array = []
	if current_workspace_path.is_empty(): return relative_paths
	
	var prefix = current_workspace_path + "/"
	for path in full_paths:
		# 移除完整路径中的工作区前缀，得到相对路径
		relative_paths.append(path.replace(prefix, ""))
	
	return relative_paths


# 获取当前工作区的显示名称，通常是其路径，但如果路径很长则进行缩短
func get_display_name() -> String:
	if current_workspace_path.is_empty(): return "N/A"
	
	const MAX_PARTS_TO_SHOW = 3 # 最多显示的路径部分数量
	var relative_path = current_workspace_path.trim_prefix("res://") # 移除 "res://" 前缀
	var parts = relative_path.split("/")
	
	if parts.size() <= MAX_PARTS_TO_SHOW:
		return current_workspace_path # 如果路径较短，直接返回完整路径
	else:
		# 如果路径较长，只显示最后几部分，并在前面加上 "res://.../"
		var last_parts = parts.slice(parts.size() - MAX_PARTS_TO_SHOW)
		return "res://.../%s" % "/".join(last_parts)
