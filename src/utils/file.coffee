fs    = require 'fs'
os    = require 'os'
async = require 'async'
path  = require 'path'
_     = require 'underscore'
uuid  = require 'uuid'
sha1  = require 'sha1'

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
            else
              returnFiles.push filePath
            
            next()
          
      , (err)->
        callback err, returnFiles

  get_tmp_file_path: (a_filename, callback)->
    file_path = path.join os.tmpdir(), a_filename

    fs.stat file_path, (err, stat)->
      if err 
        callback "file not found"
      else
        callback null, file_path
       
        

  write_tmp_file: (a_file_extension, a_data, done)->
    file_extension = ""
    file_extension = ".#{a_file_extension}" if a_file_extension

    file_name = (sha1 uuid.v4()) + "#{file_extension}"
    file_path = path.join os.tmpdir(), file_name
    async.waterfall [
      (next)->
        fs.writeFile file_path, a_data, next

    ], (err)->
      done err, file_name
