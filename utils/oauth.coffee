_       = require 'underscore'
async   = require 'async'
moment  = require 'moment'
jwt     = require 'jsonwebtoken'

JWT_SECRET      = process.env.JWT_SECRET
REDIRECT_URI    = process.env.APPLICATION_CALLBACK #"http://10.211.55.15:3000/callback"

func = (config)->
  oauth2: require('simple-oauth2')
    clientID: process.env.APPLICATION_ID #'6c79b905cdf4db2e92f005e19ad95ad19f0121f71dd841a4d3ee86b80670cf9c'
    clientSecret: process.env.APPLICATION_SECRET #'b266b52663194861ed7ac9ea60c6551d9c5ed05b31aa9e44171abe2b1fd45bbe'
    site: process.env.OAUTH_SITE #'http://auth.angsoln.net:3005'
    tokenPath: '/oauth/token'
  
  create_token: (token_info)-> 
    console.log "-oauth-create token-"
    @oauth2.accessToken.create token_info

  __token_key: (access_token)->       
    config.util('redis').key "access_token:#{access_token}:values"

  __token_key_user: (access_token)->  
    config.util('redis').key "access_token:#{access_token}:user_info"

  get_client: ()->

  verify_token: (access_token, callback)-> 
    jwt.verify access_token, JWT_SECRET, callback

  get_authorization_uri: ()-> 
    @oauth2.authCode.authorizeURL
      redirect_uri: REDIRECT_URI
      scope: ''

  auth_token_code: (code, callback)-> 
    @oauth2.authCode.getToken
      code: code
      redirect_uri: REDIRECT_URI

    , callback

  store_token: (token_info, done)->
    me = @
    access_token = token_info.access_token
    redis = config.util('redis').client

    async.waterfall [
      (next)-> 
        jwt.verify access_token, JWT_SECRET, next

    , (decoded, next)->
      redis.hmset me.__token_key_user(access_token), decoded.user, (err, result)->
        next err 

    , (next)->
      redis.hmset me.__token_key(access_token), token_info, next

    ], done

  get_token: (access_token, done)-> 
    self = @
    redis = config.util('redis').client
    async.waterfall [
      (next)-> 
        redis.hgetall self.__token_key(access_token), next

    , (token_info, next)->
      if _.isObject token_info
        token = self.create_token token_info
        created_at = moment.unix(parseInt token_info.created_at)

        expires_at = moment(created_at).add (parseInt token_info.expires_in), 's'
        now        = moment().subtract 10, 's'

        if expires_at <= now
          async.waterfall [
            (next)->
              token.refresh next

          , (new_token, next)->
            async.waterfall [
              (next)->
                self.store_token new_token.token, next

            ], (err)->
              next err, new_token

          ], next
   
        else
          next null, token
      else
        next 'Token not found!'

    ], done

module.exports = func