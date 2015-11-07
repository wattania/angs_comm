Ext.define 'LogOutout',
  alias: 'widget.LogOutout'
  extend: 'Ext.panel.Panel'
  layout: 'fit'
  message: ""
  initComponent: ->
    @html_logger = Ext.create 'Ext.form.field.HtmlEditor',
      xtype: 'htmleditor'
      name: 'html_logger' 
      submitValue: false
      border: false
      value: ""
      listeners:
        render: ()->
          @getToolbar().hide()
          @setReadOnly true

    @items = [
      @html_logger
    ]
    @callParent arguments

  add_log: (msg)->
    me = @
    if Ext.isObject msg
      
      if msg.datetime
        console.log msg.datetime + " : " + msg.message
      else
        console.log msg.message



Ext.define 'MainPanel',
  extend: 'Ext.panel.Panel'
  layout: 'card'
  border: false
  cls: 'panel-no-border'
  
  initComponent: ->
    me = @
    @working_panel = Ext.create 'Ext.panel.Panel',      
      xtype: 'panel'
      
      layout: type: 'border'
      cls: 'panel-no-border'
      border: false
      dockedItems: [
        xtype: 'toolbar'
        dock: 'bottom'
        items: [
          "<b>" + (Font.fa "copyright", "2015 Angstrom Solutions Co., Ltd") + "</b>"
        ]
      ]
      items: [
        region: 'east'
        title: 'LOGS'
        layout: 'fit'
        width: 500
        items:
          Ext.create 'LogOutout'
      ,
        region: 'center'
        tools: [
          type: 'close'
          name: 'logout'
        ]
        title: "<b>Postgresql Admin</b> <font color=blue>(#{USER_EMAIL})</font>"
        layout: type: 'vbox', align: 'stretch'
        items: [
          xtype: 'restore_ui'
          socket: @socket
          flex: 1
        ]
      ]
      

    @mask_panel = Ext.create 'Ext.panel.Panel'

    @items = [
      @working_panel
    ,
      @mask_panel
    ]

    @callParent arguments