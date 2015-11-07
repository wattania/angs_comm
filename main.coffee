SOCKET_PORT = 3000

config = require("./config/config")()
web = config.util('web').create().listen SOCKET_PORT
config.util('socket').create web