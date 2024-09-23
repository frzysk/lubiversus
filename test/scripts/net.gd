extends Node

func _ready() -> void:
	var host = "some.noray.host"
	var port = 8890
	var err = OK

	# Connect to noray
	err = await Noray.connect_to_host(host, port)
	if err != OK:
		print("Error 1-", err) # Failed to connect

	# Register host
	Noray.register_host()
	await Noray.on_pid

	# Register remote address
	# This is where noray will direct traffic
	err = await Noray.register_remote()
	if err != OK:
		print("Error 2-", err) # Failed to register
	print("done :)")
