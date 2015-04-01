#!/usr/bin/env coffee

_program = require('commander')
_fs = require('fs-extra')
_path = require('path')
_forever = require 'forever-monitor'
_os = require 'os'
_ = require 'lodash'
require 'colors'

_initialize = require '../lib/initialize'
_common = require '../lib/common'
_update = require '../lib/update'
_pluginPackage = require '../lib/plugin/package'
_build = require('../lib/build')
_hooks = require '../lib/plugin/hooks'
_hookHost = require '../lib/plugin/host'
_configure = require '../lib/configure'

_version = require(_path.join(__dirname, '../package.json')).version

console.log "Silky Version -> #{_version}"
console.log "Silky Root -> #{_path.dirname __dirname}"

init = (options, loadPlugin)->
  defaultOptions =
    workbench: process.cwd()
    version: _version
    language: 'en'

  #初始化
  _initialize _.extend(defaultOptions, options)
  #检查silky是否有更新
  _update.checkSilky _version
  _update.checkConfig()
  #初始化插件模块
  require('../lib/plugin').init() if loadPlugin

#安装插件的命令
_program.command('install [names...]')
.option('-d, --debug', '启动调试模式')
.description('安装插件')
.action((names, program)->
  init()
  return console.log("安装插件请使用：silky install [pluginName]".red) if names.length is 0
  _pluginPackage.install names, program.original, -> process.exit 0
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

#修改配置
_program.command('config')
.command('set [value]', '设置键值，如果没有设置值，则会删除该键')
.option('-g, --global', '配置全局')
.option('remove', '删除某个键')
.description('修改配置文件')
.action((args..., program)->
  init()

  action = args[0]
  xPath = args[1]
  value = args[2]

  #用户没有写xPath
  if not xPath
    console.log "要配置的键不能为空".red
    return process.exit 1

  if action is 'set' and not value
    console.log "要配置的值不能为空".red
    return process.exit 1

  xPath = "custom.#{xPath}" if program.global
  switch action
    when 'set' then _configure.set xPath, value, program.global
    when 'remove' then _configure.set xPath, undefined, program.global

  process.exit 0
)

#初始化项目
_program.command('init')
.option('-f, --full', '复制完整示例项目')
.option('-d, --debug', '启动调试模式')
.option('-p, --plugin', '创建插件的示例项目')
.description('创建一个Silky项目')
.action((program)->
  init()
  source = _path.join(__dirname, '..', 'samples')
  current = process.cwd()

  #复制插件的示例项目
  if program.plugin
    source = _path.join source, 'plugin'
    _fs.copySync source, current
    return process.exit 0

  #复制Silky的示例项目
  source = _path.join source, 'default'
  if program.full
    _fs.copySync source, current
    console.log "Silky项目初始化成功，示例项目已被创建".green
  else
    silkyDir = _path.join source, _common.options.identity
    _fs.copySync silkyDir, _path.join(current, _common.options.identity)
    console.log "Silky项目初始化成功".green
  process.exit 0
)

_program.command('build')
.description('构建项目')
.option('-c, --config [value]', '指定配置文件')
.option('-o, --output [value]', '指定输出目录')
.option('-d, --debug', '启动调试模式')
.option('-f, --force', '强行构建当前目录，适用于编译非Silky项目')
.option('-e, --environment [value]', '指定项目的运行环境，默认为 production')
.option('-x, --extra [value]', '用于扩展的参数，根据不同插件要求不同')
.action((program)->
  options =
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

  options.language = program.language if program.language
  init options, true

  #输出目录
  output = program.output || _common.config.build.output || './build'
  output = _path.resolve _common.options.workbench, output
  _common.options.output = output

  if not _common.isSilkyProject()
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

_program
.command('start')
.description('启动Silky服务')
.option('-l, --language', '指定输出的语言，默认为en')
.option('-p, --port <n>', '指定运行端口')
.option('-s, --sample', '查看示例项目')
.option('-e, --environment [value]', '指定项目的运行环境，默认为 development')
.option('-d, --debug', '启动调试模式')
.action((program)->
  options =
    #参数中提供的端口
    port: program.port || process.env.PORT || ''
    debug: Boolean(program.debug)
    env: program.environment

  options.language = program.language if program.language

  #显示示例项目
  options.workbench = _path.join(__dirname, '..', 'samples') if program.sample
  init options, true

  #非合法的silky项目，警告用户
  if not _common.isSilkyProject()
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

(->
  mustIncludeCommand = ['start', 'build', 'install', 'uninstall', 'list', 'config']
  if _.difference(_program.rawArgs, mustIncludeCommand).length is _program.rawArgs.length
    console.log "提示：新版本的silky请使用silky start启动".cyan
)()

#console.log "Debug model -> enable".red if _program.debug

