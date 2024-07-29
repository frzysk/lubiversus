# **x Networking**

## High-level multiplayer

### High-level vs low-level API

High-level is based on **x SceneTree**

Cool links:
- [x Gaffer On Games](https://gafferongames.com/categories/game-networking/)
- [x networking models in games](https://gafferongames.com/post/what_every_programmer_needs_to_know_about_game_networking/)

### Mid-level abstraction

**x MultiplayerPeer** is mid-level whatever that means. It's not meant to be created directly.
- **x ENetMultiplayerPeer**
- **x WebRTCMultiplayerPeer**
- **x WebSocketPeer**

### Initializing the network

`multiplayer` == **x `get_tree().get_multiplayer()`**
- Created a MultiplayerPeer
- Initialized (as a server or a client)
- Passed to `multiplayer.multiplayer_peer`
- Terminate with `multiplayer.multiplayer_peer = null`

### Managing connections

The ID of a server is always 1, the ID of a client is any positive integer.
