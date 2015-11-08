_     = require 'underscore'
path  = require "path"
async = require "async"
squel = require "squel"
pg    = require 'pg'

module.exports = (socket, redis_subscribe, config)->

  redis = config.util 'redis'

  exec: (fn)->
    con_string = "postgres://postgres:Angstroms99!@aboss_pg/postgres";
    stmt = squel.select("rolname")
          .from("pg_roles").toString()
    
    client = new pg.Client con_string

    async.waterfall [
      (next)-> client.connect next
    , (conn, next)-> client.query stmt, next
    ], (e, result)->
      if e 
        console.error 'error running query', err
        return fn e
      else
        ret = []
        for role in result.rows then ret.push {name: role.rolname}
        fn e, _.sortBy(ret, (n)-> n.name)