module.exports = (socket, redis_subscribe, config)->
  exec: (a, fn, info)-> 
    console.log "-test exec -", socket.id
    console.log info
    fn success: true