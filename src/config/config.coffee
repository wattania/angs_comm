_       = require 'underscore'
async   = require 'async'
yaml    = require 'js-yaml'
fs      = require 'fs'
path    = require 'path'

uuid          = require 'uuid'
sha1    = require 'sha1'    

module.exports = (a_config_path)->
  
  default_config = yaml.safeLoad fs.readFileSync (path.join __dirname, 'config.yml'), 'utf8'
  default_config = {} unless default_config

  user_config = yaml.safeLoad fs.readFileSync a_config_path, 'utf8'
  user_config = {} unless user_config

  config = {}
  if _.isObject(user_config) and _.isObject(default_config)
    config = _.extend default_config, user_config

  else if _.isObject default_config
    config = default_config

  else if _.isObject user_config
    config = user_config

  config: config

  sha1_uuid: ()-> sha1 uuid.v4()

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