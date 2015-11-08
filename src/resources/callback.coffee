module.exports = (config)->
  index: (req, res)->
    oauth2 = config.util 'oauth'
    code = req.query.code
    oauth2.auth_token_code code, (error, result)->
      if error
        res.status(401).type('txt').send(error);
      else
        token = oauth2.create_token result
        oauth2.store_token result, (err)->
          if err
            (res.status(500).type('txt').send err + "") 
          else
            ############# 
            req.session.token = result 
            res.redirect '/'