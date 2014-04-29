#!/usr/bin/env coffee

_program = require('commander')
_fs = require('fs')
_path = require('path')
_common = require '../lib/common'
require 'colors'

_program
    .version(JSON.parse(_fs.readFileSync(_path.join(__dirname, '..', 'package.json'), 'utf8')).version)
    .option('build', '打包项目')
    .option('-p, --port <n>', '指定运行端口')
    .option('-o, --output <value>', '打包指定输出目录')
    .option('-e, --environment [value]', '指定项目的运行环境，默认为[development]')
    .parse(process.argv)

#设置全局的环境参数
identity = '.silky'
workbench = process.cwd()
workbench = _path.join(__dirname, '..', 'samples') if not _fs.existsSync _path.join(process.cwd(), identity)

global.SILKY =
    #识别为silky目录
    identity: identity
    #工作环境
    env: _program.environment || 'development'
    #工作目录
    workbench: workbench
    #配置文件
    config: _path.join workbench, identity, 'config.js'

#引入配置文件
_config = require SILKY.config
global.SILKY.data = _path.join(workbench, identity, SILKY.env)
global.SILKY.port = _program.port || _config.port || 14422
_common.init()
#初始化数据及路由
require('../lib/data').init()
require('../lib/template').init()

#在当前目录下查找.silky文件，如果找不到则将主目录切换为系统安装目录
console.log "工作目录：#{SILKY.workbench}".green

#打包
if _program.build
    #设置为build模式
    global.SILKY.buildMode = true
    global.SILKY.output = _path.resolve SILKY.workbench, (_program.output || _config.build.output)
    #如果没有设置，build的时候，默认为production模式
    global.SILKY.env =  _program.environment || 'production'
    console.log "工作环境：#{SILKY.env}".green

    #执行构建
    require('../lib/build').execute ()->
        console.log('项目已被成功地构建')
        process.exit 0
    return      #阻止运行

#非打包环境，直接运行
console.log "工作环境：#{SILKY.env}".green
_app = require('../lib')
