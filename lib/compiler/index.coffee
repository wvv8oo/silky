#    Author: 易晓峰
#    E-mail: wvv8oo@gmail.com
#    Date: 2/3/15 11:07 AM
#    Description:

_fs = require 'fs-extra'
_ = require 'lodash'
_path = require 'path'

_utils = require '../utils'
_host = require '../plugin/host'

_compilerMgr = require './compiler_manager'
#编译器列表
_coffeeCompiler = require './coffee_script_compiler'
_lessCompiler = require './less_compiler'
_hbsCompiler = require './handlebars/compiler'

#根据配置文件的规则来匹配编译器
exports.getCompilerWithRule = (path, isRealTime)->
  rules = _utils.xPathMapValue 'compiler.rules', _utils.config
  return if not (rules  and rules instanceof Array)

  for rule in rules
    return rule.compiler if _utils.simpleMatch(rule.path, path, true)

#根据用户的配置，匹配扩展名所对应的编译器
#如果用户配置没有匹配上，则直接扫描所有编译器依次匹配
exports.getCompilerWithExt = (ext, isRealTime)->
  #根据配置中扩展名来匹配编译器
  rules = _utils.xPathMapValue 'compiler.maps', _utils.config
  #实时预览时，匹配target，否则匹配targetExt和sourceExt
  key = if isRealTime then 'targetExt' else 'sourceExt'

  for rule in rules
    if _utils.simpleMatch(rule[key], ext, true)
      return _compilerMgr.getCompilerWithName(rule.compiler)

  #匹配所有的的编译器
  _compilerMgr.getCompilerWithExt ext, isRealTime

#下面的代码将要废弃
##根据路径结合用户的配置文件，获取编译器的名称
##即：在此获取匹配的编译器，都是用户在配置文件中 指定的
#exports.detectCompiler = (path, isRealTime)->
#  ext = _utils.getExtension path
#  #根据规则匹配到编译器，如果没有匹配到，则根据用户配置的扩展名映射匹配
#  getCompilerWithRule(path) || getCompilerWithExt(ext, isRealTime)

#统一的处理
exports.execute = (compiler, source, options, cb)->
  if typeof options is 'function'
    cb = options
    options = {}

  #文件不存在
  return cb null, false if not _fs.existsSync source

  options.source = source
  relativePath = _path.relative _utils.options.workbench, source
  content = _utils.readFile source
  console.log "Compile #{relativePath} by #{compiler.name}"
  compiler.execute content, options, cb