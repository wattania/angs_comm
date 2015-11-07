_             = require 'underscore'
colors        = require 'colors'
child_process = require 'child_process'
moment        = require 'moment'

module.exports = (config)->
  redis = config.util 'redis'

  run: (a_entrypoint, a_params, callback)->
    console.log "exec: entrypoint = ", a_entrypoint
    console.log "exec: params = ", a_params
    child = child_process.spawn a_entrypoint, a_params
    #console.log child
    child.stdout.on 'data', (data)-> 
      console.log "stdout_data -> ", data.toString()

    child.stderr.on 'data', (data)->
      console.log colors.red("stderr_data -> #{data.toString()}")
      redis.log_room("log").publish_to_all
        level: 'error'
        datetime: moment(new Date()).format 'YYYY-MM-DD HH:mm:ss'
        message: data.toString()
      , ->

    child.on 'error', -> console.log "-error-> ", arguments
    child.on 'exit', -> console.log "-exit-> ", arguments
    child.on 'close', (e, res)-> 
      console.log colors.green("-close-> "), arguments
      callback e, res

    child.on 'disconnect', -> console.log "-disconnect-> ", arguments
    child.on 'message', -> console.log "-message->", arguments
    