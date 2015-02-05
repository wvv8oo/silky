#    Author: 易晓峰
#    E-mail: wvv8oo@gmail.com
#    Date: 2/3/15 11:07 AM
#    Description:

_common = require '../common'
_script = require './script'
_css = require './css'
_template = require './template'
_host = require '../plugin/host'

#统一的处理器
exports.execute = (type, source, options, cb)->
  if typeof options is 'function'
    cb = options
    options = {}

  #如果在插件中有指定了编译器，那么采用插件中指定的编译器
  compiler = _host.getCompilerWith type
  return compiler source, options, cb if compiler

  switch type
    when 'less' then return lessCompiler source, options, cb
    when 'coffee' then return coffeeCompiler source, options, cb
    when 'hbs' then return handlebarsCompiler source, options, cb
    else return cb null, false

#编译coffee
coffeeCompiler = (source, options, cb)->
  #读取文件
  content = _script.compile source
  _common.writeFile options.target, content if options.save and options.target
  cb null, content

#编译less
lessCompiler = (source, options, cb)->
  _css.render source, (err, css)->
    if err
      console.log "CSS Error: #{source}".red
      console.log err.message.red

    _common.writeFile options.target, content if options.save and options.target
    cb err, css

#编译handlebars
handlebarsCompiler = (source, options, cb)->
  #handlebars渲染
  content = _template.render source, options.pluginData
  _common.writeFile options.target, content if options.save and options.target
  cb null, content