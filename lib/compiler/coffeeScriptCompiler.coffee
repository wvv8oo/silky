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
    #编译coffee
    file = _path.join _utils.replaceExt source, '.coffee'

    #文件不存在
    return cb null, false if not _fs.existsSync file

    compilerOptions =
        filename: _path.basename(file)
        sourceMap: true

    compiledObj = _coffee.compile _utils.readFile(file), compilerOptions
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

    fileType = 'js'
    compiledJs = options.onCompiled compiledJs, fileType if options.onCompiled

    #如果需要保存编译后的文件
    if options.save and options.target
        target = _utils.replaceExt options.target, fileType
        _utils.writeFile target, compiledJs

    cb null, compiledJs, target, 'js'
