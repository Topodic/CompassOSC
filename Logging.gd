# A simple logging utility. Uses a fair few bitwise operations, recommend
# knowing what those are if you plan to edit this extensively (or are just
# curious, they're handy and neat).
extends Node

enum MessageLevel {
	INFO = 1, 
	DEBUG = 2,
	WARNING = 4,
	ERROR = 8,
	INCOMING = 16,
	OUTGOING = 32
}
var logging_level : MessageLevel = 0

func write(message : String, level : MessageLevel = MessageLevel.INFO):
	if !should_log(level):
		return
		
	var from : String = ""
	if EngineDebugger.is_active():
		# Fetches trace of caller for logging clarity.
		from = get_stack()[1]["source"]

		var split = from.split("/")
		from = split[split.size()-1]
		
	var level_str = level_to_string(level)

	var final_message = "[{level}] {from}: {message}".format({"level": level_str, "from": from, "message": message})
	if level == MessageLevel.WARNING or level == MessageLevel.ERROR:
		printerr(final_message)
	else:
		print(final_message)

func should_log(level : MessageLevel):
	return((logging_level & level) != 0)

func set_level(level : MessageLevel, enabled : bool):
	if enabled:
		logging_level |= level
	else:
		logging_level = logging_level & ~level

func level_to_string(level : MessageLevel):
	var string = null
	match level:
		MessageLevel.INFO:
			string = "INFO"
		MessageLevel.DEBUG:
			string = "DEBUG"
		MessageLevel.WARNING:
			string = "WARNING"
		MessageLevel.ERROR:
			string = "ERROR"
		MessageLevel.INCOMING:
			string = "INCOMING"
		MessageLevel.OUTGOING:
			string = "OUTGOING"
	return string
