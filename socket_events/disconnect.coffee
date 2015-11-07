module.exports = (socket, redis_subscribe, config)->
  exec: ()->
    console.log "Disconnect -", socket.id
    redis_subscribe.unsubscribe socket.id
    redis_subscribe.quit()