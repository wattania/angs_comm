Ext.define 'RestoreWin',
  extend: 'Ext.window.Window'
  title: 'Restore'
  width: 600
  modal: true
  layout: 'fit'
  listeners:
    render: -> @bind_events @
  getValues: ()-> if Ext.isObject @values then @values else null
  bind_events: (me)->

    form = @down 'form'
    btn_ok = @down 'button[name=restore]'

    btn_ok.on 'click', ->
      if form.isValid()
        me.values = form.getValues()
        for n in ['dbname', 'username', 'password'] 
          Ext.util.Cookies.set "restore_#{n}", me.values[n]

        me.close()

  initComponent: ->
    me = @

    @height = outerHeight * 0.3
    roles = []
    if Ext.isArray @roles then roles = @roles
    
    form = Ext.create 'Ext.form.Panel',
      border: false
      items: [
        xtype: 'hidden'
        name: 'fullpath'
        value: @fullpath
      ,
        xtype: 'textfield'
        text: 'From'
        width: 500
        allowBlank: false
        fieldLabel: 'From File'
        value: @file
        name: 'filename'
        readOnly: true 
      ,
        xtype: 'combo'
        fieldLabel: 'Role (Owner)'
        forceSelection: true
        allowBlank: false
        store: Ext.create 'Ext.data.Store',
          fields: ['name']
          data: roles
        #value: if roles.length > 0 then roles[0].name else null
        queryMode: 'local'
        displayField: 'name'
        valueField: 'name'
        name: 'username' 
        value: Ext.util.Cookies.get 'restore_username'
      ,
        xtype: 'textfield'
        fieldLabel: 'Database Name'
        allowBlank: false
        name: 'dbname' 
        value: Ext.util.Cookies.get 'restore_dbname'
      ,
        xtype: 'textfield'
        inputType: 'password'
        name: 'password'
        allowBlank: false
        fieldLabel: 'Password'
        value: Ext.util.Cookies.get 'restore_password'

      ]
    @buttons = [
      text: 'OK'
      name: 'restore'
      iconCls: 'fa-check'
    ]
    @items = [
      bodyPadding: 10
      border: false
      items: form
    ]
    @callParent arguments