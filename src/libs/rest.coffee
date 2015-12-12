Ext.define 'RestClient',
  statics:
    _rest_call: (a_path, func, a_params)->
      unless Ext.isObject a_params
        return console.log "_ invalid params for RestClient _"
 
      callback  = a_params.callback
      method    = a_params.method
      params    = a_params.params if Ext.isObject a_params.params

      operation = func
      if method
        operation = [func, method]
      
      p = 
        path: a_path
        operation: operation
      
      if Ext.isObject a_params.params     then Ext.apply p, (params: a_params.params)
      if Ext.isFunction a_params.callback then Ext.apply p, (callback: a_params.callback)
        
      RestClient.call p
    index:    (a_path, a_params)-> RestClient._rest_call a_path, "index",   a_params
    show:     (a_path, a_params)-> RestClient._rest_call a_path, "show",    a_params
    update:   (a_path, a_params)-> RestClient._rest_call a_path, "update",  a_params
    create:   (a_path, a_params)-> RestClient._rest_call a_path, "create",  a_params
    destroy:  (a_path, a_params)-> RestClient._rest_call a_path, "destroy", a_params

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

    show1: (url, a_params)->
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

    destroy1: (url, a_params)->
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

    download_tmp_file: (a_filehash, callback)->
      window_height = 70
      window_width = 300

      url = "/fileutil/#{a_filehash}?method=download"

      win = Ext.create 'Ext.window.Window',
        title: Font.fa 'refresh', 'Downloading ..', 'fa-splin'
        width: window_width
        height: window_height
        listeners:
          show: ()->
            Ext.defer ()->
              iframe = Ext.create "Ext.Component",
                xtype : "component"
                hidden: true
                autoEl :
                  tag : "iframe"
                  src : url

              console.log win.add iframe

              Ext.defer ()->
                callback()
                
                ##############################
                catchtime = ""
                count = 60
                c = count
                closeMe=()->
                  c -= 1
                  if c < 0
                    win.close()
                    window.clearInterval catchtime
                  else
                    if(c <= (count - 3))
                      win.setVisible false
                catchtime = window.setInterval closeMe, 1000
                ##############################


              , 250

            , 250



      win.showAt (outerWidth - (window_width)), (outerHeight - (window_height + 100))
       