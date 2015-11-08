_       = require 'underscore'
async   = require 'async'
yaml    = require 'js-yaml'
fs      = require 'fs'
path    = require 'path'

module.exports = (a_config_data)->
  config: _.extend (yaml.safeLoad fs.readFileSync (path.join __dirname, 'config.yml'), 'utf8'  ), a_config_data

  util: (name)->
    
    unless @["__#{name}"]
      @["__#{name}"] = require("./../utils/#{name}") @ 
  
    @["__#{name}"]

  get_raw: -> @config
  get_backup_path: (callback)->
    create_if_not_exist = true

    backup_path = @config.backup_path

    async.waterfall [
      (done)-> 
        fs.exists backup_path, (exists)->
          if exists 
            callback null, backup_path
          else 
            if create_if_not_exist 
              require('mkdirp').mkdirp backup_path, (err, path)-> 
                if err  
                  callback err, null
                else 
                  callback null, path
            else 
              callback null, null

    ], callback