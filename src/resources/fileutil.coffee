os    = require 'os'
fs    = require 'fs'
async = require 'async'

module.exports = (config)->
  file_util = config.util 'file'

  index: (callback, params, req, res)->
    callback null

  show_download: (callback, params, req, res)->
    console.log "- show_download -"
     
    async.waterfall [
      (next)->
        file_util.get_tmp_file_path params.id, next

    ], (err, file_path)->
      if err 
        callback err 
      else
        res.download file_path, params.id, ->
          fs.unlink file_path, ->