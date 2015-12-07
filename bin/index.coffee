#!/usr/bin/env coffee

_program = require('commander')
_fs = require('fs-extra')
_path = require('path')
_forever = require 'forever-monitor'
_os = require 'os'
_ = require 'lodash'
require 'colors'

_initialize = require '../lib/initialize'
_utils = require '../lib/utils'
_update = require '../lib/update'
_pluginPackage = require '../lib/plugin/package'
_build = require('../lib/build')
_hooks = require '../lib/plugin/hooks'
_hookHost = require '../lib/plugin/host'
_configure = require '../lib/configure'
_boilerplate = require '../lib/boilerplate'

_version = require(_path.join(__dirname, '../package.json')).version

console.log "Silky Version -> #{_version}"
console.log "Silky Root -> #{_path.dirname __dirname}"

init = (ops, loadPlugin)->
  defaultOptions =
    workbench: process.cwd()
    version: _version
    language: 'en'

  options = _.extend(defaultOptions, ops)
  #初始化
  _initialize options
  #检查silky是否有更新
  _update.checkSilky _version if options.checkSilky
  _update.checkConfig() if options.checkConfig

  #初始化插件模块
  require('../lib/plugin').init() if loadPlugin

#######################################插件相关#########################################
#安装插件的命令
_program.command('install [names...]')
.option('-d, --debug', '启动调试模式')
.option('-r, --repository', '强制指定安装源的git地址，请确保是否有clone的权限')
.option('-n, --npm [value]', '支持从指定镜像地址进行安装')
.description('安装插件')
.action((names, program)->
  init()

  return console.log("安装插件请使用：silky install [pluginName]".red) if names.length is 0
  _pluginPackage.install names, program.original, program.repository, program.npm, -> process.exit 0
)

#卸载插件
_program.command('uninstall [names...]')
.description('卸载插件')
.option('-d, --debug', '启动调试模式')
.action((names, program)->
  init()
  return console.log("卸载插件请使用：silky uninstall [pluginName]".red) if names.length is 0
  _pluginPackage.uninstall names, -> process.exit 0
)

#列出插件
_program.command('list')
.description('列出所有插件')
.action((program)->
  init()
  _pluginPackage.list()
  process.exit 0
)

#执行某个插件一次
_program.command('run [plugin]')
.description('运行某个插件')
.action((pluginName, program)->
  init(mergeLocalConfig: true)
  _pluginPackage.run pluginName, -> process.exit 0
)

#######################################配置相关#########################################
#修改配置
_program.command('config')
.command('set [value]', '设置键值，如果没有设置值，则会删除该键')
.option('remove', '删除某个键')
.option('-g, --global', '配置全局')
.description('修改或者查看配置文件')
.action((args..., program)->
  init()

  action = args[0]
  xPath = args[1]
  value = args[2]

  #设置honey的全局配置
  if action is 'team' and xPath is 'honey'
    _configure.setAsHoney()
    return process.exit 0

  #用户没有写xPath
  if action is 'set' and not xPath
    console.log "要配置的键不能为空".red
    return process.exit 1

#  if action is 'set' and not value
#    console.log "要配置的值不能为空".red
#    return process.exit 1

  if program.global
    globalPath = 'custom'
    globalPath += ".#{xPath}" if xPath
    xPath = globalPath

  switch action
    when 'set' then _configure.set xPath, value, program.global
    when 'get' then _configure.get xPath, program.global
    when 'remove' then _configure.set xPath, undefined, program.global

  process.exit 0
)

#######################################初始化项目相关#########################################
#初始化项目
_program.command('init')
.option('-f, --full', '复制完整示例项目')
#.option('-d, --debug', '启动调试模式')
.option('-p, --plugin', '创建插件的示例项目')
.description('创建一个Silky项目')
.action((name, program)->
  init()

  #当用户使用 silky init的时候
  if typeof name isnt 'string'
    program = name
    name = undefined

  return _boilerplate.initPlugin() if program.plugin

  #初始化示例项目
  _boilerplate.initSample name, program.full, (err)->
    console.log err.message.red if err
    process.exit ~~!!err
)

#######################################构建相关#########################################
_program.command('build')
.description('构建项目')
.option('-c, --config [value]', '指定配置文件')
.option('-o, --output [value]', '指定输出目录')
.option('-d, --debug', '启动调试模式')
.option('-f, --force', '强行构建当前目录，适用于编译非Silky项目')
.option('-e, --environment [value]', '指定项目的运行环境，默认为 production')
.option('-x, --extra [value]', '用于扩展的参数，根据不同插件要求不同')
.allowUnknownOption()
.action((program)->
  options =
    original:
      env: program.environment
    #用于扩展的命令行参数，提供给插件使用
    extra: program.extra
    #指定为build模式
    buildMode: true
    #如果没有设置，build的时候，默认为production模式
    env:  program.environment || 'production'
    #是否为debug模式
    debug: Boolean(program.debug)
    #特殊指定的配置文件
    config: program.config
    #build时需要合并本地配置
    mergeLocalConfig: true

  options.language = program.language if program.language
  init options, true

  #输出目录
  output = program.output || _utils.config.build.output || './build'
  output = _path.resolve _utils.options.workbench, output
  _utils.options.output = output

  if not _utils.isSilkyProject()
    message = if program.force then "提示：当前构建的目录非Silky目录".cyan else ""
    return console.log message

  #保持silky一直运行，当然这并不是一个好方法
  setTimeout (-> console.log 'Timeout'), 1000 * 24 * 60 * 60

  #触发事件再构建
  _hookHost.triggerHook _hooks.build.initial, (err)->
    #执行构建
    _build.execute ()->
      console.log('项目构建完成')
      process.exit 0
)

#######################################缓存相关#########################################
_program
.command('cache')
.option('clean', '清除所有的缓存')
#.option('-v, --view', '查看缓存的目录')
.action((arg1)->
  init()
  #清除缓存
  _utils.cleanCache() if arg1 is 'clean'

  process.exit 0
)

_program
.command('start')
.description('启动Silky服务')
.option('-l, --language', '指定输出的语言，默认为en')
.option('-p, --port <n>', '指定运行端口')
.option('-s, --sample', '查看示例项目')
.option('-e, --environment [value]', '指定项目的运行环境，默认为 development')
.option('-d, --debug', '启动调试模式')
.option('-x, --extra [value]', '用于扩展的参数，根据不同插件要求不同')
.action((program)->
  options =
    #参数中提供的端口
    port: program.port || process.env.PORT || '14422'
    debug: Boolean(program.debug)
    env: program.environment
    #用于扩展的命令行参数，提供给插件使用
    extra: program.extra
    #合并本地配置
    mergeLocalConfig: true
    #检查silky的更新
    updateSilky: true
    #检查配置文件的更新
    updateConfig: true

  options.language = program.language if program.language

  #显示示例项目
  options.workbench = _path.join(__dirname, '..', 'samples') if program.sample
  init options, true

  #非合法的silky项目，警告用户
  if not _utils.isSilkyProject()
    console.log("警告：当前工作区不是一个合法的Silky项目".cyan)

  #触发事件再启动服务
  _hookHost.triggerHook _hooks.route.initial, (err)->
    #启动app
    app = require('express')()
    server = require('http').createServer app
    silky = require '../lib/index'
    silky(app, server, true)

#  #暂时放弃forever的方式
#  if true or _os.platform() is 'win32'
#    global.SILKY = options
#    require '../lib/app.coffee'
#    return

#  自动重启功能，暂时放弃
#  file = _path.join __dirname, '../lib/app.coffee'
#  child = new(_forever.Monitor)(file, {
#  #logFile: '/Users/conis/temp/silky.log',
#    max: 100,
#    command: 'coffee'
#    silent: true,
#    env: options
#  })
#
#  child.on 'stdout', (data)->
#    console.log String(data)
#
#    child.on 'stderror', (data)-> console.log String(data)
#
#  child.on 'error', ()->
#    console.log 'Error'.red
#    console.log arguments
#
#  child.on 'start', ()-> console.log 'Silky已经启动'.green
#  child.on 'restart', ()-> console.error "OOPS，Silky第#{child.times}重启了".red
#
#  child.on 'exit', ()-> console.log '发生严重错误，Silky重启超过100次'.red
#
#  child.start()
)

#版本和描述
versionDesc = "Version: #{_version}; Silky: #{_path.join __dirname, '..'}"
_program.version(versionDesc).parse(process.argv)

#提示用户需要使用start进行启动
(->
  mustIncludeCommand = ['start', 'build', 'install', 'uninstall', 'list', 'config', 'cache', 'run']
  if _.difference(_program.rawArgs, mustIncludeCommand).length is _program.rawArgs.length
    console.log "提示：新版本的silky请使用silky start启动".cyan
)()

#console.log "Debug model -> enable".red if _program.debug

