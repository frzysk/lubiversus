# server
import socket

accept_connections = 2
port = ( int(input("port=") )

s = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
addrport = ('', port)
s.bind(addrport)
s.listen(accept_connections)
