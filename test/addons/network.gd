extends Node

var iod: String:
	get: return _oid

var peer: ENetMultiplayerPeer:
	get: return _peer

var connected: bool:
	get: return _connected

func create_server(host: String, port: int) -> Error:
	## connection init
	var error: Error = await _connection_init(host, port)
	if error != OK:
		return error
	## create peer
	_peer = ENetMultiplayerPeer.new()
	## create peer
	error = _peer.create_server(Noray.local_port)
	if error != OK:
		return error
	## success
	_connected = true
	return OK

func create_client(host: String, port: int, oid: String) -> Error:
	## connection init
	var error: Error = await _connection_init(host, port)
	if error != OK:
		return error
	## connect using NAT punchthrough
	error = Noray.connect_nat(oid)
	if error != OK:
		## connect using relay
		return error
	## create peer
	_peer = ENetMultiplayerPeer.new()
	error = _peer.create_client(host, port, 0, 0, 0, Noray.local_port)
	if error != OK:
		return error
	## success
	_connected = true
	return OK


##### PRIVATE #####

var _local_port: int = 0
var _oid: String = ""
var _peer: ENetMultiplayerPeer = null
var _connected: bool = false

func _connection_init(host: String, port: int) -> Error:
	if _connected:
		return 1
	## connect to host
	var error: Error = await Noray.connect_to_host(host, port)
	if error != OK:
		return error
	## register host
	Noray.register_host()
	await Noray.on_pid
	## register remote
	error = await Noray.register_remote()
	if error != OK:
		return error
	## success
	_local_port = Noray.local_port
	_oid = Noray.oid
	return OK
