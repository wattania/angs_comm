#= require libs/font
#= require panels/restore/restore.ui
#= require panels/main_panel

Ext.onReady ->
  Ext.define 'Socket',
    connect: ()-> 
      @socket = io()
      @socket

    emit: ()-> @socket["emit"].apply @socket, arguments

  window.socket = Ext.create 'Socket'

  Ext.create 'Ext.container.Viewport',
    renderTo: Ext.getBody()
    listeners:
      render: ->
        me = @
        @socket = window.socket.connect()
        @socket.on 'message', (m) -> 
          log = me.down 'LogOutout'
          if log 
            log.add_log m

        @socket.on 'disconnect', -> me.setLoading "disconnect"
        @socket.on 'connect', -> me.setLoading false
        @socket.on 'reconnecting', -> me.setLoading 'reconnecting'

    name: 'workspace'
    layout: 'border'
    items: [
      Ext.create 'MainPanel',
        region: 'center'
    ,
      xtype: 'panel'
      region: 'north'
      height: 50
    ]
###
    
###