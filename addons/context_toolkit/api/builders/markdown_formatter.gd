extends RefCounted
class_name MarkdownFormatter

# 这个类的职责是纯粹的格式化，将 ContextDataBuilder 生成的字典数据转换成易于阅读的Markdown格式。
# 这使得数据生成和数据展示的逻辑完全分离，提高了代码的可维护性和扩展性。


#==============================================================================
# ## 公共函数 ##
#==============================================================================

# 格式化文件夹结构数据为Markdown字符串。
static func format_folder_structure(_folder_data: Dictionary) -> String:
	if _folder_data.is_empty():
		return ""
	
	# 构建Markdown头部，包含文件夹路径
	var context_md: String = "Context for Folder: `%s`\n\n" % _folder_data.path
	context_md += "Folder File Structure:\n```\n" # 开始代码块，用于展示文件结构
	context_md += "%s/\n" % _folder_data.name # 添加根文件夹名称
	# 递归格式化子节点，并添加缩进
	context_md += _format_folder_tree_recursive(_folder_data.children, "  ")
	context_md += "```\n" # 结束代码块
	return context_md


# 递归函数，用于将文件夹树数据格式化为Markdown字符串。
# 根据层级添加缩进和连接符（├─, └─, │）。
static func _format_folder_tree_recursive(_children: Array, _indent: String) -> String:
	# 存储生成的Markdown字符串
	var tree_md: String = ""
	# 遍历所有子节点
	for i in range(_children.size()):
		# 当前节点
		var item = _children[i]
		# 判断是否是当前层级的最后一个节点
		var is_last = (i == _children.size() - 1)
		# 根据是否是最后一个节点选择不同的前缀
		var prefix: String = "└─ " if is_last else "├─ "
		# 添加缩进、前缀和节点名称
		tree_md += _indent + prefix + item.name
		# 如果是目录
		if item.type == "directory":
			# 目录名称后添加斜杠和换行
			tree_md += "/\n"
			# 计算新的缩进，如果是最后一个节点，后续子节点的竖线应该断开
			var new_indent: String = _indent + ("   " if is_last else "│  ")
			# 递归调用处理子目录
			tree_md += _format_folder_tree_recursive(item.children, new_indent)
		# 如果是文件
		else:
			# 文件名称后直接换行
			tree_md += "\n"
	
	return tree_md


# 格式化场景树数据为Markdown字符串。
static func format_scene_tree(_scene_path: String, _tree_data: Dictionary) -> String:
	if _tree_data.is_empty(): return ""
	# 构建Markdown头部，包含场景文件名称
	var context_md: String = "Context for Scene: `%s`\n```\n" % _scene_path.get_file()
	context_md += "Scene Tree Structure:\n"
	# 递归格式化场景节点，初始缩进为空，且是根节点
	context_md += _format_scene_node_recursive(_tree_data, "", true)
	context_md += "```\n" # 结束代码块
	return context_md


# 递归函数，用于将场景节点数据格式化为Markdown字符串。
# 根据层级和节点信息添加缩进、连接符、节点名称、类名和脚本路径。
static func _format_scene_node_recursive(_node_data: Dictionary, _indent: String, _is_last: bool) -> String:
	var line: String = _indent
	# 如果不是根节点，添加连接符
	if not _indent.is_empty():
		line += "└─ " if _is_last else "├─ "
	# 添加节点名称和类名
	line += "%s (%s)" % [_node_data.name, _node_data.class]
	
	if _node_data.script:
		line += " [script: `%s`]" % _node_data.script
	
	var tree_md: String = line + "\n"
	# 计算新的缩进，如果是最后一个节点，后续子节点的竖线应该断开
	var new_indent: String = _indent + ("   " if _is_last else "│  ")
	var children = _node_data.children
	
	for i in range(children.size()):
		tree_md += _format_scene_node_recursive(children[i], new_indent, i == children.size() - 1)
	
	return tree_md


# 格式化脚本内容数据为Markdown字符串。
static func format_script_content(_script_data: Dictionary) -> String:
	if _script_data.is_empty(): return ""
	
	var context_md: String = "Content for Script: `%s`\n" % _script_data.path.get_file()
	context_md += "```gdscript\n"
	context_md += _script_data.source_code
	context_md += "\n```\n"
	return context_md


# 格式化通用文本文件内容为Markdown字符串。
# 会根据文件扩展名自动匹配Markdown代码块的语言标识符。
static func format_text_content(_text_data: Dictionary) -> String:
	if _text_data.is_empty():
		return ""
	
	var file_name: String = _text_data.path.get_file()
	var extension: String = _text_data.path.get_extension().to_lower()
	
	# 根据文件类型选择合适的语言标识符，增强可读性
	var lang_tag = ""
	match extension:
		"json":
			lang_tag = "json"
		"md", "markdown":
			lang_tag = "markdown"
		"cfg", "ini":
			lang_tag = "ini"
		"txt":
			lang_tag = "text"
	
	var context_md: String = "Content for File: `%s`\n" % file_name
	context_md += "```%s\n" % lang_tag
	context_md += _text_data.content
	context_md += "\n```\n"
	return context_md


# 格式化图片元数据为Markdown字符串。
static func format_image_metadata(_image_data: Dictionary) -> String:
	if _image_data.is_empty():
		return ""
	
	var file_name: String = _image_data.path.get_file()
	var formatted_size: String = _format_bytes(_image_data.file_size_bytes)
	var context_md: String = "Context for Image: `%s`\n\n" % file_name
	context_md += "*   **Path**: `%s`\n" % _image_data.path
	context_md += "*   **Dimensions**: %d x %d pixels\n" % [_image_data.width, _image_data.height]
	context_md += "*   **File Size**: %s\n" % formatted_size
	return context_md


#==============================================================================
# ## 内部函数 ##
#==============================================================================

# 为了不破坏公共函数需要设置成内部静态辅助函数
# 将字节数格式化为KB, MB等易读单位
static func _format_bytes(_bytes: int) -> String:
	if _bytes < 1024:
		return "%d B" % _bytes
	elif _bytes < 1024 * 1024:
		return "%.2f KB" % (_bytes / 1024.0)
	elif _bytes < 1024 * 1024 * 1024:
		return "%.2f MB" % (_bytes / (1024.0 * 1024.0))
	else:
		return "%.2f GB" % (_bytes / (1024.0 * 1024.0 * 1024.0))


# 为了不破坏公共函数需要设置成内部静态辅助函数
# 根据扩展名返回对应的 MIME 类型
static func _get_mime_type(_extension: String) -> String:
	match _extension:
		"png": return "image/png"
		"jpg", "jpeg": return "image/jpeg"
		"svg": return "image/svg+xml"
		_: return ""
