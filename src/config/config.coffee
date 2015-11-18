_       = require 'underscore'
async   = require 'async'
yaml    = require 'js-yaml'
fs      = require 'fs'
path    = require 'path'

uuid          = require 'uuid'
sha1    = require 'sha1'    

module.exports = (a_config_path, a_opts)->
  utils_dirs = [path.join(__dirname, "./../utils")]
  if (_.isObject a_opts) and (_.isArray a_opts.dirs)
    for p_dir in a_opts.dirs then utils_dirs.push p_dir
 
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
    me = @
    unless @["__#{name}"] 
      for util_dir_path in utils_dirs  
        if fs.existsSync util_dir_path 
          if fs.lstatSync(util_dir_path).isDirectory()
            source_path         = path.join util_dir_path, name

            for ext in ["coffee", "js"]
              _src = source_path + ".#{ext}"
              if (fs.existsSync _src) and fs.lstatSync(_src).isFile()
                unless me["__#{name}"] then me["__#{name}"] = require(_src) me 
                        
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