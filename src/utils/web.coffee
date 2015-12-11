COOKIE_SECRET   = process.env.COOKIE_SECRET
EXPRESS_SID_KEY = process.env.EXPRESS_SID_KEY
REDIS_HOST      = process.env.REDIS_HOST || 'redis'
REDIS_PORT      = process.env.REDIS_PORT || 6379

url         = require 'url'
_           = require 'underscore'
async       = require 'async'
express     = require 'express'
body_parser = require 'body-parser'
path        = require "path"
fs          = require 'fs'
multer      = require 'multer'

express_cookie_parser = require 'cookie-parser'

module.exports = (config)->
  listen: (port)->
    ret = @app.listen port
    ret.session_redis_store = @app.session_redis_store
    ret

  create: (a_opts)->

    opts = {}
    opts = a_opts if _.isObject a_opts

    redis = config.util 'redis'
    oauth2 = config.util 'oauth'

    @cookie_parser = express_cookie_parser COOKIE_SECRET
    
    authorization_uri = oauth2.get_authorization_uri()

    @app = express()
    @app.set 'view engine', 'jade'

    if opts.views
      @app.set 'views', opts.views
    else
      @app.set 'views', path.join(__dirname, '..', 'views')

    @app.use "/fonts", [

      (express.static(path.join(__dirname, '..', '..', 'assets/fonts')))

    ]

    assets_path = [
      path.join(__dirname, '..', '..', 'assets/css'),
      path.join(__dirname, '..', '..', 'assets/javascripts'),
      path.join(__dirname, '..', 'libs'),
      path.join(__dirname, '..', '..', 'assets/img')
    ]

    if _.isArray opts.assets
      for e in opts.assets then assets_path.push e
    else
      assets_path.push opts.assets if opts.assets

    @app.use body_parser.json()
    @app.use body_parser.urlencoded
      extended: true

    @app.use (require 'connect-assets')
      paths: assets_path

    session     = require 'express-session'
    RedisStore  = require('connect-redis') session

    @app.session_redis_store = new RedisStore host: REDIS_HOST, port: REDIS_PORT
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

            , (decode, next)->
              redis.set_user_info(decode.user).to_session_id req.sessionID, (err)-> next err, decode

            ], (err, decode)->
              
              if err 
                delete req.session.token
                res.redirect authorization_uri

              else
                params = 
                  email: decode.user.email
                  user: decode.user

                if _.isFunction opts.index
                  opts.index params, (err, a_params)->
                    if err
                      res.status(500).type('txt').send (err + "" )
                    else
                      if _.isObject a_params
                        res.render 'index', _.extend(params, a_params)
                      else
                        res.render 'index', params
                else
                  res.render 'index', params

      else
        res.redirect authorization_uri

    controller_paths = [(path.join __dirname, '..', 'resources')]
    if _.isArray opts.controllers
      for e in opts.controllers then controller_paths.push e
    else
      controller_paths.push opts.controllers if opts.controllers

    app_controller = @map_route()

    for controller_path in controller_paths
      if fs.existsSync controller_path
        if fs.lstatSync(controller_path).isDirectory()

          for file in fs.readdirSync controller_path
            continue if file in ["..", "."]

            _dot_split = file.split(".")

            continue unless _dot_split[0]
            continue unless _.contains ['coffee', 'js'], _.last(_dot_split)

            rest_path = _.first _dot_split

            file_path = path.join controller_path, file
            m = require file_path

            app_controller.reg (file_path + ""), rest_path, m
      else
        console.log "warning: #{controller_path} , not exist"

    @

  __response_fn: (res, err, data, a_opts)->
    opts = {}
    opts = a_opts if _.isObject a_opts

    if opts.file_path
      fs.stat opts.file_path, (e)->
        if e
          res.json error: "#{e.code}: #{e.path}"
        else
          res.sendFile opts.file_path  

    else
      if err 
        res.json error: err
      else 
        if data 
          res.json data: data 
        else 
          res.json error: null

  __rest_fn: (req, res, method_name, callback)->
    me = @
    redis = config.util 'redis'

    rest_path = url.parse(req.originalUrl).pathname.split('/')[1]
    if rest_path
      fn = me.rest_call[rest_path]
      if _.isFunction fn 
        self = fn config
        if _.isObject self
 
          params = req.params
          params = (_.extend params, req.query) if method_name in ['index', 'show']

          req_body = req.body
          if _.isObject params
            if _.isObject req_body
              params = _.extend params, req_body

          if method_name in ['index', 'create']
            
            async.waterfall [
              (next)-> 
                redis.from_session_id(req.sessionID).clear_socket (err, socket_ids)-> next err, socket_ids

            , (socket_ids, next)->
              redis.from_session_id(req.sessionID).get_user_info (err, user_info)->
                next err, socket_ids, user_info

            ], (err, socket_ids, user_info)-> 
              if err 
                callback err
              else 
                called = false 
                if params.method
                  if _.isFunction self["#{method_name}_#{params.method}"]
                    called = true
                    self["#{method_name}_#{params.method}"].apply self, [
                      (err, data, a_opts)-> me.__response_fn res, err, data, a_opts
                    ,
                      params,
                      req, 
                      res,
                      {user: user_info, sockets: socket_ids} 
                    ]                      
                  else
                    return callback "Undefined method '#{method_name}_#{params.method}' "

                unless called
                  if _.isFunction self[method_name]
                    self[method_name].apply self, [
                      (err, data)-> 
                        if err 
                          res.json error: err
                        else 
                          if data
                            res.json data: data
                          else 
                            res.json error: null
                    ,
                      params,
                      req, 
                      res, 
                      {user: user_info, sockets: socket_ids} 
                    ]
                  else
                    return callback "no method #{method_name}"

          else

            if _.isObject params
              params.id = req.params.id

            id = req.params.id
            async.waterfall [
              (next)-> 
                redis.from_session_id(req.sessionID).clear_socket (err, socket_ids)-> next err, socket_ids

            , (socket_ids, next)->
              redis.from_session_id(req.sessionID).get_user_info (err, user_info)->
                next err, socket_ids, user_info

            ], (err, socket_ids, user_info)-> 

              if err then callback(err) else 
                called = false 
                if params.method
                  
                  if _.isFunction self["#{method_name}_#{params.method}"]
                    
                    called = true
                    
                    self["#{method_name}_#{params.method}"].apply self, [
                      (err, data, a_opts)-> me.__response_fn res, err, data, a_opts
                    , params, req, res, {user: user_info, sockets: socket_ids} 
                    ]
                    
                  else
                    return callback "Undefined method '#{method_name}_#{params.method}' "

                unless called
                  
                  if _.isFunction self[method_name]
                    
                    self[method_name].apply self, [
                      (err, data)-> 
                        if err
                          res.json error: err
                        else 
                          if data 
                            res.json data: data
                          else
                            res.json error: null

                    , params, req, res, {user: user_info, sockets: socket_ids} 
                    ]
                  else
                    
                    return callback "Undefined method '#{method_name}' "
           
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
    reg: (file_path, rest_path, a_module)->
      me.rest_call[rest_path] = a_module

      #index
      app.get "/#{rest_path}", (req, res)->
        me.__rest_fn req, res, 'index', (err)->   res.json error: err
            
      #create
      app.post "/#{rest_path}", (req, res)->
        me.__rest_fn req, res, 'create', (err)->  res.json error: err
        
      #update
      app.put "/#{rest_path}/:id", (req, res)->
        me.__rest_fn req, res, 'update', (err)->  res.json error: err

      #show
      app.get "/#{rest_path}/:id", (req, res)->
        me.__rest_fn req, res, 'show', (err)->    res.json error: err

      #destroy
      app.delete "/#{rest_path}/:id", (req, res)->
        me.__rest_fn req, res, 'destroy', (err)-> res.json error: err

  render_error: (res, err)->
    res.render 'page_error',
      message: "[" + err.toString() + "]"
