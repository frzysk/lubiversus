(for SyncManager)

video 2:
	// For all peers
	.add_peer()
	.remove_peer()
	.clear_peers() // ~ .remove_peer()?
	// (only if get_tree().is_network_server()): start 
	.start()
	// stop
	.stop()
	// signals?
	.connect({signal}, {function})
		{signal}:
			-	"sync_started"
			-	"sync_stopped"
			-	"sync_lost"
			-	"sync_regained"
			-	"sync_error"

	A node participating in the rollback is in group "network_sync":
	To override:
	-	`_get_local_input()`
	-	`_network_process(input)` (replaces `_physics_process()`?)
		must be deterministic!!
	-	`_save_state()`
	-	`_load_state()`
	Functions:
	-	`.set_network_master(peer_id)`

	constant fps?
