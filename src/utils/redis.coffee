_       = require 'underscore'
async   = require 'async'
redis   = require 'redis'
moment  = require 'moment'

REDIS_PORT      = process.env.REDIS_PORT || 6379
REDIS_HOST      = process.env.REDIS_HOST || 'redis'

REDIS_KEY_PREFIX = ""
KEY_SOCKET_IDS = 'socket_ids'

module.exports = (config)->
  socket = config.util 'socket'

  create_client: -> redis.createClient REDIS_PORT, REDIS_HOST
  client: redis.createClient REDIS_PORT, REDIS_HOST
  key: (text)-> "#{REDIS_KEY_PREFIX}#{text}"
  k: (text)-> @key text

  set_user_info: (a_user_info)->
    me = @ 
    to_session_id: (a_session_id, done)->
      me.client.multi()
        .hmset (me.key "session_id:#{a_session_id}:user_info"), a_user_info
        .exec done

  add_session_id: (a_session_id)->
    me = @
    to_email: (a_email, done)->
      me.client.multi()
        .set  me.key("session_id:#{a_session_id}:email"), a_email
        .sadd me.key("email:#{a_email}:session_ids"), a_session_id
        .exec done

  add_socket: (a_socket)->
    me = @
    to_session_id: (a_session_id, done)->
      me.client.multi()
        .set  me.key("socket_id:#{a_socket.id}:session_id"), a_session_id
        .sadd me.key("session_id:#{a_session_id}:#{KEY_SOCKET_IDS}"), a_socket.id
        .exec done

    to_log_listener: (callback)->
      key = me.key "room:log_listener:socket_ids"
      async.waterfall [
        (next)-> me.__clear_socket_ids key, next
      , (next)-> me.client.sadd key, a_socket.id, next
      ], (e)-> callback e if _.isFunction callback

    to_log_room: (a_room, callback)->
      key = me.key "log_room:#{a_room}:socket_ids"
      async.waterfall [
        (next)-> me.__clear_socket_ids key, next
      , (next)-> me.client.sadd key, a_socket.id, next
      ], (e)-> callback e if _.isFunction callback      

  log_room: (a_room_name)->
    me = @
    #key = "room:log_listener"
    key = me.key "log_room:#{a_room_name}"
    get_sockets: (callback)->
      key = me.key "#{key}:socket_ids"
      me.client.smembers key, callback

    clear_socket: (callback)-> 
      key = me.key "#{key}:socket_ids"
      me.__clear_socket_ids key, callback

    count: (callback)->
      key = me.key "#{key}:socket_ids"
      me.client.scard key, callback

    publish: (a_msg, callback)->
      key = me.key "#{key}:socket_ids"
      async.waterfall [
        (next)-> 
          me.__clear_socket_ids key, next

      , (next)-> 
          me.client.smembers key, next

      , (socket_ids, next)->
          if _.isObject a_msg
            _.extend a_msg, datetime: moment(new Date()).format 'YYYY-MM-DD HH:mm:ss SSS'
          
          me.publish socket_ids, a_msg, next

      ], (err)-> 
        
        callback err if _.isFunction callback
      
  from: (a_name)->
    me = @
    key = "#{a_name}"

  from_socket: (a_socket)->
    me = @
    key = "socket_id:#{a_socket.id}"
    get_session_id: (callback)-> 
      key = me.key "#{key}:session_id"
      me.client.get key, callback

  from_session_id: (a_session_id)->
    me = @
    key = "session_id:#{a_session_id}"
    clear_socket: (done)->
      key = me.key "#{key}:#{KEY_SOCKET_IDS}"
      async.waterfall [
        (next)-> me.__clear_socket_ids key, next
      , (next)-> me.client.smembers key, next
      ], done

    get_sockets: (done)-> @clear_socket done
    get_email: (callback)->
      key = me.key "#{key}:email"
      me.client.get key, callback 

    get_user_info: (callback)->
      key = me.key "#{key}:user_info"
      me.client.hgetall key, callback
      
  __clear_socket_ids: (key, done)->
    unless _.last(key.split ":") == "#{KEY_SOCKET_IDS}" 
      return done() 

    all_connected = socket.get_all_connected_ids()
    if all_connected.length <= 0
      return @client.del key, (err)-> done err

    key_tmp = @key "_#{KEY_SOCKET_IDS}"

    @client.multi()
      .del key_tmp
      .sadd key_tmp, _.map(all_connected, (e)-> "/##{e}")
      .sinterstore key, key, key_tmp
      .del key_tmp
      .exec (err, results)-> 
        done err
    
  __clear_session_ids: (key, done)->
    me = @
    if _.last(key.split ":") == "session_ids" 
      
      async.waterfall [
        (next)-> me.client.smembers key, next
      , (session_ids, next)->

          async.map session_ids, (session_id, done)->
            k = me.k "session_id:#{session_id}:#{KEY_SOCKET_IDS}"

            async.waterfall [
              (next)-> me.__clear_socket_ids k, next
              (next)-> me.client.scard k, next
            ], (e, total)-> 
              done null, (if total > 0 then session_id else null)

          , (e, results)->
            if e 
              next e
            else
              ret = _.filter results, (m)-> m
              next e, ret

      ], done 

    else 
      done null

  publish_to_user: (a_email, a_message, callback)->

    me = @
    key = @k "email:#{a_email}:session_ids"

    async.waterfall [
      (next)-> me.__clear_session_ids key, next
      (session_ids, next)->
        async.map session_ids, (session_id, done)->

          async.waterfall [
            (next)->
              me.from_session_id(session_id).get_sockets next

          , (socket_ids, next)->
            me.publish socket_ids, a_message

          ], done

        , next

    ], callback

  publish: (socket_id, a_message, callback)->
 
    me = @
    channels = []
    if _.isString socket_id
      channels.push socket_id

    else if _.isArray socket_id
      channels = socket_id

    else
      m = "Invalid channel name (expect Object or Array)"
      if _.isFunction callback
        return callback m
      else
        return console.log m

    message = "{}"
    if (_.isObject a_message) or (_.isArray a_message) or (_.isBoolean a_message)
      message = JSON.stringify a_message
 
    else
      m = "Invalid message type (expect Object, Array, Boolean)!"
      if _.isFunction callback
        return callback m

      else
        return console.log m
    
    async.map channels, (c, done)->
      me.client.publish c, message, done
    , (e)->
 
      callback e if _.isFunction callback
        