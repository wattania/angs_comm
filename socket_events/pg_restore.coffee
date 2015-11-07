path  = require 'path'
async = require 'async'
fs    = require 'fs'

module.exports = (socket, redis_subscribe, config)->

  redis = config.util 'redis'
  pg    = config.util 'pg'

  exec: (a_params, fn)->
    console.log "-exec-pg_restore-", arguments
    async.waterfall [
      (next)-> redis.add_socket(socket).to_log_listener next
    , (next)->
      filename = a_params.filename
      dbname  = a_params.dbname
      username = a_params.username
      password = a_params.password
      console.log "---call pg_restore --> ", a_params
      pg.pg_restore filename, dbname, username, password, next

    ], (e)->
      console.log "- result -"
      console.log e
      fn success: (if e then true else false)
 
    ###
    spawn = require('child_process').spawn
    child = spawn cmd
    child.on 'error', -> console.log "-error-> ", arguments
    child.on 'exit', -> console.log "-exit-> ", arguments
    child.on 'close', -> console.log "-close-> ", arguments
    child.on 'disconnect', -> console.log "-disconnect-> ", arguments
    child.on 'message', -> console.log "-message->", arguments
    #console.log child
    child.stdout.on 'data', (data)-> 
      console.log "stdout_data -> ", data.toString()
    ###
    