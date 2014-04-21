#!/usr/bin/env coffee

_program = require('commander')
_fs = require('fs')
_path = require('path')

_program
    .version(JSON.parse(_fs.readFileSync(_path.join(__dirname, '..', 'package.json'), 'utf8')).version)
    .option('-b, --build', '打包项目')
    #.usage('[debug] [options] [files]')
    .option('-r, --root', '指定项目的根目录')
    .option('-e, --environment', '指定项目的运行环境，默认为[development]')
    .option('-w, --watch', '实时监控文件变化并build，一般不建议')
    .parse(process.argv);

_program.name = 'silky'

console.log('a')
