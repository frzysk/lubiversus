extends Node

# Run a game between the given players.
func run(players: Array[Lobby.Player]):
	var players_oids: Array = players.map(func(player: Lobby.Player) -> String: return player.oid)
	run_rpc.rpc(players_oids)

@rpc("any_peer", "call_local", "reliable")
func run_rpc(players_oids: Array): # Array[String]
	var players: Array[Lobby.Player]
	players.assign(players_oids.map(Lobby.get_player_from_oid))

	get_tree().change_scene_to_file("res://scenes/platform_example.tscn")
	while get_tree().current_scene == null:
		await get_tree().process_frame

	var avatars: Array[CharacterBody2D] = [
		get_tree().current_scene.get_node_or_null("Charles1"),
		get_tree().current_scene.get_node_or_null("Charles2"),
		get_tree().current_scene.get_node_or_null("Charles3"),
		get_tree().current_scene.get_node_or_null("Charles4")]
	for avatar in avatars.slice(players.size()):
		avatar.get_parent().remove_child(avatar)
	for i in range(players.size()):
		if players[i].state != Lobby.Player.State.ME:
			SyncManager.add_peer(players[i].peer)
		avatars[i].set_multiplayer_authority(players[i].peer)

	if multiplayer.is_server():
		await get_tree().create_timer(2.0).timeout
		SyncManager.start()
