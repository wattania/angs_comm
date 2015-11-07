COOKIE_SECRET   = process.env.COOKIE_SECRET
EXPRESS_SID_KEY = process.env.EXPRESS_SID_KEY

url         = require 'url'
_           = require 'underscore'
async       = require 'async'
express     = require 'express'
path        = require "path"
fs          = require 'fs'
express_cookie_parser = require 'cookie-parser'

module.exports = (config)->
  listen: (port)->
    ret = @app.listen port
    ret.session_redis_store = @app.session_redis_store
    ret

  create: ()->
    redis = config.util 'redis'
    oauth2 = config.util 'oauth'

    @cookie_parser = express_cookie_parser COOKIE_SECRET
    
    authorization_uri = oauth2.get_authorization_uri()

    @app = express()
    @app.set 'view engine', 'jade'
    @app.set 'views', path.join(__dirname, '..', 'views')
    @app.use "/fonts", express.static(path.join(__dirname, '..', 'assets/fonts'))
    @app.use (require 'connect-assets')
      paths: [
        path.join(__dirname, '..', 'assets/css'),
        path.join(__dirname, '..', 'assets/javascripts'),
        path.join(__dirname, '..', 'assets/img')
      ]

    session     = require 'express-session'
    RedisStore  = require('connect-redis') session

    @app.session_redis_store = new RedisStore host: 'redis'
    @app.use session
      store: @app.session_redis_store
      secret: COOKIE_SECRET
      saveUninitialized: false
      resave: false
      name: EXPRESS_SID_KEY

    #@session_redis_store

    @app.get '/', (req, res)->
      token = req.session.token
      if _.isObject token
        async.waterfall [
          (next)->
            oauth2.get_token token.access_token, next

        , (token_info, next)-> 
          next null, token_info

        ], (err, info)-> 
          if err 
            delete req.session.token
            res.redirect authorization_uri
      
          else 
            req.session.token = info.token

            async.waterfall [
              (next)-> oauth2.verify_token req.session.token.access_token, next
            , (decode, next)->
              redis.add_session_id(req.sessionID).to_email decode.user.email, (err)-> next err, decode
              ###
              redis.client.multi()
                .set  redis.key("session_id:#{req.sessionID}:email"),      decode.user.email
                .sadd redis.key("email:#{decode.user.email}:session_ids"), req.sessionID
                .exec (err)-> next err, decode
              ###

            ], (err, decode)->
              console.log "Decode -> ", decode
              if err 
                delete req.session.token
                res.redirect authorization_uri

              else
                res.render 'index',
                  email: decode.user.email
                  user: decode.user

      else
        res.redirect authorization_uri

    controller_path = path.join __dirname, '..', 'resources'
    base_controller_path = path.join __dirname, '..', 'resources', '__base'

    app_controller = @map_route()

    for file in fs.readdirSync controller_path
      continue if file in ["..", "."]
      rest_path = file.split('.')[0]
      m = require path.join __dirname, '..', 'resources', file
      app_controller.reg rest_path, m

    @

  __rest_fn: (req, res, method_name, callback)->
    me = @
    redis = config.util 'redis'

    rest_path = url.parse(req.originalUrl).pathname.split('/')[1]
    if rest_path
      fn = me.rest_call[rest_path]
      if _.isFunction fn 
        _a = fn config
        if _.isObject _a

          if _.isFunction _a[method_name]
            if method_name in ['index', 'create']
              
              async.waterfall [
                (next)-> redis.from_session_id(req.sessionID).clear_socket next
              ], (err, socket_ids)-> 
                if err 
                  callback err
                else 
                  _a[method_name].apply _a, [
                    req, 
                    res, 
                    socket_ids
                  ]
                  callback err

            else
              id = req.params.id
              async.waterfall [
                (next)-> redis.from_session_id(req.sessionID).clear_socket next 
              ], (err, results)->
                if err then callback(err) else 
                  _a[method_name].apply _a, [id, req, res]
                  callback err
          else
            callback "undefined method '#{method_name}'"  
          
        else
          callback "Invalid rest controller [#{rest_path}]"
      else
        callback 'Invalid Rest Function!'  
    else
      callback 'Invalid Rest Path!'
      
  map_route: ()->
    me = @
    app = @app
    @rest_call = {}
    reg: (rest_path, a_module)->
      me.rest_call[rest_path] = a_module

      #index
      app.get "/#{rest_path}", (req, res)->
        console.log "Resource:#{rest_path}:index:#{req.sessionID}"
        me.__rest_fn req, res, 'index', (err)->
          me.render_error res, err if err 
            
      #create
      app.post "/#{rest_path}", (req, res)->
        console.log "Resource:#{rest_path}:create"
        me.__rest_fn req, res, 'create', (e)-> me.render_error res, e if e 
        
      #update
      app.post "/#{rest_path}/:id", (req, res)->
        me.__rest_fn req, res, 'update', (e)-> me.render_error res, e if e  

      #show
      app.get "/#{rest_path}/:id", (req, res)->
        me.__rest_fn req, res, 'show', (e)-> me.render_error res, e if e

      #destroy
      app.delete "/#{rest_path}/:id", (req, res)->
        console.log "Resource:#{rest_path}:destroy:#{req.params.id}"
        r = me.__rest_fn req, res, 'destroy'
        res.json error: r if _.isString r

  render_error: (res, err)->
    res.render 'page_error',
      message: "[" + err.toString() + "]"
