extends RefCounted
class_name ContextDataBuilder

# 这个类现在只负责生成结构化的Dictionary数据，不再关心Markdown格式。
# 这种分离使得数据生成逻辑更纯粹，更容易测试和复用，而Markdown格式化则由MarkdownFormatter负责。

# 默认扫描的文件扩展名列表。
# 只有这些扩展名的文件才会被包含在文件夹结构数据中。
const DEFAULT_SCAN_EXTENSIONS: Array = [
	".tres", ".mp3", ".png", ".jpg", ".ogg", 
	".tscn", ".gd", ".cfg", ".json", ".wav", 
	".svg", ".md"
]


#==============================================================================
# ## 公共函数 ##
#==============================================================================

# 构建指定文件夹的目录结构数据。
# 返回一个包含文件夹名称、路径、类型和子节点（children）的字典。
static func build_folder_structure_data(_folder_path: String, _file_extensions: PackedStringArray = DEFAULT_SCAN_EXTENSIONS) -> Dictionary:
	# 检查文件夹路径是否存在且有效。如果无效，返回空字典。
	if not DirAccess.dir_exists_absolute(ProjectSettings.globalize_path(_folder_path)):
		return {}
	
	return {
		"name": _folder_path.get_file(),
		"path": _folder_path,
		"type": "directory",
		"children": _build_folder_tree_data(_folder_path, _file_extensions)
	}


# 递归函数，用于生成目录树数据。
# 遍历指定路径下的文件和子目录，并为它们生成结构化数据。
static func _build_folder_tree_data(_path: String, _file_extensions: PackedStringArray) -> Array:
	var children_data: Array = [] # 存储当前路径下的子节点数据
	var dir: DirAccess = DirAccess.open(_path) # 打开目录访问器
	
	if dir: # 如果目录成功打开
		# 遍历所有子目录
		for item in dir.get_directories():
			# 忽略特殊目录 "." (当前目录) 和 ".." (父目录)
			if item != "." and item != "..":
				# 构建子目录的完整路径
				var new_path: String = _path.path_join(item)
				children_data.append({
					"name": item,
					"path": new_path,
					"type": "directory",
					"children": _build_folder_tree_data(new_path, _file_extensions) # 递归构建子目录的子节点数据
				})
		
		# 遍历所有文件
		for item in dir.get_files():
			# 检查文件扩展名是否在允许的列表中
			for ext in _file_extensions:
				if item.ends_with(ext):
					children_data.append({
						"name": item,
						"path": _path.path_join(item),
						"type": "file"
					})
					break # 找到匹配的扩展名后，跳出内层循环，处理下一个文件
	
	return children_data


# 构建指定场景文件的节点树数据。
# 加载场景并递归遍历其节点，生成结构化数据。
static func build_scene_tree_data(_scene_path: String) -> Dictionary:
	if not FileAccess.file_exists(_scene_path): return {}
	
	# 加载场景资源
	var scene_resource: PackedScene = load(_scene_path)
	# 如果加载失败，返回空字典
	if not scene_resource: return {}
	
	# 实例化场景。使用 GEN_EDIT_STATE_MAIN 状态，确保在编辑器上下文中实例化，
	# 能够访问到编辑器特有的节点和属性。
	var scene_instance = scene_resource.instantiate(PackedScene.GEN_EDIT_STATE_MAIN)
	if not is_instance_valid(scene_instance): return {}
	# 递归构建场景节点数据
	var tree_data = _build_scene_node_data(scene_instance)
	# 释放场景实例，避免内存泄漏
	scene_instance.free()
	return tree_data


# 递归函数，用于生成场景节点树数据。
# 遍历节点及其所有子节点，收集它们的名称、类名和脚本路径。
static func _build_scene_node_data(_node: Node) -> Dictionary:
	var node_data: Dictionary = {
		"name": _node.name,
		"class": _node.get_class(),
		"script": null,
		"children": []
	}
	
	# 获取节点关联的脚本
	var script = _node.get_script()
	# 如果脚本有效且有资源路径，则记录脚本路径
	if is_instance_valid(script) and script.resource_path:
		node_data["script"] = script.resource_path
	
	for child in _node.get_children():
		# 递归构建子节点数据并添加到数组
		node_data["children"].append(_build_scene_node_data(child))
		
	return node_data


# 构建指定脚本文件的内容数据。
# 加载脚本文件并获取其源代码。
static func build_script_content_data(_script_path: String) -> Dictionary:
	if not FileAccess.file_exists(_script_path): return {}
	
	var script_resource: Resource = load(_script_path)
	
	if not script_resource is Script:
		return {}
	
	if not is_instance_valid(script_resource) or not script_resource.has_source_code():
		return {}
	
	return {
		"path": _script_path,
		"source_code": script_resource.source_code
	}


# 构建通用文本文件（.txt, .md, .json, .cfg 等）的内容数据。
# 对JSON文件会尝试进行格式化。
static func build_text_content_data(_file_path: String) -> Dictionary:
	if not FileAccess.file_exists(_file_path): return {}
	
	var file: FileAccess = FileAccess.open(_file_path, FileAccess.READ)
	if not is_instance_valid(file): return {}
	
	var content: String = file.get_as_text()
	file.close()
	
	# 如果是JSON文件，尝试解析并美化输出，以增强可读性
	if _file_path.get_extension().to_lower() == "json":
		var json: JSON = JSON.new()
		var error: Error = json.parse(content)
		if error == OK:
			# 如果解析成功，使用stringify进行美化（缩进）
			content = JSON.stringify(json.get_data(), "\t")
		# 如果解析失败，则直接返回原始文本内容，不做处理
	
	return {
		"path": _file_path,
		"content": content
	}


# 构建图片文件（.png, .jpg, .svg 等）的元数据。
# 返回包含路径、尺寸、文件大小内容的字典。
static func build_image_metadata_data(_image_path: String) -> Dictionary:
	if not FileAccess.file_exists(_image_path): return {}
	
	# 检查是否是支持的图片格式
	var supported_extensions: Array = ["png", "jpg", "jpeg", "svg"]
	if not _image_path.get_extension().to_lower() in supported_extensions:
		return {}
	
	var texture: Texture2D = load(_image_path)
	if not is_instance_valid(texture):
		return {}
	
	var file_size_bytes := 0
	var file = FileAccess.open(_image_path, FileAccess.READ)
	
	if file:
		file_size_bytes = file.get_length()
		file.close()
	else:
		return {}
	
	return {
		"path": _image_path,
		"width": texture.get_width(),
		"height": texture.get_height(),
		"file_size_bytes": file_size_bytes,
	}
