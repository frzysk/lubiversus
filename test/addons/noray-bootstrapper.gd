extends Node

#region VARIABLES

var _address: String = ""
var _host_oid: String = ""
var _force_relay: bool = false

## Set the address of the Noray server to use.
func set_address(value: String):
	_address = value

## Set the OID of the host to connect to.
func set_host_oid(value: String):
	_host_oid = value

## Set the force relay value. If true, doesn't even try NAT punchthrough.
func set_force_relay(value: bool):
	_force_relay = value

## Get the OID of this host.
func get_local_oid() -> String:
	return Noray.oid

enum Role { NONE, HOST, CLIENT }
var _role = Role.NONE

#endregion

#region PUBLIC FUNCTIONS

## Connect to a Noray server.
## Define the Noray server address with set_address() before calling this.
func connect_to_noray() -> Error:
	# Connect to noray
	var err = OK
	if _address.contains(":"):
		var parts = _address.split(":")
		var address_host = parts[0]
		var address_port = (parts[1] as String).to_int()
		err = await Noray.connect_to_host(address_host, address_port)
	else:
		err = await Noray.connect_to_host(_address)
	
	if err != OK:
		print("Failed to connect to Noray: %s" % error_string(err))
		return err
	
	# Get IDs
	Noray.register_host()
	await Noray.on_pid
	
	# Register remote address
	err = await Noray.register_remote()
	if err != OK:
		print("Failed to register remote address: %s" % error_string(err))
		return err
	
	# Our local port is a remote port to Noray, hence the weird naming
	print("Registered local port: %d" % Noray.local_port)
	return OK

## Disconnect from the Noray server.
func disconnect_from_noray() -> void:
	Noray.disconnect_from_host()

## Host a game server.
## Connect to a Noray server with connect_to_noray() before calling this.
func host() -> Error:
	if Noray.local_port <= 0:
		return ERR_UNCONFIGURED
	
	# Start host
	var err = OK
	var port = Noray.local_port
	print("Starting host on port %s" % port)
	
	var peer = ENetMultiplayerPeer.new()
	err = peer.create_server(port)
	if err != OK:
		print("Failed to listen on port %s: %s" % [port, error_string(err)])
		return err

	get_tree().get_multiplayer().multiplayer_peer = peer
	print("Listening on port %s" % port)
	
	# Wait for server to start
	while peer.get_connection_status() == MultiplayerPeer.CONNECTION_CONNECTING:
		await get_tree().process_frame
	
	if peer.get_connection_status() != MultiplayerPeer.CONNECTION_CONNECTED:
		OS.alert("Failed to start server!")
		return FAILED
	
	get_tree().get_multiplayer().server_relay = true
	
	_role = Role.HOST
	# NOTE: This is not needed when using NetworkEvents
	# However, this script also runs in multiplayer-simple where NetworkEvents
	# are assumed to be absent, hence starting NetworkTime manually
	#NetworkTime.start()

	return OK

## Connect to a game server.
## Connect to a Noray server with connect_to_noray() and set the host OID with
## with set_host_oid() before calling this.
func join() -> Error:
	_role = Role.CLIENT

	if _force_relay:
		return await Noray.connect_relay(_host_oid)
	else:
		return await Noray.connect_nat(_host_oid)

#endregion

#region EVENT FUNCTIONS

func _ready():
	Noray.on_connect_nat.connect(_handle_connect_nat)
	Noray.on_connect_relay.connect(_handle_connect_relay)

func _handle_connect_nat(address: String, port: int) -> Error:
	var err = await _handle_connect(address, port)

	# If client failed to connect over NAT, try again over relay
	if err != OK and _role != Role.HOST:
		print("NAT connect failed with reason %s, retrying with relay" % error_string(err))
		Noray.connect_relay(_host_oid)
		err = OK

	return err

func _handle_connect_relay(address: String, port: int) -> Error:
	return await _handle_connect(address, port)

func _handle_connect(address: String, port: int) -> Error:
	if not Noray.local_port:
		return ERR_UNCONFIGURED

	var err = OK
	
	if _role == Role.NONE:
		push_warning("Refusing connection, not running as client nor host")
		err = ERR_UNAVAILABLE
	
	if _role == Role.CLIENT:
		var udp = PacketPeerUDP.new()
		udp.bind(Noray.local_port)
		udp.set_dest_address(address, port)
		
		print("Attempting handshake with %s:%s" % [address, port])
		err = await PacketHandshake.over_packet_peer(udp)
		udp.close()
		
		if err != OK:
			if err == ERR_BUSY:
				print("Handshake to %s:%s succeeded partially, attempting connection anyway" % [address, port])
			else:
				print("Handshake to %s:%s failed: %s" % [address, port, error_string(err)])
				return err
		else:
			print("Handshake to %s:%s succeeded" % [address, port])

		# Connect
		var peer = ENetMultiplayerPeer.new()
		err = peer.create_client(address, port, 0, 0, 0, Noray.local_port)
		if err != OK:
			print("Failed to create client: %s" % error_string(err))
			return err

		get_tree().get_multiplayer().multiplayer_peer = peer
		
		# Wait for connection to succeed
		await Async.condition(
			func(): return peer.get_connection_status() != MultiplayerPeer.CONNECTION_CONNECTING
		)
			
		if peer.get_connection_status() != MultiplayerPeer.CONNECTION_CONNECTED:
			print("Failed to connect to %s:%s with status %s" % [address, port, peer.get_connection_status()])
			get_tree().get_multiplayer().multiplayer_peer = null
			return ERR_CANT_CONNECT
		
		# NOTE: This is not needed when using NetworkEvents
		# However, this script also runs in multiplayer-simple where NetworkEvents
		# are assumed to be absent, hence starting NetworkTime manually
		#NetworkTime.start()

	if _role == Role.HOST:
		# We should already have the connection configured, only thing to do is a handshake
		var peer = get_tree().get_multiplayer().multiplayer_peer as ENetMultiplayerPeer
		
		err = await PacketHandshake.over_enet(peer.host, address, port)
		
		if err != OK:
			print("Handshake to %s:%s failed: %s" % [address, port, error_string(err)])
			return err
		print("Handshake to %s:%s concluded" % [address, port])

	return err

#endregion
