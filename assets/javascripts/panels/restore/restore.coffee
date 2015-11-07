#= require libs/rest
#= require panels/restore/restore_win

Ext.define 'Restore',
  bind: (ui)->

    grid = ui.down 'grid[name=database]'
    btn_restore = ui.down 'button[name=restore]'
    btn_delete  = ui.down 'button[name=delete]'
    btn_upload  = ui.down 'button[name=upload]'

    grid.on 'selectionchange', ->
      btn_restore.setDisabled !(grid.getSelectionModel().getSelection().length > 0)
      btn_delete.setDisabled !(grid.getSelectionModel().getSelection().length > 0)
    
    btn_upload.on 'click', (btn)->
      window.socket.emit 'test', 1, ()-> console.log arguments

    btn_restore.on 'click', (btn)->
      selections = grid.getSelectionModel().getSelection()
      if selections.length <= 0
        btn.setDisabled true
        return

      select = selections[0] 
      ui.setLoading true
      window.socket.emit 'pg_all_roles', (e, roles)->
        ui.setLoading false

        filename  = select.get 'filename'
        Ext.create('RestoreWin',
          roles: roles
          file: filename
          fullpath: select.get 'fullpath'
          listeners:
            close: (win)->
              values = win.getValues()
              if Ext.isObject values
                console.log "pg_restore -> ", values
                window.socket.emit 'pg_restore', values, ()->
              else
                console.log "-close->", 

        ).show()
        
      
      ###
      
      RestClient.update "file/#{selections[0].get 'filename'}",
        params: 
          fullpath: select.get 'fullpath'
        callback: (err, res)->
          console.log "--res--"
          console.log arguments
      ###

    btn_delete.on 'click', (btn)->
      selections = grid.getSelectionModel().getSelection()
      if selections.length <= 0
        btn.setDisabled true
        return


      filename = selections[0].get 'filename'
      Ext.Msg.show
        title:'Delete?'
        msg: filename
        buttons: Ext.Msg.YESNOCANCEL
        icon: Ext.Msg.QUESTION
        fn: (btn, text)->
          if btn == 'yes'
            RestClient.destroy "file/#{filename}",
              params: {a: 1, b: 2}
              callback: (err, res)->
                console.log "--res--"
                console.log arguments
