fs    = require 'fs'
async = require 'async'
path  = require 'path'
_     = require 'underscore'

module.exports = (config)->
  scan_sync: (a_dir, a_suffix)->
    returnFiles = []

    _scan = (a_dir, a_suffix)->
      
      files = fs.readdirSync a_dir 
      for file in files 
        file_path = path.join a_dir, file 
        stat = fs.statSync file_path
        if stat.isDirectory()
          results = _scan file_path, a_suffix
          returnFiles = returnFiles.concat results
         
        else if stat.isFile()
          ext = _.last(file.split ".")
          if _.isArray a_suffix
            if _.contains a_suffix, ext  
              returnFiles.push file_path

          else if _.isString a_suffix
            if ext == a_suffix 
              returnFiles.push file_path

      []

    _scan a_dir, a_suffix
    returnFiles

  scan: (dir, suffix, callback)-> 
    me = @
    fs.readdir dir, (err, files)-> 
      returnFiles = []
      async.each files, (file, next)->
        filePath = path.join dir, file
        fs.stat filePath, (err, stat)->
          if err then return next err
          
          if stat.isDirectory() 

            me.scan filePath, suffix, (err, results)->
              if err then return next err
              
              returnFiles = returnFiles.concat results

              next()
            
          else if stat.isFile()
            ext = _.last file.split('.')

            if _.isArray suffix
              if _.contains suffix, ext
                returnFiles.push filePath

            else if _.isString suffix
              if ext == suffix
                returnFiles.push filePath  
            
            next()
          
      , (err)->
        callback err, returnFiles