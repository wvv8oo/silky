#!/usr/bin/env coffee

_program = require('commander')
_fs = require('fs')
_path = require('path')
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
workbench = _path.join(__dirname, '../', 'samples') if not _fs.existsSync _path.join(process.cwd(), identity)

global.SILKY =
    #识别为silky目录
    identity: identity
    #工作环境
    env: _program.environment || 'development'
    #端口
    port: _program.port
    #工作目录
    workbench: workbench
    #配置文件
    config: _path.join workbench, identity, 'config.js'

global.SILKY.data = _path.join(workbench, identity, SILKY.env)

#在当前目录下查找.silky文件，如果找不到则将主目录切换为系统安装目录
console.log "工作目录：#{SILKY.workbench}".green
console.log "工作环境：#{SILKY.env}".green

#打包
if _program.build
    require('../lib/build').execute()
    return

#非打包环境，直接运行
_app = require('../lib')
