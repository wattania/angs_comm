Ext.define 'Font',
  statics:
    fa: (icon_name, text, a_cls)->
      cls = (if a_cls then a_cls else "")
      "<i class=\"fa fa-#{icon_name} #{cls}\"></i> #{text}"