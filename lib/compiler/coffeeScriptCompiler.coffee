###
    处理js和coffee
###
_path = require 'path'
_utils = require '../utils'
_coffee = require 'coffee-script'
_fs = require 'fs'
_convertSourceMap = require 'convert-source-map'

#编译coffee
exports.compile = (source, relativeSource, options, cb)->
    fileType = 'js'
    #文件不存在
    return cb null, false if not _fs.existsSync source

    content = _utils.readFile(source)
    #对于js文件，直接返回内容即可
    return cb null, content, fileType if /\.js$/i.test source

    console.log "Compile #{relativeSource} by coffee compiler"
    compilerOptions =
        filename: _path.basename(source)
        sourceMap: true

    compiledObj = _coffee.compile content, compilerOptions
    compiledJs = compiledObj.js

    #开发模式下，加入source map
    if _utils.isDevelopment()
        sourceMapObj = {
            version: 3,
            file:  _path.basename(_utils.replaceExt source + '.js'),
            sources: [_path.basename(source)],
            names: [],
            mappings: JSON.parse(compiledObj.v3SourceMap).mappings
        }
        sourceMapStr = _convertSourceMap.fromObject(sourceMapObj).toComment()
        compiledJs += '\n' + sourceMapStr

    cb null, compiledJs, fileType