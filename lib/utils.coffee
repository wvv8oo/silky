###
    全局配置
###
_events = require 'events'
_watch = require 'watch'
_fs = require 'fs-extra'
_path = require 'path'
_ = require 'lodash'
_child = require 'child_process'

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

  localConfigFile = exports.localConfigFile()
  console.log "配置文件路径 -> #{localConfigFile}"

  #如果当前项目文件夹没有配置，则加载默认的配置
  if not _fs.existsSync localConfigFile
    console.log "没有找到配置文件，加载配置默认的配置文件"
    localConfigFile = _path.join(__dirname, 'default_config.coffee')

  localConfig = require(localConfigFile)

  #复制global config中的custom节点
  globalCustom = _.extend {}, globalConfig.custom
  #合并本地配置到全局配置
  exports.config = _.extend globalCustom, localConfig

  #合并默认的编译器
  defaultCompiler =
    html: 'hbs'
    css: 'less'
    js: 'coffee'
  exports.config.compiler = _.extend defaultCompiler, exports.config.compiler

#全局配置文件的路径
exports.globalConfigFile = -> _path.join exports.globalSilkyIdentityDir(), 'config.js'

#本地配置的文件路径
exports.localConfigFile = ()->
  _path.resolve exports.localSilkyIdentityDir(), _options.config || 'config.js'

#保存全局配置
exports.saveGlobalConfig = ()->
  exports.saveObjectAsCode exports.globalConfig, exports.globalConfigFile()

#全局的siky目录
exports.globalSilkyIdentityDir = -> _path.join exports.homeDirectory(), exports.options.identity
#仓库的缓存目录
exports.globalCacheDirectory = (dir = '')->
  _path.join exports.globalSilkyIdentityDir(), '.cache', dir

#检查工作目录是否为合法的silky目录
exports.isSilkyProject = ->
  local = exports.localSilkyIdentityDir()
  global = exports.globalSilkyIdentityDir()
  #当前.silky非全局.silky，且存在.silky才被认为是silky项目
  local isnt global and _fs.existsSync(exports.localSilkyIdentityDir())

#获取identity的目录
exports.localSilkyIdentityDir = -> _path.join _options.workbench, _options.identity

#获取语言的文件夹
exports.languageDirectory = -> _path.join(exports.localSilkyIdentityDir(), 'language', _options.language)

#获取全局的插件目录
exports.globalPluginDirectory = ->
  dir = exports.xPathMapValue("custom.globalPluginDirectory", exports.globalConfig)
  dir || _path.join(exports.globalSilkyIdentityDir(), 'plugin')

#用户的home目录
exports.homeDirectory = ->
  process.env[if process.platform is 'win32' then 'USERPROFILE' else 'HOME']

#示例项目的目录
exports.samplesDirectory = (dir = '')->
  _path.join(__dirname, '..', 'samples', dir)

#判断是否为产品环境
exports.isProduction = -> _options.env is 'production'

exports.isDevelopment = -> _options.env is 'development'

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
exports.replaceExt = (file, ext)->
  ext = ".#{ext}" if not /^\./.test ext
  file.replace _path.extname(file), ext

#读取文件
exports.readFile = (file)-> _fs.readFileSync file, 'utf-8'
#保存文件
exports.writeFile = (file, content)-> _fs.outputFileSync file, content
#获取模板文件，针对于旧版本的silky
exports.getTemplateDir = -> _path.join _options.workbench, 'template'
#替换掉slash，所有奇怪的字符
exports.replaceSlash = (file)-> file.replace(/\W/ig, "_")

#监控文件，但在监控之前会检查文件是否存在
exports.watch = (path, cb)->
  #文件不存在，不需要监控
  return if not _fs.existsSync path
  #检查文件类型
  stat = _fs.statSync path
  if not stat.isDirectory()
    return _fs.watchFile path, -> cb path

  #监控文件夹
  _watch.watchTree path, (f, curr, prev)->
    return if typeof f is "object" && prev is null && curr is null
    type =
      if prev is null then 'new'
      else if curr.nlink is 0 then 'remove'
      else 'change'

    cb f, type

#初始化
exports.init = (options)->
  _options =
    env: 'development'
    workbench: null
    buildMode: false
    livereload: 'http://localhost:35729/livereload.js'

  _.merge _options, options
  _options.identity = '.silky'
  exports.options = _options

  _options.globalSilkyIdentityDir = exports.globalSilkyIdentityDir()
  readConfig()

  #监控配置文件的变化
  exports.watch exports.globalConfigFile(), readConfig
  exports.watch exports.localConfigFile(), readConfig

#x.y.x这样的文本式路径，从data中找出对应的值
exports.xPathMapValue = (xPath, root)->
  value = root
  return undefined if not xPath

  _.forEach xPath.split('.'), (key)->
    return false if not (value = value[key])

  value

##设置xPath，不支持数组
exports.xPathSetValue = (xPath, root, value)->
  node = root

  paths = xPath.split('.')
  last = paths.pop()

  _.forEach paths, (key)->
    if not node.hasOwnProperty(key)
      node = node[key] = {}
    else
      node = node[key]

  #最后一级的父节点，必需存在，且为hash
  return false if not (node and _.isPlainObject(node))
  if value is undefined  then delete node[last] else node[last] = value


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

#根据文件路径或者url，判断文件类型
exports.detectFileType = (path)->
  extname = _path.extname(path).toLowerCase()
  return 'html' if extname in ['.html', '.htm']
  #不包含.的，默认为一个文件夹
  return 'dir' if not /\./.test extname
  #替换掉.，返回扩展名
  return extname.replace('.', '')

#  if /(\.(html|html))$/.test(path) then 'html'
#  else if /\.css$/.test(path) then 'css'
#  else if /\.js$/.test(path) then 'js'
#  else if /(^\/$)|(\/[^\.]+$)/.test(path) then 'dir'
#  else 'other'

#复制文件
exports.copyFile = (source, target, cb)->
  _fs.copySync source, target
  cb? null

#执行命令，返回结果以及错误
exports.execCommand = (command, cb)->
  options =
    env: process.env
    maxBuffer: 20*1024*1024
  message = ''
  error = ''

  console.log "执行命令 -> #{command}"
  exec = _child.exec command, options
  exec.on 'close', (code)->
    cb code, message, error

  exec.stdout.on 'data',  (chunk)->
    console.log chunk
    message += chunk + '\n'

  exec.stderr.on 'data', (chunk)->
    console.log chunk
    error += chunk + '\n'

#更新仓库，如果仓库不存在，则clone仓库
exports.updateGitRepos = (remoteRepos, localRepos, cb)->
  console.log "正在同步git仓库..."
  #目录已经存在，则clone
  if _fs.existsSync localRepos
    command = "cd \"#{localRepos}\" && git pull origin master"
  else
    command = "git clone \"#{remoteRepos}\" \"#{localRepos}\""

  exports.execCommand command, (code)->
    console.log "同步git仓库完成"
    cb code

#清除缓存
exports.cleanCache = ()->
  dir = exports.globalCacheDirectory()
  _fs.removeSync dir
  console.log "缓存清除完毕 -> #{dir}".green

#honey的配置
exports.honeyConfig =
  'boilerplateRepository': 'http://git.hunantv.com/honey-lab/silky-boilerplate.git'
  'pluginRepository': 'http://git.hunantv.com/honey-lab/silky-plugins.git'