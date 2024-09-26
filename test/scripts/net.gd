extends Node

var readyButton: bool = false
var readyPrompt: bool = false
var instanceName: String = "-"

const host = "tomfol.io"
const port = 8890

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
		var error: Error = await Network.create_server(host, port)
		if error != OK:
			printCool("ERROR 1-" + str(error))
			return
		printCool("SERVER READY! IOD: " + Network.iod)
	
	else:
		printCool("CLIENT MODE")
		printCool("Send OID")
		var oid: String = await waitPrompt()
		var error: Error = await Network.create_client(host, port, oid)
		if error != OK:
			printCool("Error 2-" + str(error))
			return
		printCool("CLIENT READY!")

@rpc("any_peer", "call_remote", "reliable")
func _rpc_message(txt: String) -> void:
	printCool("Received message: " + txt)

func send_message(txt: String) -> void:
	printCool("Broadcast message: " + txt)
	_rpc_message.rpc(txt)
