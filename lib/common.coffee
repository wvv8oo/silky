###
    全局配置
###
_events = require 'events'
_watch = require 'watch'
_fs = require 'fs-extra'
_path = require 'path'
require 'colors'
_ = require 'lodash'
_plugin = require './plugin'
_update = require './update'

#用户传入的配置信息
_options = null

#  #如果在workbench中没有找到.silky的文件夹，则将目录置为silky的samples目录
#  if not workbench or not _fs.existsSync _path.join(workbench, exports.identity)
#    workbench = _path.join __dirname, '..', 'samples'
readConfig = ()->
  globalConfig = {}
  localConfig = {}

  #读取配置文件
  configFileName = 'config.js'
  #读取全局配置文件
  globalConfigFile = _path.join exports.globalSilkyIdentityDir(), configFileName
  globalConfig = require(globalConfigFile) if _fs.existsSync globalConfigFile

  #工作文件夹的配置文件
  localConfigFile = _path.join exports.identityDir(), configFileName
  #如果当前项目文件夹没有配置，则加载默认的配置
  if not _fs.existsSync localConfigFile
    localConfigFile = _path.join(__dirname, 'default_config')

  localConfig = require(localConfigFile)

  #用本地配置覆盖全局配置
  _.extend globalConfig, localConfig

exports.globalSilkyIdentityDir = ()-> _path.join exports.homeDirectory(), exports.options.identity
#检查工作目录是否为合法的silky目录
exports.isSilkyProject = ()->
  _fs.existsSync exports.identityDir()

#获取identity的目录
exports.identityDir = ()-> _path.join _options.workbench, _options.identity

#获取工作区的插件目录
exports.workbenchPluginDirectory = ()->
  _path.join exports.identityDir(), 'plugin'

#获取全局的插件目录
exports.globalPluginDirectory = ()->
  _options.globalPluginDirectory || _path.join(exports.globalSilkyIdentityDir(), 'plugin')

#用户的home目录
exports.homeDirectory = ()->
  process.env[if process.platform is 'win32' then 'USERPROFILE' else 'HOME']

#判断是否为产品环境
exports.isProduction = ()->
  _options.env is 'production'

#如果是产品环境，则报错，否则返回字符
exports.combError = (error)->
  #如果是产品环境，则直接抛出错误退出
  if this.isProduction()
      console.log 'Error:'.red
      console.log error
      process.exit 1
      return
  error

#替换扩展名为指定的扩展名
exports.replaceExt = (file, ext)-> file.replace _path.extname(file), ext
#读取文件
exports.readFile = (file)-> _fs.readFileSync file, 'utf-8'
#保存文件
exports.writeFile = (file, content)-> _fs.outputFileSync file, content
#获取模板文件，针对于旧版本的silky
exports.getTemplateDir = ()-> _path.join _options.workbench, 'template'
#替换掉slash，所有奇怪的字符
exports.replaceSlash = (file)-> file.replace(/\W/ig, "_")

#初始化
exports.init = (options)->
  _options =
    env: 'development'
    workbench: null
    buildMode: false

  _.extend _options, options
  _options.identity = '.silky'
  exports.options = _options
  exports.config = readConfig()

#x.y.x这样的文本式路径，从data中找出对应的值
exports.xPathMapValue = (xPath, data)->
  value = data
  xPath.split('.').forEach (key)->
    return if not (value = value[key])
  value

#简单的匹配，支持绝对匹配，正则匹配，以及匿名函数匹配
exports.simpleMatch = (rules, value)->
  return false if not rules
  rules = [rules] if not (rules instanceof Array)
  result = false
  for rule in rules
    if rule instanceof RegExp   #正则匹配
      result = rule.test(value)
    else if typeof rule is 'function'
      result = rule(value)
    else
      result = rule is value

    return result if result

  false

exports.debug = (message)->
  return if not _options.debug
  console.log message