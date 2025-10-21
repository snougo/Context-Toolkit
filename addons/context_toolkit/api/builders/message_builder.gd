extends RefCounted
class_name MessageBuilder


#==============================================================================
# ## 公共函数 ##
#==============================================================================

# 将用户新注入的上下文（如场景树、代码）与输入框中已有的文本进行组装。
# 这个类确保了上下文信息以一致且易于理解的方式添加到用户的输入中。
static func build_message(_existing_text: String, _new_context: String) -> String:
	var processed_existing_text = _existing_text.strip_edges() # 去除两端空白
	
	if processed_existing_text.is_empty():
		# 如果输入框为空，直接返回新的上下文内容。
		# 在上下文后添加两个换行符，为用户后续输入提供空间。
		return _new_context + "\n\n"
	else:
		# 如果输入框中已有内容，则使用一个清晰的Markdown分隔符 (---) 将现有文本与新的上下文拼接起来。
		# 这样可以明确区分不同的信息块。
		return processed_existing_text + "\n\n---\n\n" + _new_context
