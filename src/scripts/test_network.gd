extends Control

func send_message(msg: String):
	msg = msg.replace("[", "[lb]")
	get_node("logs").append_bbcode(str("[color=yellow]", msg, "[/color]\n"))
