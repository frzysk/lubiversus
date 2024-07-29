extends Object
## Permet de communiquer avec les autres clients.
## 
## TODO docu

## TODO docu
func find(n: int):
	var upnp = UPNP.new()
	var discover_result = upnp.discover()
	
	if discover_result == UPNP.UPNP_RESULT_SUCCESS:
		if upnp.get_gateway() and upnp.get_gateway().is_valid_gateway():
			var map_result_udp = upnp.add_port_mapping(9999, 0, "godot_udp", "UDP")
			var map_result_tcp = upnp.add_port_mapping(9999, 0, "godot_tcp", "TCP")
			
			if not map_result_udp == UPNP.UPNP_RESULT_SUCCESS:
				upnp.add_port_mapping(9999, 0, "", "UDP")
			if not map_result_tcp == UPNP.UPNP_RESULT_SUCCESS:
				upnp.add_port_mapping(9999, 0, "", "TCP")

	var external_ip = upnp.query_external_address()

	upnp.delete_port_mapping(9999, "UDP")
	upnp.delete_port_mapping(9999, "TCP")
