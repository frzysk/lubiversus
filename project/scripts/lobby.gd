extends Node

class Player:
	var peer: MultiplayerPeer
	var peer_id: int:
		get: return self.peer.get_unique_id()
	func _init(peer_: PacketPeer) -> void:
		self.peer = peer_

var players: Array[Player] = []

func clean() -> void:
	players = []

func add_player(peer: MultiplayerPeer) -> void:
	players.push_back(Player.new(peer))

signal _players_received(players_: Array[Player])

func ask_authority() -> void:
	_ask_players_to_authority.rpc()
	players = await _players_received

@rpc("authority", "call_remote", "reliable")
func _ask_players_to_authority() -> void:
	_give_players_from_authority.rpc_id(multiplayer.get_remote_sender_id(), players)

@rpc("any_peer", "call_remote", "reliable")
func _give_players_from_authority(players_: Array[Player]) -> void:
	_players_received.emit(players_)
