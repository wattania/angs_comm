module.exports = (config)->
  update: (id, req, res)->
    console.log "-- restore --",
    console.log id

    res.json 
      success: true
      a: 3