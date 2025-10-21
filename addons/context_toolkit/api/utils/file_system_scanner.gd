class_name FileSystemScanner

# 默认要忽略的目录列表，这些目录在扫描时不会被遍历。
# 这样可以避免扫描不必要的系统或配置文件夹。
const DEFAULT_IGNORE_DIRS: Array = [".", "..", ".godot", ".vscode", "ai_chat_logs"]


# 负责扫描特定类型文件的核心函数。
# 接收一个路径、文件扩展名和可选的忽略目录列表。
static func scan_for_files(_path: String, _extension: String, _ignore_dirs: PackedStringArray = DEFAULT_IGNORE_DIRS) -> Array:
	var files: Array = []
	_recursive_scan_for_files(_path, _extension, files, _ignore_dirs)
	return files


# 内部递归函数，实际执行文件扫描。
# 遍历指定路径下的文件和子目录，如果文件扩展名匹配则添加到列表中。
static func _recursive_scan_for_files(_path: String, _extension: String, _files: Array, _ignore_dirs: PackedStringArray) -> void:
	var dir: DirAccess = DirAccess.open(_path)
	if dir:
		# 扫描当前目录下的文件
		for item in dir.get_files():
			if item.ends_with(_extension):
				_files.append(_path.path_join(item))
		# 扫描当前目录下的子目录
		for item in dir.get_directories():
			# --- 优化点: 使用可配置的忽略列表 ---
			if item in _ignore_dirs:
				continue
			_recursive_scan_for_files(_path.path_join(item), _extension, _files, _ignore_dirs)


# 负责扫描所有文件夹的核心函数。
# 接收一个路径和可选的忽略目录列表。
static func scan_for_folders(_path: String, _ignore_dirs: PackedStringArray = DEFAULT_IGNORE_DIRS) -> Array:
	var folders: Array = []
	_recursive_scan_for_folders(_path, folders, _ignore_dirs)
	return folders


# 内部递归函数，实际执行文件夹扫描。
# 遍历指定路径下的子目录，并将其添加到列表中。
static func _recursive_scan_for_folders(_path: String, _folders: Array, _ignore_dirs: PackedStringArray):
	var dir: DirAccess = DirAccess.open(_path)
	if dir:
		for item in dir.get_directories():
			# --- 优化点: 使用可配置的忽略列表 ---
			if item in _ignore_dirs:
				continue
			var full_path = _path.path_join(item)
			_folders.append(full_path)
			_recursive_scan_for_folders(full_path, _folders, _ignore_dirs)
