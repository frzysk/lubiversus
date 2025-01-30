extends Node

var _noray_peer: StreamPeerTCP = StreamPeerTCP.new()
static var _logger: _NetfoxLogger = _NetfoxLogger.for_noray("OnlineConnection")
var _protocol: NorayProtocolHandler = NorayProtocolHandler.new()
var _oid: String
var _pid: String
## If is_relay == false, data is "{host}:{port}".
## If is_relay == true, data is "{port}".
signal _on_connect(is_relay: bool, data: String)

func register_to_noray_server(address: String, on_disconnected: Callable) -> Error:
	var err = OK

	# Si déjà connecté, se déconnecte
	if _noray_peer.get_status() != _noray_peer.Status.STATUS_NONE:
		_noray_peer.disconnect_from_host()
		_noray_peer.poll()
	if _noray_peer.get_status() != _noray_peer.Status.STATUS_NONE:
		await get_tree().process_frame
		_noray_peer.poll()

	# Parse 'address'
	var address_host: String
	var address_port: int
	if address.contains(":"):
		var parts = address.split(":")
		address_host = parts[0]
		address_port = (parts[1] as String).to_int()
	else:
		address_host = address
		address_port = 8890
	
	# Se connecte au serveur noray
	_logger.info("Trying to connect to noray at %s:%s", [address_host, address_port])
	# - Trouve l'IP
	var address_host_ipv4 = IP.resolve_hostname(address, IP.TYPE_IPV4)
	_logger.debug("Resolved noray host to %s", [address_host_ipv4])
	# - Se connecte à l'host
	err = _noray_peer.connect_to_host(address_host_ipv4, address_port)
	if err != Error.OK:
		return err
	# - Préparation
	_noray_peer.set_no_delay(true)
	_protocol.reset()
	# - await jusqu'à qu'on soit connecté
	while _noray_peer.get_status() < 2:
		_noray_peer.poll()
		await get_tree().process_frame
	if _noray_peer.get_status() == _noray_peer.STATUS_ERROR:
		_logger.error("Connection failed to noray at %s (%s:%s), connection status %s", [address_host, address_host_ipv4, address_port, _noray_peer.get_status()])
		_noray_peer.disconnect_from_host()
		return ERR_CONNECTION_ERROR
	_logger.info("Connected to noray at %s (%s:%s)", [address_host, address_host_ipv4, address_port])
	
	# Enregistrement sur le serveur noray
	_oid = ""
	_pid = ""
	Noray.register_host()
	err = _put_command("register-host")
	if err != OK:
		return err
	while _oid == "" or _pid == "":
		await get_tree().process_frame
	
	# Register remote address
	err = await Noray.register_remote()
	if err != OK:
		print("Failed to register remote address: %s" % error_string(err))
		return err
	
	# Our local port is a remote port to Noray, hence the weird naming
	print("Registered local port: %d" % Noray.local_port)
	
	(func():
		await Noray.on_disconnect_from_host
		on_disconnected.call()
	).call()
	
	return OK

func _put_command(command: String, data = null) -> Error:
	if _noray_peer.get_status() != _noray_peer.Status.STATUS_CONNECTED:
		return ERR_CONNECTION_ERROR
	if data != null:
		_noray_peer.put_data(("%s %s\n" % [command, data]).to_utf8_buffer())
	else:
		_noray_peer.put_data((command + "\n").to_utf8_buffer())
	return OK

func _handle_commands(command: String, data: String):
	if command == "set-oid":
		_oid = data
		_logger.debug("Receive OID: %s", [data])
	elif command == "set-pid":
		_pid = data
		_logger.debug("Receive PID: %s", [data])
	elif command == "connect":
		_logger.debug("Received connect command to %s", [data])
		_on_connect.emit(false, data)
	elif command == "connect-relay":
		var port = data.to_int()
		_logger.debug("Received connect relay command to port %s", [data])
		_on_connect.emit(true, data)
	else:
		_logger.trace("Received command %s %s", [command, data])
