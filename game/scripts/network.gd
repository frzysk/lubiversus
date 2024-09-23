extends Node

#var host = "some.noray.host"
#var port = 8890

func register(host: String, port: int) -> Error:
	var err: Error = OK

	# Connect to noray
	err = await Noray.connect_to_host(host, port)
	if err != OK:
		return err # Failed to connect

	# Register host
	Noray.register_host()
	await Noray.on_pid

	# Register remote address
	# This is where noray will direct traffic
	err = await Noray.register_remote()
	if err != OK:
		return err # Failed to register
	return OK
