#= require panels/restore/restore
###
Ext.create('Ext.form.Panel', {
    title: 'Upload a Photo',
    width: 400,
    bodyPadding: 10,
    frame: true,
    renderTo: Ext.getBody(),
    items: [{
        xtype: 'filefield',
        name: 'photo',
        fieldLabel: 'Photo',
        labelWidth: 50,
        msgTarget: 'side',
        allowBlank: false,
        anchor: '100%',
        buttonText: 'Select Photo...'
    }],

    buttons: [{
        text: 'Upload',
        handler: function() {
            var form = this.up('form').getForm();
            if(form.isValid()){
                form.submit({
                    url: 'photo-upload.php',
                    waitMsg: 'Uploading your photo...',
                    success: function(fp, o) {
                        Ext.Msg.alert('Success', 'Your photo "' + o.result.file + '" has been uploaded.');
                    }
                });
            }
        }
    }]
});
###

Ext.define 'RestoreUi',
  extend: 'Ext.panel.Panel'
  alias: 'widget.restore_ui'
  layout: type: 'fit'
  border: false
  listeners:
    render: (me)-> (Ext.create 'Restore').bind me
  initComponent: ->
    store = Ext.create 'Ext.data.Store',
      autoLoad: true
      proxy:
        type: 'ajax'
        url: '/file'
        reader:
          type: 'json'
          rootProperty: 'data'
      fields: [
        {name: 'filename',  type: 'string'},
        {name: 'fullpath',  type: 'string'},
        {name: 'file_size', type: 'string'},
        {name: 'size',      type: 'integer'},
      ]
    @items = [
      xtype: 'grid'
      name: 'database'
      store: store
      border: false
      dockedItems: [
        xtype: 'toolbar'
        dock: 'top'
        items: [
          xtype: 'button'
          name: 'restore'
          text: 'Restore'
          disabled: true
          iconCls: 'fa-share-square-o'
        ,
          '->'
        ,
          xtype: 'button'
          name: 'upload'
          iconCls: 'fa-upload'
        ,
          xtype: 'button'
          name: 'delete'
          disabled: true
          iconCls: 'fa-trash'
        ]
      ,
        xtype: 'pagingtoolbar'
        store: store
        dock: 'bottom'
        displayInfo: true
      ] 
      columns: [
        xtype: 'rownumberer'
        width: 45
      ,
        text: "Filename"
        flex: 1
        dataIndex: 'filename'
      ,
        text: 'Size'
        width: 120
        dataIndex: 'file_size'
      ]
    ]
    @callParent arguments