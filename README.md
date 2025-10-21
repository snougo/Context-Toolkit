# Context Toolkit
[English](https://github.com/snougo/Context-Toolkit/blob/main/README.md)/[中文](https://github.com/snougo/Context-Toolkit/blob/main/README_zh-CN.md)

## About Context Toolkit
Context Toolkit is a convenient one-click Godot plugin that helps you get structured context information about your Godot project, saving you the trouble of manually building it during chats with LLMs.

## How to Install and Enable
1.  Download Context Toolkit plugin.
2.  Drag the downloaded plugin folder into the `addons` folder within the editor's file system.
3.  Open Project Settings, switch to the Plugins tab, find and enable Context Toolkit.

## How to Use

### Direct Usage
Once the plugin is enabled, you will see a new "Context Toolkit" button in the Godot editor's bottom panel. Click it to enter the plugin's interface.

The plugin's default Workspace points to its own folder. Click the "Select Workspace" button to customize it to the folder you need.

#### Feature Button Descriptions
-   **Get Folder Structure**: Get the directory tree structure of the current workspace (Markdown format).
-   **Get Scene Tree**: Get the node tree structure of `.tscn` scenes in the current workspace (Markdown format).
-   **Get Script Code**: Get the source code content of `.gd` scripts in the current workspace (Markdown format).
-   **Select Workspace**: Switch the workspace path.

> Note: When you set the Workspace to the project root directory `res://`, the plugin can only retrieve folder structure information. Scene tree and script code information will not be available. If you attempt to retrieve them, you will see the error message `[ERROR: Unknown error occurred.]`

> Note: When used with the Godot AI Chat plugin, you should also not let the LLM directly retrieve scene tree and script code information from the project root directory.

### API Interface Calls
In addition to providing a UI interface, the plugin also supports programmatic context extraction by calling its custom class `ContextProvider` in GDScript scripts. Currently, its main application scenario is to provide enhanced functionality for the Godot AI Chat plugin.

#### Usage Example
```gdscript
# 1. Get the ContextProvider instance provided by the plugin (requires plugin API)
var provider = get_context_provider() # Obtained from Godot AI Chat or other plugins

# 2. Call interface methods to return structured data or Markdown strings
var result = provider.get_folder_structure_as_markdown("res://addons/context_toolkit/")

# 3. Process the result
if result.success:
    print(result.data) # Markdown formatted string
else:
    print("Error: " + result.get("error", "Unknown error"))
```
