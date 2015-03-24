###
    处理js和coffee
###
_path = require 'path'
_common = require '../common'
_coffee = require 'coffee-script'
_fs = require 'fs'
_convertSourceMap = require 'convert-source-map'


exports.compile = (file)->
    #如果是js文件，则直接返回
    return _common.readFile file if _path.extname(file) is '.js'

    #编译coffee
    file = _path.join _common.replaceExt file, '.coffee'
    #文件不存在
    return null if not _fs.existsSync file

    options =
        filename: _path.basename(file)
        sourceMap: true

    compiledObj = _coffee.compile _common.readFile(file), options

    sourceMapObj = {
        version: 3,
        file:  _path.basename(_common.replaceExt file, '.js'),
        sources: [_path.basename(file)],
        names: [],
        mappings: JSON.parse(compiledObj.v3SourceMap).mappings
    }

    compiledJs = compiledObj.js
    if _common.isDevelopment()
        sourceMapStr = _convertSourceMap.fromObject(sourceMapObj).toComment()
        compiledJs += '\n' + sourceMapStr

    compiledJs