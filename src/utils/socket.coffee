socketio    = require 'socket.io'

EXPRESS_SID_KEY = process.env.EXPRESS_SID_KEY

fs          = require 'fs'
_           = require 'underscore'
async       = require 'async'
path        = require "path"

module.exports = (config, PORT)->
  file_util = config.util 'file'

  get_io: ()-> @_io
  get_all_connected_ids: ()-> _.keys @get_io().eio.clients
  create: (web_req, a_opts)-> 

    opts = {}
    opts = a_opts if _.isObject a_opts

    me = @

    oauth2  = config.util 'oauth'
    redis   = config.util 'redis'

    @_io = socketio.listen web_req unless @_io
    @_io 

    ####################
    @_io.use (socket, next)->
      request = socket.request

      unless request.headers.cookie
        return next(new Error('No cookie transmitted.'))

      me.get_session_id socket, (err, session_id)->
        #config.get_session_id_from_socket socket, (err, session_id)->
        if err then next err else

          web_req.session_redis_store.load session_id, (err, session)->
            if err
              return next err

            else if not session
              return next new Error 'Session cannot be found/loaded'

            else if not (_.isObject session.token)
              return next new Error 'Session Unauthorized.'

            else
              # If you want, you can attach the session to the handshake data, so you can use it again later
              # You can access it later with "socket.request.session" and "socket.request.sessionId"
              
              async.waterfall [
                (next)-> oauth2.verify_token session.token.access_token, next
              , (decode, next)->
                
                redis.add_socket(socket).to_session_id session_id, next
                #request.session = session
                #request.sessionId = session_id
                ###
                redis.client.multi()
                  .set  redis.key("socket_id:#{socket.id}:session_id"),      session_id
                  .sadd redis.key("session_id:#{session_id}:socket_ids"),    socket.id
                  .exec next
                ###

              ], next

    @_io.sockets.on 'connection', (socket)->
      redis_socket_subscribe  = redis.create_client() # REDIS_PORT, REDIS_HOST

      async.waterfall [
        (next)-> redis.from_socket(socket).get_session_id next

      ], (err, session_id)->
        if err 
          console.log "Invalid session_id for socket connection!"
        else
          #console.log 'connection -> ', socket.id, " session: ", session_id

          redis_socket_subscribe.subscribe socket.id
          
          if _.isFunction opts.connection
            opts.connection socket, redis_socket_subscribe

          event_dirs = [
            (path.join __dirname, '..', "socket_events")
          ]

          if _.isArray opts.events
            for e in opts.events then event_dirs.push e
          else
            event_dirs.push opts.events if opts.events

          subscribe_dirs = [
            (path.join __dirname, '..', "socket_subscribes")
          ]

          if _.isArray opts.subscribes
            for e in opts.subscribes then subscribe_dirs.push e
          else
            subscribe_dirs.push opts.subscribes if opts.subscribes

          for dir in event_dirs
            socket_utils = null
            socket_utils = me.map_event socket, redis_socket_subscribe, config
            me.handle_event socket, redis_socket_subscribe, socket_utils, dir

          for dir in subscribe_dirs
            socket_utils = null
            socket_utils = me.map_message socket, redis_socket_subscribe, config
            me.handle_event socket, redis_socket_subscribe, socket_utils, dir

    @

  handle_event: (socket, redis_socket_subscribe, socket_utils, dir_path)->
    
    file_util.scan dir_path, ["coffee", "js"], (err, file_lists) ->

      async.map file_lists, (file, done)->
        method_path = []
        m = file.split('.')[0]
        m = m.split dir_path
        for p in  _.last(m).split "/"
          method_path.push (p + "").trim() if p 

        method_path = method_path.join "/"
         
        _m = require(file) socket, redis_socket_subscribe, config 
        socket_utils.reg method_path, _m

        done()

      , ()->

    
  get_session_id: (socket, callback)->
    request = socket.request
    web = config.util 'web'
    web.cookie_parser request, {}, (err)->
      if err 
        callback err
      else
        callback err, (request.secureCookies and request.secureCookies[EXPRESS_SID_KEY]) or
                          (request.signedCookies and request.signedCookies[EXPRESS_SID_KEY]) or
                          (request.cookies and request.cookies[EXPRESS_SID_KEY]);

  map_message: (socket, redis_socket_subscribe, config)->
    reg: (method_path, module)->
      redis_socket_subscribe.on method_path, (channel, message)->
        if _.isFunction module.exec
          json_msg = JSON.parse message
          module["exec"].apply module, [json_msg]

  map_event: (socket, redis_socket_subscribe, config)->
    me = @
    redis = config.util 'redis'

    reg: (method_path, module)-> 
      socket.on method_path, ()-> 
        args = arguments

        #console.log "EXEC #{method_path}"
        async.waterfall [
          (next)-> me.get_session_id socket, next

        , (session_id, next)-> 
          redis.from_session_id(session_id).get_email (e, email)-> 
            if e then next(e) else next(e, session_id, email)

        , (session_id, email, next)->
          redis.from_session_id(session_id).get_sockets (e, sockets)-> 
            if e then next(e) else
              next e, 
                session_id: session_id
                email: email 
                sockets: _.filter(sockets, (e)-> e != socket.id )
            
        ], (e, info)->
          if e
            console.log e
          else
            if _.isFunction module.exec
              params = [] 
              for prop, value of args 
                if _.isFunction value
                  params.unshift value
                else
                  params.push value
                
              params.push info
              module["exec"].apply module, params