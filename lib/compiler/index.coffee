#    Author: 易晓峰
#    E-mail: wvv8oo@gmail.com
#    Date: 2/3/15 11:07 AM
#    Description:

_common = require '../common'
_script = require './script'
_css = require './css'
_template = require './template'
_host = require '../plugin/host'
_fs = require 'fs-extra'

#根据文件类型，探测compiler的类型
exports.detectCompiler = (type)->
  #检测编译器的类型
  _common.config.compiler[type]

#根据编译类型，获取可能的要编译的文件名，并检查文件是否存在
exports.sourceFile = (type, source)->
  realpath = _common.replaceExt source, ".#{type}"
  if _fs.existsSync(realpath) then realpath else false

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
      console.log err

    _common.writeFile options.target, css if options.save and options.target
    cb err, css

#编译handlebars
handlebarsCompiler = (source, options, cb)->
  #handlebars渲染
  content = _template.render source, options.pluginData
  _common.writeFile options.target, content if options.save and options.target
  cb null, content