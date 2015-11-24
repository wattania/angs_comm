  Ext.define 'Socket',
    connect: ()-> 
      @socket = io()
      @socket

    emit: (a_params)->
      
      params = {}
      if Ext.isObject a_params
        path = null
        path = a_params.event if Ext.isString a_params.event

        if Ext.isObject a_params.params
          params = a_params.params

        
        @socket.emit path, params, (err, data)-> 
          if err 
            Ext.Msg.alert 'ERROR', err, Ext.emptyFn 
          a_params.callback err, data if Ext.isFunction a_params.callback

      else
        @socket["emit"].apply @socket, arguments