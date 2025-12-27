extends Object
class_name ContextProvider

# _context_cache 是一个字典，用于缓存已经获取并格式化好的上下文数据。
# 键通常是文件路径和修改时间的组合，值是包含数据或Markdown字符串的字典。
var _context_cache := {}

#==============================================================================
# ## 公共函数 ##
#==============================================================================

# --- Folder Structure Context ---
# 获取指定文件夹的结构原始数据（字典格式）。
func get_folder_structure_data(_folder_path: String) -> Dictionary:
	if _folder_path.is_empty() or not DirAccess.dir_exists_absolute(_folder_path):
		return {"success": false, "error": "Invalid or non-existent folder path provided."}
	
	var result: Dictionary = ContextDataBuilder.build_folder_structure_data(_folder_path)
	if result.is_empty():
		return {"success": false, "error": "Folder is empty or could not be read."}
	
	return {"success": true, "data": result}


# 获取指定文件夹的结构数据，并格式化为Markdown字符串。
func get_folder_structure_as_markdown(_folder_path: String) -> Dictionary:
	var data_result: Dictionary = get_folder_structure_data(_folder_path)
	if not data_result.success:
		return {"success": false, "data": "[ERROR: %s]" % data_result.get("error", "Unknown error getting script content.")}
	
	var markdown: String = MarkdownFormatter.format_folder_structure(data_result.data)
	return {"success": true, "data": markdown}


# --- Scene Tree Context ---
# 获取指定场景文件的节点树原始数据（字典格式）。
func get_scene_tree_data(_scene_path: String) -> Dictionary:
	var mod_time: int = FileAccess.get_modified_time(_scene_path)
	var cache_key: String = "%s_data_%s" % [_scene_path, mod_time]
	if _context_cache.has(cache_key): return _context_cache[cache_key]
	
	var result: Dictionary = ContextDataBuilder.build_scene_tree_data(_scene_path)
	if result.is_empty():
		return {"success": false, "error": "Failed to load or instantiate scene."}
	
	var success_result: Dictionary = {"success": true, "data": result}
	_context_cache[cache_key] = success_result
	return success_result


# 获取指定场景文件的节点树数据，并格式化为Markdown字符串。
func get_scene_tree_as_markdown(_scene_path: String) -> Dictionary:
	var mod_time: int = FileAccess.get_modified_time(_scene_path)
	var cache_key: String = "%s_md_%s" % [_scene_path, mod_time]
	if _context_cache.has(cache_key): return _context_cache[cache_key]
	
	var data_result: Dictionary = get_scene_tree_data(_scene_path)
	if not data_result.success:
		# 失败时，将错误信息放入 "data" 键，并确保它是字符串
		return {"success": false, "data": "[ERROR: %s]" % data_result.get("error", "Unknown error getting scene tree data.")}
	
	var markdown: String = MarkdownFormatter.format_scene_tree(_scene_path, data_result.data)
	var success_result: Dictionary = {"success": true, "data": markdown}
	_context_cache[cache_key] = success_result
	return success_result


# --- Script Content ---
# 获取指定脚本文件的内容原始数据（字典格式）。
func get_script_content_data(_script_path: String) -> Dictionary:
	var mod_time: int = FileAccess.get_modified_time(_script_path)
	var cache_key: String = "%s_data_%s" % [_script_path, mod_time]
	if _context_cache.has(cache_key): return _context_cache[cache_key]
	
	var result: Dictionary = ContextDataBuilder.build_script_content_data(_script_path)
	if result.is_empty():
		return {"success": false, "error": "Failed to load script or script is empty."}
	
	var success_result: Dictionary = {"success": true, "data": result}
	_context_cache[cache_key] = success_result
	return success_result


# 获取指定脚本文件的内容数据，并格式化为Markdown字符串。
func get_script_content_as_markdown(_script_path: String) -> Dictionary:
	var mod_time: int = FileAccess.get_modified_time(_script_path)
	var cache_key: String = "%s_md_%s" % [_script_path, mod_time]
	if _context_cache.has(cache_key): return _context_cache[cache_key]
	
	var data_result: Dictionary = get_script_content_data(_script_path)
	if not data_result.success:
		return {"success": false, "data": "[ERROR: %s]" % data_result.get("error", "Unknown error getting script content.")}
	
	var markdown: String = MarkdownFormatter.format_script_content(data_result.data)
	var success_result: Dictionary = {"success": true, "data": markdown}
	_context_cache[cache_key] = success_result
	return success_result


# --- Text Based File Content ---
# 获取指定通用文本文件的内容原始数据（字典格式）。
func get_text_content_data(_text_based_file_path: String) -> Dictionary:
	var mod_time: int = FileAccess.get_modified_time(_text_based_file_path)
	var cache_key: String = "%s_data_%s" % [_text_based_file_path, mod_time]
	if _context_cache.has(cache_key): return _context_cache[cache_key]
	
	var result: Dictionary = ContextDataBuilder.build_text_content_data(_text_based_file_path)
	if result.is_empty():
		return {"success": false, "error": "Failed to read file or file is empty."}
	
	var success_result: Dictionary = {"success": true, "data": result}
	_context_cache[cache_key] = success_result
	return success_result


# 获取指定通用文本文件的内容数据，并格式化为Markdown字符串。
func get_text_content_as_markdown(_text_based_file_path: String) -> Dictionary:
	var mod_time: int = FileAccess.get_modified_time(_text_based_file_path)
	var cache_key: String = "%s_md_%s" % [_text_based_file_path, mod_time]
	if _context_cache.has(cache_key): return _context_cache[cache_key]
	
	var data_result: Dictionary = get_text_content_data(_text_based_file_path)
	if not data_result.success:
		return {"success": false, "data": "[ERROR: %s]" % data_result.get("error", "Unknown error getting script content.")}
	
	var markdown: String = MarkdownFormatter.format_text_content(data_result.data)
	var success_result: Dictionary = {"success": true, "data": markdown}
	_context_cache[cache_key] = success_result
	return success_result


# --- Image Content ---
# 获取指定图片文件的元数据（字典格式）。
func get_image_metadata_data(_image_path: String) -> Dictionary:
	var mod_time: int = FileAccess.get_modified_time(_image_path)
	var cache_key: String = "%s_data_%s" % [_image_path, mod_time]
	if _context_cache.has(cache_key): return _context_cache[cache_key]
	
	var result: Dictionary = ContextDataBuilder.build_image_metadata_data(_image_path)
	if result.is_empty():
		return {"success": false, "error": "Failed to load image or unsupported file type."}
	
	var success_result: Dictionary = {"success": true, "data": result}
	_context_cache[cache_key] = success_result
	return success_result


# 获取指定图片文件的元数据，并格式化为Markdown字符串。
func get_image_metadata_as_markdown(_image_path: String) -> Dictionary:
	var mod_time: int = FileAccess.get_modified_time(_image_path)
	var cache_key: String = "%s_md_%s" % [_image_path, mod_time]
	if _context_cache.has(cache_key): return _context_cache[cache_key]
	
	var data_result: Dictionary = get_image_metadata_data(_image_path)
	if not data_result.success:
		return {"success": false, "data": "[ERROR: %s]" % data_result.get("error", "Unknown error getting script content.")}
	
	var markdown: String = MarkdownFormatter.format_image_metadata(data_result.data)
	var success_result: Dictionary = {"success": true, "data": markdown}
	_context_cache[cache_key] = success_result
	return success_result


# [新增] --- Search Files ---
# 根据关键词搜索文件，并返回格式化的Markdown列表。
# 默认搜索 .md 文件，但可以通过参数指定。
func search_files_as_markdown(_root_path: String, _keyword: String, _extension: String = ".md") -> Dictionary:
	# 简单的路径有效性检查
	if _root_path.is_empty() or not DirAccess.dir_exists_absolute(_root_path):
		return {"success": false, "error": "Invalid directory path: %s" % _root_path}
	
	# 调用 Scanner 进行搜索
	var results: Array = FileSystemScanner.scan_for_files_with_keyword(_root_path, _keyword, _extension)
	
	# 调用 Formatter 格式化结果
	var markdown: String = MarkdownFormatter.format_search_results(_keyword, _root_path, results)
	
	return {"success": true, "data": markdown}
