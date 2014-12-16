#!/usr/bin/env coffee

_program = require('commander')
_fs = require('fs-extra')
_path = require('path')
_forever = require 'forever-monitor'
_os = require 'os'
require 'colors'

_initialize = require '../lib/initialize'
_update = require '../lib/update'

_version = require(_path.join(__dirname, '../package.json')).version

#检查silky是否有更新
_update.checkSilky _version

_program
.version(_version)
.option('init', '初始化一个项目')
.option('build', '打包项目')
.option('-l, --language', '指定输出的语言，默认为en')
.option('-f, --full', '创建silky项目及示例项目')
.option('-p, --port <n>', '指定运行端口')
.option('-o, --output <value>', '打包指定输出目录')
.option('-e, --environment [value]', '指定项目的运行环境，默认为[development]')
.option('-d, --debug', '以debug的方式运行，这将会输出大量的日志')
.parse(process.argv)

#初始化silky项目
initSilkyProject = ()->
  identity = '.silky'
  samples = _path.join(__dirname, '..', 'samples')
  current = process.cwd()

  if _program.full
    _fs.copySync samples, current
    console.log "Silky项目初始化成功，示例项目已被创建".green
  else
    silkyDir = _path.join samples, identity
    _fs.copySync silkyDir, _path.join(current, identity)
    console.log "Silky项目初始化成功".green
  process.exit 1


#构建一个silky项目
buildSilkyProject = ()->
  #设置为build模式
  options =
    workbench: process.cwd()
    #指定为build模式
    buildMode: true
    #输出目录
    output: _program.output
    #如果没有设置，build的时候，默认为production模式
    env:  _program.environment || 'production'
    #指定语言
    language: _program.language || 'en'
    debug: Boolean(_program.debug)

  _initialize options

  #保持silky一直运行，当然这并不是一个好方法
  setTimeout (-> console.log 'Timeout'), 1000 * 24 * 60 * 60
  #执行构建
  require('../lib/build').execute ()->
    console.log('项目构建完成')
    process.exit 0

#实时运行项目
runtime = ()->
  options =
    #设置全局的环境参数
    WORKBENCH: process.cwd()
    #工作环境
    NODE_ENV: _program.environment || process.env.NODE_ENV || 'development'
    #参数中提供的端口
    PORT: _program.port || process.env.PORT || ''
    LANG: _program.language || 'en'
    DEBUG: Boolean(_program.debug)

  #暂时不使用forever
  if _os.platform() is 'win32' or true
    global.SILKY = options
    require '../lib/app.coffee'
    return

  file = _path.join __dirname, '../lib/app.coffee'
  child = new(_forever.Monitor)(file, {
  #logFile: '/Users/conis/temp/silky.log',
    max: 100,
    command: 'coffee'
    silent: true,
    env: options
  })

  child.on 'stdout', (data)->
    console.log String(data)

    child.on 'stderror', (data)-> console.log String(data)

  child.on 'error', ()->
    console.log 'Error'.red
    console.log arguments

  child.on 'start', ()-> console.log 'Silky已经启动'.green
  child.on 'restart', ()-> console.error "OOPS，Silky第#{child.times}重启了".red

  child.on 'exit', ()-> console.log '发生严重错误，Silky重启超过100次'.red


  child.start()

console.log "Silky Version->#{_version}"
console.log "Debug model -> enable".red if _program.debug

#将示例项目复制到当前目录
return initSilkyProject() if _program.init
#构建一个silky项目
return buildSilkyProject() if _program.build

runtime()
