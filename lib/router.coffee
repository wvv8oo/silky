_common = require './common'
_path = require 'path'
_fs = require 'fs'
_template = require './template'
_less = require 'less'
_data = require './data'
_css = require './css'
_coffee = require 'coffee-script'
_script = require './script'
_precompiler = require './handlebars_precompiler'
_url = require 'url'
_handlebars = require 'handlebars'

#如果文件存在，则直接响应这个文件
responseFileIfExists = (file, res)->
	#如果html文件存在，则直接输出
	if _fs.existsSync file
		res.sendfile file
		return true

#请求html文件
responseHTML = (filename, req, res, next)->
	#处理根目录的问题，自动加上index.html
	#filename += 'index.html' if /\/$/.test filename

	#如果html文件存在，则直接返回
	htmlFile = _path.join(_common.getTemplateDir(), filename)
	return if responseFileIfExists htmlFile, res

	#不存在这个文件，则读取模板
	hbsFile = htmlFile.replace(/\.(html)|(html)$/i, '.hbs')
	content = _template.render hbsFile
	res.end content

#请求css，如果是less则编译
responseCSS = (filename, req, res, next)->
  cssFile = _path.join _common.options.workbench, filename
  #如果文件已经存在，则直接返回
  return if responseFileIfExists cssFile, res

  #不存在这个css，则渲染less
  lessFile = _common.replaceExt cssFile, '.less'
  #如果不存在这个文件，则交到下一个路由
  if not _fs.existsSync lessFile
    console.log "CSS或Less无法找到->#{filename}".red
    return next()

  _css.render lessFile, (err, css)->
    #编译发生错误
    return response500 req, res, next, JSON.stringify(err) if err
    res.type('text/css')
    res.end css

#响应js
responseJS = (filename, req, res, next)->
	#替换掉source的文件名，兼容honey
	#jsFile = jsFile.replace '.source.js', '.js' if _config.replaceSource
	#如果文件已经存在，则直接返回
	jsFile = _path.join _common.options.workbench, filename
	return if responseFileIfExists jsFile, res

	#没有找到，考虑去掉.source文件
	if _common.config.replaceSource
		jsFile = jsFile.replace '.source.js', '.js'
		return if responseFileIfExists jsFile, res

		#有可能是文件名带有.source，但实际上并没有，所以增加source作为文件名再找一次
		sourceJs = _common.replaceExt jsFile, '.source.js'
		return if responseFileIfExists sourceJs, res

	#如果没有找到，则考虑编译coffee
	coffeeFile = _common.replaceExt jsFile, '.coffee'
	#如果不存在这个文件，则交到下一个路由
	if not _fs.existsSync coffeeFile
		console.log "Coffee或JS无法找到->#{filename}".red
		return next()

	res.send _script.compile coffeeFile

#响应文件夹列表
responseDirectory = (path, req, res, next)->
  dir = _path.join _common.getTemplateDir(), path
  files = []
  _fs.readdirSync(dir).forEach (filename)->
    #不处理module
    return if /module/i.test filename
    item =
      filename: filename
      url: _path.join(path, filename.replace('.hbs', '.html'))
    files.push item

  tempfile = _path.join __dirname, './client/file_viewer.hbs'
  template = _handlebars.compile _common.readFile(tempfile)
  result =
    files: files

  res.end template(result)


#请求其它静态资源，直接输入出


responseStatic = (req, res, next)->
  url = _url.parse(req.url)
  file = _path.join _common.options.workbench, url.pathname
  #查找文件是否存在
  return next() if not _fs.existsSync file
  res.sendfile file

#找不到
response404 = (req, res, next)->
	res.statusCode = 404
	res.end('404 Not Found')

#服务器错误
response500 = (req, res, next, message)->
	res.statusCode = 500
	res.end(message || '500 Error')

#根据路由规则替换路由
replacePath = (origin)->
	url = origin
	for router in _common.config.routers
		continue if not router.path.test(url)
		url = url.replace router.path, router.to
		break if not router.next

	console.log "#{origin} -> #{url}".green if url isnt origin
	url

module.exports = (app)->
  #silky的文件引用
  app.get "/__/:file", (req, res, next)->
    file = _path.join(__dirname, 'client', req.params.file)
    res.sendfile file

  #匹配所有
  app.get "*", (req, res, next)->
    url = _url.parse(req.url)
    path = replacePath url.pathname

    #匹配html
    if /(\.(html|html))$/.test(path)
      return responseHTML path, req, res, next
    else if /\.css$/.test(path)
      return responseCSS path, req, res, next
    else if /\.js$/.test(path)
      return responseJS path, req, res, next
    else if /(^\/$)|(\/[^.]+$)/.test(path)
      #显示文件夹
      return responseDirectory path, req, res, next
    else
      responseStatic(req, res, next)
