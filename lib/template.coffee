###
    读取所有模板
###

_fs = require 'fs'
_path = require 'path'
_common = require './common'
_handlebars = require 'handlebars'
_data = require './data'
_cheerio = require 'cheerio'
_ = require 'underscore'
_htmlpretty = require('js-beautify').html
require 'colors'

#模板
_templtes = {}
#系统出错的模板
_errorTemplate = null

#根据文件名提取key
getTemplateKey = exports.getTemplateKey = (file)->
	#取相对于template的路径
	key = _path.relative _path.join(_common.options.workbench, 'template/'), file

	#替换掉扩展名
	key = key.replace _path.extname(key), ''
	key = _common.replaceSlash key
	key

#读取模板
readTemplate = (file)->
	content = _fs.readFileSync file, 'utf-8'
	key = getTemplateKey file
	_common.fileLog key

	#不能直接编译，因为partials可能没有准备好
	#路径是以module开头的
	if /^module/.test key
		try
		#console.log "partial: #{key}"
			_handlebars.registerPartial key, content
		catch e
			console.log "警告：#{key}读取失败，路径：#{file}".error

	#将所有的模板都缓存起来，partial也被缓存起来，有时候可能需要渲染一模块
	_templtes[key] = content

#获取模板的目录
getTemplateDir = ()->
	_path.join _common.options.workbench, 'template'


#获取所有模板
fetch = (parent)->
	parent = parent || getTemplateDir()
	#读取所有文件
	_fs.readdirSync(parent).forEach (filename) ->
		file = _path.join parent, filename
		return fetch(file) if _fs.statSync(file).isDirectory()

		#如果是handlebars，则读取文件
		readTemplate(file) if _path.extname(file) is '.hbs'

#合并honey中的依赖
combineHoney = ($)->
	#全并所有<script honey=""></script>的代码
	deps = []
	scripts = []
	$('script[honey]').each ()->
		$this = $(this)
		#合并依赖
		deps = _.union(deps,$this.attr('honey').split(','))
		#临时保存脚本
		scripts.push $this.html()
		#删除这个script标签
		$this.remove()

	#如果存在script honey的脚本
	if scripts.length > 0
		#处理合并项
		html = "\thoney.go(\"#{_.compact(deps).join(',')}\", function() {\n"
		#将所有的代码都封装到闭包中运行
		for script in scripts
			#不处理空的script
			html += "\t(function(){\n#{script}\n\t}).call(this);\n\n"

		html += '\n\t});'

	#html = _jspretty html, indent_size: 4
	html = "<script>\n#{html}\n</script>"

	#将新的html合并到body里
	$('body').append html

#注入及合并js
injectScript = (content)->
	#提取
	$ = _cheerio.load content
	#合并honey的依赖
	combineHoney $

	livereload = _common.config.livereload
	if _common.options.env in livereload.env
		mainJS = '/__/main.js'
		socketJS = '/socket.io/socket.io.js'
		append = '<!--自动附加内容-->\n'
		if livereload.amd
			append += "<script>
										require(['#{mainJS}'])
									</script>"
		else
			append += "<script src='#{socketJS}'>
										</script>\n
										<script src='#{mainJS}'></script>\n"
		append += "<!--生成时间：#{new Date()}-->\n"
		$('head').append(append)

	$.html()

#渲染一个模板
exports.render = (key)->
	key = _common.replaceSlash key
	content = _templtes[key]
	return _common.combError("无法找到模板[#{key}]") if not content
	try
		template = _handlebars.compile content
		#使用json的数据进行渲染模板
		data = _data.whole.json
		#附加运行时的环境
		data.silky = _.extend({}, _common.options)
		data.silky.isDevelopment = false

		content = template data
		html = injectScript content

		if _common.config.beautify then _htmlpretty(html) else html
	catch e
	#调用目的是为了产品环境throw
		_common.combError(e)
		_errorTemplate(e)

compilePartial = (name, context)->
	name = _common.replaceSlash name
	partial = _handlebars.partials[name]

	return "无法找到partial：#{name}" if not partial

	#查找对应的节点数据
	template = _handlebars.compile partial
	template(context)

importCommand = (name, context, options)->
	#如果则第二个参数像options，则表示没有提供参数
	if context and context.name in ['import', 'partial']
		options = context
		context = _.extend {}, options.data.root

	context = context || options.data.root
	#合并silky到context
	context.silky = _.extend {}, _common.options if not context.silky
	html = compilePartial(name, context || {})
	new _handlebars.SafeString(html)

#注册handlebars
registerHandlebars = ()->
	#循环
	_handlebars.registerHelper "loop", (name, count, options)->
		count = count || []
		count = [1..count] if typeof count is 'number'
		results = []
		for value in count
			results.push compilePartial(name, value)
		new _handlebars.SafeString(results.join(''))

	#partial
	_handlebars.registerHelper "partial", importCommand
	_handlebars.registerHelper "import", importCommand

	_handlebars.registerHelper "ifEqual", (left, right, options)->
		return if left is right then options.fn(this) else ""

#初始化
exports.init = ()->
	registerHandlebars()
	fetch()

	#监控模板被改变的事件
	_common.addListener 'file:change:html', (event, file)->
		#删除模板的数据
		if event is 'delete'
			key = getTemplateKey file
			delete _data[key]
		else
			#更新模板
			readTemplate file

	#读取系统出错模板，并编译
	file = _path.join __dirname, 'client/error.hbs'
	content =  _fs.readFileSync file, 'utf-8'
	_errorTemplate = _handlebars.compile content