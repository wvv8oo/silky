###
    全局配置
###
_events = require 'events'
_watch = require 'watch'
_fs = require 'fs-extra'
_path = require 'path'
_ = require 'lodash'
_plugin = require './plugin'
_update = require './update'
_object2string = require './object2string'
_beautify = require('js-beautify').js_beautify

require 'colors'

#用户传入的配置信息
_options = null

#  #如果在workbench中没有找到.silky的文件夹，则将目录置为silky的samples目录
#  if not workbench or not _fs.existsSync _path.join(workbench, exports.identity)
#    workbench = _path.join __dirname, '..', 'samples'
readConfig = ->
  globalConfig = {}
  localConfig = {}

  #读取全局配置文件
  globalConfigFile = exports.globalConfigFile()
  globalConfig = require(globalConfigFile) if _fs.existsSync globalConfigFile
  exports.globalConfig = globalConfig

  #工作文件夹的配置文件
  #指定了配置文件的路径
  if _options.config
    localConfigFile = _path.resolve __dirname, _options.config
  else
    localConfigFile = exports.localConfigFile()

  console.log "配置文件路径 -> #{localConfigFile}"

  #如果当前项目文件夹没有配置，则加载默认的配置
  if not _fs.existsSync localConfigFile
    console.log "没有找到配置文件，加载配置默认的配置文件"
    localConfigFile = _path.join(__dirname, 'default_config')

  localConfig = require(localConfigFile)

  #复制global config中的custom节点
  globalCustom = _.extend {}, globalConfig.custom
  #合并本地配置到全局配置
  _.extend globalCustom, localConfig

#全局配置文件的路径
exports.globalConfigFile = -> _path.join exports.globalSilkyIdentityDir(), 'config.js'
#本地配置的文件路径
exports.localConfigFile = -> _path.join exports.localSilkyIdentityDir(), 'config.js'

#保存全局配置
exports.saveGlobalConfig = ()->
  exports.saveObjectAsCode exports.globalConfig, exports.globalConfigFile()

#全局的siky目录
exports.globalSilkyIdentityDir = -> _path.join exports.homeDirectory(), exports.options.identity
#仓库的缓存目录
exports.globalCacheDirectory = -> _path.join exports.globalSilkyIdentityDir(), '.cache'

#检查工作目录是否为合法的silky目录
exports.isSilkyProject = ->
  local = exports.localSilkyIdentityDir()
  global = exports.globalSilkyIdentityDir()
  #当前.silky非全局.silky，且存在.silky才被认为是silky项目
  local isnt global and _fs.existsSync(exports.localSilkyIdentityDir())

#获取identity的目录
exports.localSilkyIdentityDir = -> _path.join _options.workbench, _options.identity

#获取全局的插件目录
exports.globalPluginDirectory = ->
  _options.globalPluginDirectory || _path.join(exports.globalSilkyIdentityDir(), 'plugin')
#用户的home目录
exports.homeDirectory = ->
  process.env[if process.platform is 'win32' then 'USERPROFILE' else 'HOME']


#判断是否为产品环境
exports.isProduction = ->
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
exports.getTemplateDir = -> _path.join _options.workbench, 'template'
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

#保存对象为代码文件
exports.saveObjectAsCode = (object, file)->
  content = _object2string object
  content = "module.exports = #{content}"
  content = _beautify(content, { indent_size: 2 })
  exports.writeFile file, content

exports.debug = (message)->
  return if not _options.debug
  console.log message
