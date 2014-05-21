#!/usr/bin/env coffee

_program = require('commander')
_fs = require('fs-extra')
_path = require('path')
_initialize = require '../lib/initialize'
require 'colors'

_program
    .version(require(_path.join(__dirname, '../package.json')).version)
    .option('init', '初始化一个项目')
    .option('build', '打包项目')
    .option('-f, --full', '创建silky项目及示例项目')
    .option('-p, --port <n>', '指定运行端口')
    .option('-o, --output <value>', '打包指定输出目录')
    .option('-e, --environment [value]', '指定项目的运行环境，默认为[development]')
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

    _initialize options
    #执行构建
    require('../lib/build').execute ()->
        console.log('项目已被成功地构建')
        process.exit 0

#实时运行项目
runtime = ()->
    options =
        #设置全局的环境参数
        workbench: process.cwd()
        #工作环境
        env: _program.environment || 'development'
        #参数中提供的端口
        port: _program.port

    _initialize options
    #执行app
    require('../lib/app')




#将示例项目复制到当前目录
return initSilkyProject() if _program.init
#构建一个silky项目
return buildSilkyProject() if _program.build

runtime()
