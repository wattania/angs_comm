module.exports = (socket, redis_socket_subscribe, config)->
  exec: (message)->
    console.log "-socket message-"
    socket.json.send message