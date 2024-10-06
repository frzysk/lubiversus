extends Node

var readyButton: bool = false
var readyPrompt: bool = false
var instanceName: String = "-"
var broadcastingActive: bool = false

const norayserver = "tomfol.io:8890"

##### UTILS #####
func printCool(txt: String) -> void:
	print("\t", instanceName, ":\t", txt)

func waitPrompt() -> String:
	readyPrompt = true
	var txt: String = await get_node("LineEdit").text_submitted
	readyPrompt = false
	printCool("Prompted: [" + txt + "]")
	return txt

##### EVENTS #####
func _ready() -> void:
	printCool("Set name")
	instanceName = await waitPrompt()
	printCool("Click on a button")
	readyButton = true

func on_choice(is_server: bool) -> void:
	if not readyButton:
		return
	readyButton = false
	
	if is_server:
		printCool("SERVER MODE")
		Online.set_address(norayserver)
		var error: Error = await Online.connect_to_noray()
		if error != OK:
			printCool("ERROR 1-" + str(error))
			return
		error = await Online.host()
		if error != OK:
			printCool("ERROR 2-" + str(error))
			return
		printCool("Connected!")
		printCool("server oid: " + Online.get_local_oid())
		broadcastingActive = true

	else:
		printCool("CLIENT MODE")
		printCool("Send OID")
		var oid: String = await waitPrompt()
		Online.set_address(norayserver)
		var error: Error = await Online.connect_to_noray()
		if error != OK:
			printCool("Error 3-" + str(error))
			return
		Online.set_host_oid(oid)
		error = await Online.join()
		if error != OK:
			printCool("Error 4-" + str(error))
			return
		printCool("Connected!")
		broadcastingActive = true

@rpc("any_peer", "call_remote", "reliable")
func _rpc_message(txt: String) -> void:
	printCool("Received message: " + txt)

func send_message(txt: String) -> void:
	if not broadcastingActive:
		return
	printCool("Broadcast message: " + txt)
	_rpc_message.rpc(txt)
