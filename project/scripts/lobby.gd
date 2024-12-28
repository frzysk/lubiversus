extends Node
## Singleton qui contient les informations du lobby auquel ce client est actuellement connecté.
## Les informations du lobby sont automatiquement partagées entre tous les clients.
## Autoload sous le nom Lobby.

## (readonly) true si ce client est actuellement connecté à un lobby.
var connected: bool:
	get: return _connected
	set(_v): pass
var _connected := false

## Emis quand le lobby a été modifié par un peer distant.
signal modified

## Représente un client connecté au lobby.
class Player:
	## Etat du Player.
	enum State {
		## Le Player représente ce client.
		ME,
		## Ce client connait le Player.peer de ce Player.
		CONNECTED,
		## Ce client ne connait pas encore le Player.peer de ce Player.
		CONNECTING,
	}
	
	## OID du Player.
	var oid: String
	## Etat du Player, voir Player.State.
	var state: Player.State
	## Peer id du client. Défini seulement si Player.state est CONNECTED, sinon null.
	var peer: Variant

	func _init(oid_: String, state_: Player.State, peer_: Variant = null) -> void:
		assert((state_ == Player.State.CONNECTED and peer_ is int)
			or (state_ != Player.State.CONNECTED and peer_ == null))
		self.oid = oid_
		self.state = state_
		self.peer = peer_
		if state_ == Player.State.CONNECTING:
			(func():
				self.peer = await Lobby._who_has_this_oid_and_wait(oid_)
				self.state = Player.State.CONNECTED
				Lobby.modified.emit()
			).call()

	## Retourne une représentation du Player qui peut être partagée via une fonction rpc
	## (on peut pas juste envoyer un Player via les arguments des fonctions rpc).
	func serialize() -> Dictionary:
		return {"oid": self.oid}

	## Crée un Player correspondant à la représentation donnée.
	## 'dict' doit être une valeur retournée par Player.serialize().
	## Noray.oid et Lobby.players doivent être définis.
	static func deserialize(dict: Dictionary) -> Player:
		var state_: Player.State
		var peer_: Variant = null
		if dict["oid"] == Noray.oid:
			state_ = Player.State.ME
		elif Lobby._get_player_from_oid(dict["oid"]) != null:
			peer_ = Lobby._get_player_from_oid(dict["oid"]).peer_
			state_ = Player.State.CONNECTED if peer_ != null else Player.State.CONNECTING
		else:
			state_ = Player.State.CONNECTING
		return Player.new(dict["oid"], state_, peer_)

## Liste des joueurs actuellement connectés au lobby.
var players: Array[Player] = []

## Retourne le Player correspondant à l'OID donné dans la liste des joueurs du lobby.
## null si aucun Player n'a cet OID.
func _get_player_from_oid(oid: String) -> Variant:
	for player in players:
		if player.oid == oid:
			return player
	return null

## Retourne une représentation du Lobby qui peut être partagée via une fonction rpc
## (on peut pas juste envoyer un Lobby via les arguments des fonctions rpc).
func _serialize() -> Dictionary:
	var serialized_players: Array[Dictionary] = []
	for player in players:
		serialized_players.push_back(player.serialize())
	return {"players": serialized_players}

## Redéfinit self selon la représentation du lobby donné.
## 'dict' doit être une valeur retournée par _serialize().
func _deserialize(dict: Dictionary) -> void:
	var _players: Array[Player] = []
	for player in dict["players"]:
		_players.push_back(Player.deserialize(player))
	players = _players

## Se déconnecte du lobby. Ne fait rien si ce client n'est pas connecté à un lobby.
func disconnect_from_lobby() -> void:
	_connected = false
	players = []

## Demande au peer de se connecter à son lobby.
## 'await' permet d'attendre de bien avoir été connecté au lobby.
## multiplayer.get_peers() doit avoir un et un seul peer.
func join_peer_lobby_and_wait() -> void:
	var peers := multiplayer.get_peers()
	assert(peers.size() == 1)
	_join_lobby.rpc_id(peers[0], Noray.oid)
	await _lobby_joined

## Crée un lobby avec seulement toi dedans :D
func create_lobby() -> void:
	players = [Player.new(Noray.oid, Player.State.ME)]
	_connected = true

## Emis quand le client a joint un lobby via join_peer_lobby_and_wait().
signal _lobby_joined

## Demande à un peer de se connecter à son lobby.
## 'oid' est l'OID de celui qui fait la demande.
@rpc("any_peer", "call_remote", "reliable")
func _join_lobby(oid: String) -> void:
	print("///////// _join_lobby() called from " + str(multiplayer.get_remote_sender_id()))
	for player in players:
		_add_player.rpc(oid)
	players.push_back(Player.new(oid, Player.State.CONNECTED, multiplayer.get_remote_sender_id()))
	_join_lobby_accept.rpc_id(multiplayer.get_remote_sender_id(), _serialize())
	modified.emit()

## Confirme au peer qu'il a été connecté au lobby, et lui envoie les informations du lobby.
@rpc("any_peer", "call_remote", "reliable")
func _join_lobby_accept(lobby_data: Dictionary) -> void:
	print("///////// _join_lobby_accept() called from " + str(multiplayer.get_remote_sender_id()))
	_deserialize(lobby_data)
	connected = true
	_lobby_joined.emit()

## Signale aux peers qu'il y a un-e nouvelleau joueurse \('o')/
## 'oid' est l'OID du nouveau joueur.
@rpc("any_peer", "call_remote", "reliable")
func _add_player(oid: String) -> void:
	print("///////// _add_player() called from " + str(multiplayer.get_remote_sender_id()))
	if _get_player_from_oid(oid) != null:
		return
	players.push_back(Player.new(oid, Player.State.CONNECTING))
	modified.emit()

## Signale aux peers que tu te déconnectes du lobby.
@rpc("any_peer", "call_remote", "reliable")
func _remove_me(oid: String) -> void:
	print("///////// _remove_me() called from " + str(multiplayer.get_remote_sender_id()))
	for i in range(players.size()):
		if players[i].oid == oid:
			players.remove_at(i)
	modified.emit()


## Envoie un message à tout le monde pour savoir qui a l'OID spécifié, et retourne le peer ID.
func _who_has_this_oid_and_wait(oid: String) -> int:
	_who_has_this_oid.rpc(oid)
	var peer = {"value": null}
	_now_i_know_that_this_peer_has_this_oid.connect(
		func(peer_id: int, oid_: String):
			if oid == oid_:
				peer["value"] = peer_id
	)
	while peer["value"] == null:
		await get_tree().process_frame
	return peer["value"]

signal _now_i_know_that_this_peer_has_this_oid(peer_id: int, oid: String)

## Envoie un message aux peers pour savoir qui a l'OID spécifié.
@rpc("any_peer", "call_remote", "reliable")
func _who_has_this_oid(oid: String) -> void:
	print("///////// _who_has_this_oid() called from " + str(multiplayer.get_remote_sender_id()))
	if oid == Noray.oid:
		_i_have_this_oid.rpc_id(multiplayer.get_remote_sender_id(), oid)

## Envoie un message au peer pour l'informer que c'est toi qu'a cet OID.
@rpc("any_peer", "call_remote", "reliable")
func _i_have_this_oid(oid: String) -> void:
	print("///////// _i_have_this_oid() called from " + str(multiplayer.get_remote_sender_id()))
	_now_i_know_that_this_peer_has_this_oid.emit(multiplayer.get_remote_sender_id(), oid)
