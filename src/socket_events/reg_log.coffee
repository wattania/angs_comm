module.exports = (socket, redis_subscribe, config)->
  redis = config.util 'redis'
  exec: (callback)-> 
    redis.from_socket(socket).add_to_log_listener callback