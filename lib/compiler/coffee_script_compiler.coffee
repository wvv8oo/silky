###
    处理js和coffee
###
_path = require 'path'
_utils = require '../utils'
_fs = require 'fs'
_coffee = null
_convertSourceMap = null

_compilerMgr = require './compiler_manager'

#编译coffee
coffeeHandler = (content, options, cb)->
	_coffee = require 'coffee-script' if not _coffee
	_convertSourceMap = require 'convert-source-map' if not _convertSourceMap

	compilerOptions =
		filename: _path.basename(options.source)
		sourceMap: true
	compiledObj = _coffee.compile content, compilerOptions
	compiledJs = compiledObj.js

	#开发模式下，加入source map
	if _utils.isDevelopment()
		sourceMapObj = {
			version: 3,
			file:  _path.basename(_utils.replaceExt(options.source + '.js')),
			sources: [_path.basename(options.source)],
			names: [],
			mappings: JSON.parse(compiledObj.v3SourceMap).mappings
		}
		sourceMapStr = _convertSourceMap.fromObject(sourceMapObj).toComment()
		compiledJs += '\n' + sourceMapStr

	cb null, compiledJs


module.exports = _compilerMgr.registerCompiler('coffee', 'coffee', 'js', coffeeHandler)