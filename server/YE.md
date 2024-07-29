# STUN
p2p: UDP par un NAT. En général bon sur des wifi domestiques
# TURN
p2p
# ICE
STUN > TURN
(Broker ICE: serveur qui établit la connexion)
# WebRTC
ICE + faux TCP avec UDP (retransmission des paquets perdus + réordonnage)
