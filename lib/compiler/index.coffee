#    Author: 易晓峰
#    E-mail: wvv8oo@gmail.com
#    Date: 2/3/15 11:07 AM
#    Description:

_fs = require 'fs-extra'
_ = require 'lodash'
_path = require 'path'

_utils = require '../utils'
_host = require '../plugin/host'

#编译器列表
_coffeeCompiler = require './coffeeScriptCompiler'
_lessCompiler = require './lessCompiler'
_hbsCompiler = require './handlebars/hbsCompiler'

#根据path判断对应的编译器，优先匹配插件
getCompilerWithPath = (path)->
  compiler = false
  rules = _utils.xPathMapValue 'compiler.rules', _utils.config
  return compiler if not (rules  and rules instanceof Array)

  for rule in rules
    return rule.compiler if rule.path.test(path)
  compiler

#根据文件类型判断编译器，优先匹配插件
getCompilerWithType = (type)->
  #默认的编译器
  compilerMatches =
    htm: 'hbs'
    html: 'hbs'
    css: 'less'
    js: 'coffee'

  #根据配置中扩展名来匹配编译器
  extension = _utils.xPathMapValue 'compiler.extension', _utils.config
  #合并编译器到默认的编译器
  _.extend compilerMatches, extension if extension
  compilerMatches[type]

#根据文件类型，及路径，探测compiler的类型
exports.detectCompiler = (type, path)->
  getCompilerWithPath(path) || getCompilerWithType(type)

##根据编译类型，获取可能的要编译的文件名，并检查文件是否存在
#exports.sourceFile = (type, source)->
#  realpath = _utils.replaceExt source, ".#{type}"
#  if _fs.existsSync(realpath) then realpath else false

#统一的处理器
exports.execute = (compilerName, source, options, cb)->
  if typeof options is 'function'
    cb = options
    options = {}

  relativeSource = _path.relative _utils.options.workbench, source
  #如果在插件中有指定了编译器，那么采用插件中指定的编译器
  compiler = _host.getCompilerWithName compilerName

  return compiler source, relativeSource, options, cb if compiler

  #内置的编译器
  switch compilerName
    when 'less' then return _lessCompiler.compile source, relativeSource, options, cb
    when 'coffee' then return _coffeeCompiler.compile source, relativeSource, options, cb
    when 'hbs' then return _hbsCompiler.compile source, relativeSource, options, cb

  cb null, false
