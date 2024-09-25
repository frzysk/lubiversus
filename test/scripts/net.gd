extends Node

var readyButton: bool = false
var readyPrompt: bool = false

func printCool(txt: String) -> void:
	print("##### ", txt, " #####")

func waitPrompt() -> String:
	readyPrompt = true
	var txt: String = await get_node("LineEdit").text_submitted
	readyPrompt = false
	printCool("Prompted: [" + txt + "]")
	return txt

func _ready() -> void:
	var host = "tomfol.io"
	var port = 8890
	var err = OK

	err = await Noray.connect_to_host(host, port)
	if err != OK:
		printCool("Error 1-" + String(err))
		return

	Noray.register_host()
	await Noray.on_pid
	
	err = await Noray.register_remote()
	if err != OK:
		printCool("Error 2-" + String(err))
		return
	printCool("Noray.local_port: " + str(Noray.local_port))
	printCool("Noray.oid: " + String(Noray.oid))
	printCool("[Click on a button]")
	readyButton = true

func on_choice(is_server: bool) -> void:
	if not readyButton:
		return
	readyButton = false
	if is_server:
		printCool("SERVER MODE")
		printCool("OID: " + Noray.oid)
		var peer = ENetMultiplayerPeer.new()
		var error = peer.create_server(Noray.local_port)
		if error != OK:
			printCool("Error 3-" + str(error))
			return
		printCool("OK")
	else:
		printCool("CLIENT MODE")
		printCool("[Send OID]")
		var oid: String = await waitPrompt()
		# Connect using NAT punchthrough
		var error: Error = Noray.connect_nat(oid)
		if error != OK:
			printCool("Error 4-" + str(error))
			return
		printCool("yay!!")
		# Or connect using relay
		#Noray.connect_relay(oid)
