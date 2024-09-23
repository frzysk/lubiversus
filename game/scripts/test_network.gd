extends Control


enum _States {
	OFFLINE,
	ONLINE,
}
var _state := _States.OFFLINE
var _peer: ENetMultiplayerPeer = null

# Afficher un message, éventuellement de la couleur spécifiée.
# /!\ Ne fait pas automatiquement de retour à la ligne.
func print_logs(msg: String, color: String = "") -> void:
	var logs: RichTextLabel = get_node("logs")
	msg = msg.replace("[", "[lb]")
	if (color != ""):
		logs.append_text(
			str("[color=", color, "]", msg, "[/color]"))
	else:
		logs.append_text(msg)

func _create_server(port: int) -> void:

func _create_client(address: String, port: int) -> void:

# Appelée quand l'utilisateur a écrit quelque chose.
func _message_from_user(msg: String) -> void:
	print_logs(msg, "yellow")
	print_logs("\n")
	if _state == _States.OFFLINE:
		var argv: PackedStringArray = msg.split(" ") # c'est à cause du C
		if argv.size() == 0:
			return
		var command: String = argv[0]
		
		if command == "server":
			if argv.size() != 2:
				print_logs("syntaxe: server <PORT>\n")
				return
			if not argv[1].is_valid_int():
				print_logs("ça c'est pas un nombre\n")
			var port := int(argv[1])
			_create_server(port)
			_state = _States.ONLINE
			print_logs("ok c'est bon normalement???")
		
		elif command == "client":
			if argv.size() != 3:
				print_logs("syntaxe: client <IP_ADDRESS> <PORT>\n")
				return
			if not argv[2].is_valid_int():
				print_logs("le port ilé supposé être un nombre\n")
			var address: String = argv[1]
			var port := int(argv[2])
			_create_client(address, port)
			_state = _States.ONLINE
			print_logs("ok c'est bon normalement???")
		
		else:
			print_logs("ça veut rien dire\n")
	
	elif _state == _States.ONLINE:
		broadcast_message.rpc(msg)

	#msg = msg.strip_edges()
	#print_logs("t'as écrit: ")
	#print_logs(msg, "yellow")
	#print_logs("\n")

@rpc("any_peer", "call_local", "reliable", 0)
func broadcast_message(msg: String) -> void:
	print_logs("Reçu: ")
	print_logs(msg, "green")
	print_logs("\n")

func _run_state() -> void:
	if _state == _States.OFFLINE:
		print_logs(
				"utilise 'client <IP> <PORT>' pour te connecter à un serveur\n")
		print_logs(
				"utilise 'server <PORT>' pour créer un serveur\n")

func _ready() -> void:
	print_logs("salut c'est zy\n")
	_run_state()
