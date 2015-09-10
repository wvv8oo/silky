#    Author: 易晓峰
#    E-mail: wvv8oo@gmail.com
#    Date: 9/7/15 5:57 PM
#    Description: 负责响应路由请求的数据

_fs = require 'fs-extra'
_mime = require 'mime'
_async = require 'async'

_hookHost = require './plugin/host'
_utils = require './utils'
_hooks = require './plugin/hooks'
_compilerMrg = require './compiler/compiler_manager'
_compiler = require './compiler'

#统一处理响应
responseNormal = exports.responseNormal = (route, pluginData, req, res, next)->
	options = pluginData: pluginData
	source = route.realpath
	mime = route.mime

	if route.compiler
		#如果用户已经强制指定了编译，可以用to重写至真实的文件名
		#在query中指定，直接查找与url中一致的文件名
		#在routers配置中指定，需要用to重写至真实的文件名
		compiler = _compilerMrg.getCompilerWithName(route.compiler)
	else
		#找到扩展名，然后匹配对应的编译器
		ext = _utils.getExtension(route.realpath)
		compiler = _compiler.getCompilerWithExt ext, true
		#如果是根据扩展名自动映射到编译器，则需要更改扩展名以查找源文件
		if compiler
			compilerRule = compiler.rule.route
			source = _utils.replaceExt(source, compilerRule.replaceExt)
			mime = compilerRule.mime

	#没有找到编译器，则直接响应静态文件
	return responseStatic route.realpath, req, res, next if not compiler

	#由编译器处理
	_compiler.execute compiler, source, options, (err, content)->
		#编译发生错误
		return response500 req, res, next, JSON.stringify(err) if err
		#没有编译成功，可能是文件格式没有匹配或者其它原因
		return responseStatic(route.realpath, req, res, next) if content is false
		#响应数据到客户端
		responseContent content, mime, req, res, next

#找不到
response404 = exports.response404 = (req, res, next)->
	res.statusCode = 404
	res.end('404 Not Found')

#服务器错误
response500 = exports.response500 = (req, res, next, message)->
	res.statusCode = 500
	res.end(message || '500 Error')

#如果文件存在，则直接响应这个文件
responseFileIfExists = exports.responseFileIfExists = (file, res)->
#如果html文件存在，则直接输出
	if _fs.existsSync file
		res.sendfile file
		return true

#响应纯内容数据
responseContent = exports.responseContent = (content, mime, req, res, next)->
	#如果是html，则考虑要在head前加入livereload
	if _utils.config.livereload and _mime.extension(mime) is 'html'
		script = "    <script src='#{_utils.options.livereload}'></script>\n$1"
		content = content.replace /(<\/\s*head>)/i, script

	data =
		content: content
		mime: mime
		response: res
		request: req
		next: next
		stop: false

	_hookHost.triggerHook _hooks.route.willResponse, data, (err)->
		return if  data.stop
		res.type data.mime if data.mime
		res.end data.content

#请求其它静态资源，直接输入出
responseStatic = exports.responseStatic = (realpath, req, res, next)->
#如果文件不存在，则
	if not _fs.existsSync realpath
		data =
			realpath: realpath
			req: req
			res: res
			next: next
			stop: false

		_hookHost.triggerHook _hooks.route.notFound, data, (err)->
			return if data.stop
			next()
	else
		res.sendfile realpath

#响应文件夹列表
responseDirectory = exports.responseDirectory = (dir, req, res, next)->
	workbench = _utils.options.workbench
	#兼容旧版的template目录
	workbench = _path.join workbench, 'template' if _utils.config.compatibleModel

#	relativePath = _path.relative _utils.options.workbench, dir
#	realPath = _path.join workbench, relativePath
	realPath = _path.join workbench, dir
	return next() if not _fs.existsSync realPath
	return next() if not _fs.statSync(realPath).isDirectory()

	files = []
	content = null

	#读取所有的文件
	_fs.readdirSync(realPath).forEach (filename)->
		file = _path.join(realPath, filename)
		item =
			filename: filename
			url: filename

		#只有silky项目，才会将hbs的扩展名改为html
		#TODO 这里应该要根据编译器自动替换扩展名
		item.url = item.url.replace('.hbs', '.html') if _utils.isSilkyProject()

		stat = _fs.statSync file
		#如果是文件夹，在后台加上/
		item.url += '/?directory=true' if stat.isDirectory()
		files.push item

	queue = []
	#触发hook
	queue.push(
		(done)->
			data =
				files: files
				response: res
				request: req
				next: next
				directory: dir
				stop: false

			_hookHost.triggerHook _hooks.route.willPrepareDirectory, data, (err)->
				files = data.files
				done data.stop
	)

	#根据模板响应数据
	queue.push(
		(done)->
			tempfile = _path.join __dirname, './client/file_viewer.hbs'
			templateFn = _handlebars.compile _utils.readFile(tempfile)
			data = files: files
			content = templateFn data
			done null
	)

	#触发hook
	queue.push(
		(done)->
			data =
				content: content
				response: res
				request: req
				next: next
				directory: dir

			_hookHost.triggerHook _hooks.route.didPrepareDirectory, data, (err)->
				content = data.content
				done null
	)

	_async.waterfall queue, (err)->
		return err if err
		res.end content