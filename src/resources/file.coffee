async       = require 'async'
fs          = require 'fs'
path        = require 'path'
filesize    = require 'filesize'

module.exports = (config)->
  index: (req, res, sockets)->
    console.log "--sockets -> ", sockets
    console.log sockets
    async.waterfall [
      (next)-> config.get_backup_path next

    , (backup_path, next)->
      fs.readdir backup_path, (err, files)->
        next err, files, backup_path

    , (files, backup_path, next)->

      async.map files, (ff, done)->
        fullpath = path.join backup_path, ff 
        fs.stat fullpath, (e, stat)->
          data = 
            filename: ff
            fullpath: fullpath
            size: stat.size
            file_size: filesize(stat.size, {base: 10})

          done e, data
        
      , next

    ], (e, files, backup_path)->
      res.json 
        total: files.length
        data: files

  show: (id, req, res)->
    console.log "--show---", id
    res.json 
      success: true
      a: 2

  destroy: (id, req, res)->
    res.json 
      success: true
      a: 1
