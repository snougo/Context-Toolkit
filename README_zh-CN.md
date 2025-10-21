# Context Toolkit

## 关于Context Toolkit
Context Toolkit是一款方便的一键获取Godot项目结构化上下文信息的Godot插件，免去了和LLM聊天过程中手动构建结构化上下文信息的麻烦。

## 如何安装和启用
1. 下载插件Context Toolki。
2. 将下载后的插件文件夹拖入到编辑器文件系统中的addon文件夹中。
3. 打开Project Settings，切换到Plugins标签，找到并启用Context Toolkit。

## 如何使用

### 直接使用
当你启用插件后，会在Godot编辑器的底部面板看到新增的Context Toolkit按钮，点击进入插件使用界面。

插件默认的工作区（Workspace）指向插件自己的文件夹，点击Select Workspace按钮可以自定义指向你需要的文件夹。

#### 功能按钮说明
- **Get Folder Structure**：获取当前工作区的目录树结构（Markdown 格式）。
- **Get Scene Tree**：获取当前工作区中 `.tscn` 场景的节点树结构（Markdown 格式）。
- **Get Script Code**：获取当前工作区中 `.gd` 脚本的源码内容（Markdown 格式）。
- **Select Workspace**：切换工作区路径。

> 注意：当你将Workspace指向项目根目录res://时，插件只能获取文件夹结构信息，而场景树和脚本代码的结构信息将无法获取，强行点击获取的话，会看到错误提示`[ERROR: Unknown error occurred.]`

> 注意：当和插件Godot AI Chat一起使用时，同样不应该让LLM直接从项目根目录去获取场景树和脚本代码的结构信息。

### API接口调用
插件除了提供UI界面的使用，还支持通过插件自定义类ContextProvider在gdscript脚本中调用，实现**程序化上下文提取**，目前主要的应用场景是为Godot AI Chat插件提供功能增强。

#### 使用方式
```gdscript
# 1. 获取插件提供的 ContextProvider 实例（需通过插件 API）
var provider = get_context_provider() # 从 Godot AI Chat 或其他插件中获取

# 2. 调用接口方法，返回结构化数据或 Markdown 字符串
var result = provider.get_folder_structure_as_markdown("res://addons/context_toolkit/")

# 3. 处理结果
if result.success:
    print(result.data) # Markdown 格式字符串
else:
    print("Error: " + result.get("error", "Unknown error"))
```