###
    处理js和coffee
###
_path = require 'path'
_utils = require '../utils'
_coffee = require 'coffee-script'
_fs = require 'fs'
_convertSourceMap = require 'convert-source-map'

#编译coffee
exports.compiler = (source, options, cb)->
    #如果是js文件，则直接返回
    return _utils.readFile source if _path.extname(source) is '.js'

    #编译coffee
    file = _path.join _utils.replaceExt source, '.coffee'
    #文件不存在
    return null if not _fs.existsSync source

    options =
        filename: _path.basename(file)
        sourceMap: true

    compiledObj = _coffee.compile _utils.readFile(file), options
    compiledJs = compiledObj.js

    #开发模式下，加入source map
    if _utils.isDevelopment()
        sourceMapObj = {
            version: 3,
            file:  _path.basename(_utils.replaceExt source + '.js'),
            sources: [_path.basename(file)],
            names: [],
            mappings: JSON.parse(compiledObj.v3SourceMap).mappings
        }
        sourceMapStr = _convertSourceMap.fromObject(sourceMapObj).toComment()
        compiledJs += '\n' + sourceMapStr

    #如果
    _utils.writeFile options.target, compiledJs if options.save and options.target
    cb null, compiledJs