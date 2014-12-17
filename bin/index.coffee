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
_version = require(_path.join(__dirname, '../package.json')).version

console.log "Silky Version -> #{_version}"

init = (options)->
  defaultOptions =
    workbench: process.cwd()
    version: _version
    language: 'en'

  #初始化
  _initialize _.extend(defaultOptions, options)
  #初始化插件模块
  require('../lib/plugin').init()
#检查silky是否有更新
_update.checkSilky _version

#安装插件的命令
_program.command('install [names...]')
.option('-g, --global', '安装到全局目录下')
.option('-d, --debug', '启动调试模式')
.description('安装插件')
.action((names, program)->
  init()
  _pluginPackage.install names, program.global
)

#卸载插件
_program.command('uninstall [names...]')
.description('卸载插件')
.option('-d, --debug', '启动调试模式')
.option('-g, --global', '卸载全局目录的插件')
.action((names, program)->
  init()
  _pluginPackage.uninstall names, program.global
)

#列出插件
_program.command('list')
.description('列出所有插件')
.option('-g, --global', '卸载全局目录的插件')
.action((program)->
  init()
  _pluginPackage.list program.global
)

#初始化项目
_program.command('init')
.option('-f, --force', '强制清除当前目录')
.option('-d, --debug', '启动调试模式')
.description('初始化目录')
.action((program)->
  init()
  samples = _path.join(__dirname, '..', 'samples')
  current = process.cwd()

  if _program.force
    _fs.copySync samples, current
    console.log "Silky项目初始化成功，示例项目已被创建".green
  else
    silkyDir = _path.join samples, _common.options.identity
    _fs.copySync silkyDir, _path.join(current, _common.options.identity)
    console.log "Silky项目初始化成功".green
  process.exit 0
)

_program.command('build')
.description('构建项目')
.option('-o, --output [value]', '指定输出目录')
.option('-d, --debug', '启动调试模式')
.option('-e, --environment [value]', '指定项目的运行环境，默认为 production')
.action((program)->
  options =
    #指定为build模式
    buildMode: true
    #输出目录
    output: _program.output
    #如果没有设置，build的时候，默认为production模式
    env:  _program.environment || 'production'
    #是否为debug模式
    debug: Boolean(_program.debug)

  options.language = _program.language if _program.language
  init options

  #保持silky一直运行，当然这并不是一个好方法
  setTimeout (-> console.log 'Timeout'), 1000 * 24 * 60 * 60
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
    port: _program.port || process.env.PORT || ''
    debug: Boolean(_program.debug)

  options.language = _program.language if _program.language

  #显示示例项目
  options.workbench = _path.join(__dirname, '..', 'samples') if program.sample
  init options

  #非合法的silky项目，警告用户
  if not _common.isSilkyProject()
    console.log("警告：当前工作区不是一个合法的Silky项目".cyan)

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

_program.version(_version).parse(process.argv)
#console.log "Debug model -> enable".red if _program.debug

