#    Author: 易晓峰
#    E-mail: wvv8oo@gmail.com
#    Date: 9/6/15 3:04 PM
#    Description: 管理编译器列表

_mime = require 'mime'
_ = require 'lodash'

_utils = require '../utils'

#编译器列表
COMPILERS = {}

class Compiler
	rule: null
	#编译器的名称
	name: 'abstract'

	#根据路径来确定当前编译器是否符合规则
	isMatch: (ext, isRealTime)->
		currentRule = if isRealTime then @rule.route else @rule.build
		return false if not currentRule
		_utils.simpleMatch currentRule.captureExt, ext, true

	constructor: (@name, handler)-> @execute = handler

#根据指定类型和源文件的扩展名获取简单的规则，type为css/html/js之一
getRuleWithType = (sourceExt, type)->
	#与路由相关
	route:
		#捕获路由中使用的扩展名
		captureExt: [type]
		#源文件实对应实际文件的扩展名
		replaceExt: sourceExt
		#返回数据时对应的mime
		mime: _mime.lookup(type)
	#与构建相关
	build:
		#构建时捕获的扩展名
		captureExt: [sourceExt]
		#最终保存时的扩展名
		replaceExt: type

#注册一个编译器到编译器列表
#支持两种方式调用，registerCompiler(name, sourceExt, type, handler)，type只能是css/html/js之一
#另一种调用方式：registerCompiler(name, rule, handler)
exports.registerCompiler = (args...)->
	#第一个参数是名称
	name = args[0]

	#仅指定源文件的扩展名和类型
	if args.length > 2 and args[0]
		rule = getRuleWithType args[1], args[2]
		handler = args[3]
	else
		rule = args[1]
		handler = args[2]

	compiler = new Compiler(name, handler)
	compiler.rule = rule
	COMPILERS[name] = compiler
	compiler

#根据名字查找编译器的名称
exports.getCompilerWithName = (name)-> COMPILERS[name]

#根据扩展名来获取编译器的名称
exports.getCompilerWithExt = (ext, isRealTime)->
	for name, compiler of COMPILERS
		return compiler if compiler.isMatch ext, isRealTime