fs      = require 'fs'
path    = require 'path'
async   = require 'async'
colors  = require 'colors'

PG_HOST = process.env.PG_HOST

PG_BIN_PATH       = "/usr/pgsql-9.4/bin" 
PG_CMD_RESTORE    = "pg_restore"
PG_CMD_CREATEDB   = "createdb"
PG_CMD_DROPDB     = "dropdb"

PG_PASS_PATH = path.join process.env.HOME, ".pgpass"

module.exports = (config)->
  exec = config.util 'exec'
  redis = config.util 'redis'

  create_pgpass: (a_pg_user, a_pg_pass, callback)->
    async.waterfall [
      (next)-> fs.exists PG_PASS_PATH, (exists)-> next null, exists
    , (exists, next)->
      p = [PG_PASS_PATH, "#{PG_HOST}:5432:*:#{a_pg_user}:#{a_pg_pass}", { flags: 'wx', mode: 600 }, next]
      fs["writeFile"].apply fs, p 
    , (next)-> fs.chmod PG_PASS_PATH, "0600", next
    ], callback

  get_all_role_name: (callback)->
    callback success: true

  drop_db: (a_db_name, a_username, a_password, callback)->
    me = @
    async.waterfall [
      (next)-> me.create_pgpass a_username, a_password, next
    , (next)->
      console.log "pg: drop_db:", arguments
      params = [
        "--host=#{PG_HOST}",
        "--port=5432",
        "--username=#{a_username}",
        "--no-password",
        "--if-exists",
        a_db_name
      ]
      
      exec.run (path.join PG_BIN_PATH, PG_CMD_DROPDB), params, next

    ], callback

  create_db: (a_db_name, a_username, a_password, a_owner, callback)->
    # "#{PG_BIN}/createdb --host=127.0.0.1 --port=5432 --username=#{PG_USER} --encoding=UTF-8 --owner=#{owner} --no-password #{db_name}"
    me = @
    async.waterfall [
      (next)-> me.create_pgpass a_username, a_password, next
    , (next)->
      console.log "pg: create_db:", arguments
      params = [
        "--host=#{PG_HOST}",
        "--port=5432",
        "--username=#{a_username}",
        "--encoding=UTF-8",
        "--owner=#{a_owner}"
        "--no-password",
        a_db_name
      ]
      
      exec.run (path.join PG_BIN_PATH, PG_CMD_CREATEDB), params, next

    ], callback

  pg_restore: (a_filename, a_db_name, a_username, a_password, callback)->
    console.log colors.bold.yellow "PG: pg_restore "
    console.log arguments

    me = @
    async.waterfall [
      (next)-> 
        console.log colors.bold.yellow "PG: pg_restore : create_pgpass"
        me.create_pgpass a_username, a_password, next

    , (next)->
      console.log colors.bold.yellow "PG: pg_restore : drop_db"
      me.drop_db a_db_name, a_username, a_password, next

    , (e, next)->
      console.log colors.bold.yellow "PG: pg_restore : create_db"
      me.create_db a_db_name, a_username, a_password, a_username, next

    , (e, next)-> 
      console.log colors.bold.yellow "PG: pg_restore : get_backup_path"
      console.log "--get_backup_path--> ", arguments
      config.get_backup_path next

    , (backup_path, next)->
      console.log colors.bold.yellow "PG: pg_restore : do restore"
      
      a_backup_path = path.join backup_path, a_filename
      console.log "pg: pg_restore path:", a_backup_path
      params = [
        a_backup_path,
        "--dbname=#{a_db_name}",
        "--host=#{PG_HOST}",
        "--username=#{a_username}",
        "--verbose",
        "--no-password",
        "--exit-on-error"
      ]
      
      exec.run (path.join PG_BIN_PATH, PG_CMD_RESTORE), params, next

    ], callback