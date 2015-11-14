Ext.define 'RestClient',
  statics:
    req: (path, params)->

      Ext.Ajax.request
        url: "/#{path}"
        success: (response, opts)->
          obj = Ext.decode response.responseText, true
          unless Ext.isEmpty obj
            if Ext.isObject obj
              if obj.error
                params.callback error, {} if Ext.isFunction params.callback
              else if Ext.isObject obj.data
                params.callback false, obj.data if Ext.isFunction params.callback 
              else
                params.callback false, {} if Ext.isFunction params.callback

            else
              Ext.Msg.alert 'ERROR', 'Invalid response', Ext.emptyFn    
           
        failure: ()->
          Ext.Msg.alert 'ERROR', 'Program Error!', Ext.emptyFn

    show: (url, a_params)->
      operations = ['show']
      if a_params.method 
        operations.push a_params.method

      p =
        path: url
        operation: operations
        
      if Ext.isObject a_params.params
        Ext.apply p,
          params:
            data: a_params.params

      if Ext.isFunction a_params.callback
        Ext.apply p,
          callback: a_params.callback

      RestClient.call p

    destroy: (url, a_params)->
      operations = ['destroy']
      if a_params.method 
        operations.push a_params.method

      p =
        path: url
        operation: operations
        
      if Ext.isObject a_params.params
        Ext.apply p,
          params:
            data: a_params.params

      if Ext.isFunction a_params.callback
        Ext.apply p,
          callback: a_params.callback

      RestClient.call p

    call: (a_params)->
      ###  
      RestClient.call
        path: me.store.getProxy().getUrl()
        operation: ['create', 'product']
        params:
          data: from.getValues()
        callback: (err)->
      ###
      return unless Ext.isObject a_params
      rest_path = Ext.valueFrom a_params.path, ""
      
      if Ext.isArray a_params.operation
        rest_operation = Ext.valueFrom a_params.operation[0], ""
        method    = Ext.valueFrom a_params.operation[1], ""
      else
        rest_operation = Ext.valueFrom a_params.operation, ""
        method = ""

      xhr = new XMLHttpRequest()
      xhr.addEventListener "load",  (evt)->   
      xhr.addEventListener "error", (evt)-> 
      xhr.addEventListener "abort", (evt)->  
      xhr.addEventListener "readystatechange", (evt)->   
        if evt.target.readyState == 4 
          if evt.target.status == 200 
            
            response = Ext.JSON.decode evt.target.responseText, true
            if Ext.isObject response
              if response.error
                Ext.Msg.alert 'ERROR', response.error
                a_params.callback response.error
              else 
                a_params.callback null, response.data if Ext.isFunction a_params.callback

            else
              Ext.Msg.alert 'Invalid JSON', evt.target.responseText

          else if evt.target.status == 401 
            Ext.Msg.alert 'Unauthorized!', "" 
            a_params.callback 'Unauthorized' if Ext.isFunction a_params.callback

          else
            Ext.Msg.alert 'Network Error!', "#{evt.target.status}" 
            a_params.callback 'Network Error!' if Ext.isFunction a_params.callback  
      
      #server_address = RestClient.get_server_addr()
      server_address = ""
      #return Ext.Msg.alert 'Unauthorized!', ""  if Ext.isEmpty server_address 
        
      unless Ext.isEmpty rest_path
        url = "#{server_address}/#{rest_path}"
      else
        url = "#{server_address}"

      access_token = ""

      m = null
      switch rest_operation
        when 'index', 'show'
          m = 'GET'
        when 'create'
          m = 'POST'
        when 'update'
          m = 'PUT'
        when 'destroy', 'delete'
          m = 'DELETE'
        else
          m = null

      form_data = {}

      Ext.apply form_data, a_params.params    if Ext.isObject a_params.params
      Ext.apply form_data, {method: method} if Ext.isString(method) and !Ext.isEmpty(method)

      if m == 'GET'
        url += "/?#{Ext.Object.toQueryString form_data}" unless Ext.isEmpty form_data
        xhr.open m, url, true  
        xhr.setRequestHeader "Authorization", "Bearer #{access_token}"  
        xhr.send()
      else
        xhr.open m, url, true
        xhr.setRequestHeader "Content-type", "application/json"  
        xhr.setRequestHeader "Authorization", "Bearer #{access_token}"  
        xhr.send JSON.stringify form_data
