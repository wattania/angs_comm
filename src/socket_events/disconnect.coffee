module.exports = (socket, redis_subscribe, config)->
  exec: ()->
    redis_subscribe.unsubscribe socket.id
    redis_subscribe.quit()