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
_config = require SILKY.config

#如果文件存在，则直接响应这个文件
responseFileIfExists = (file, res)->
    #如果html文件存在，则直接输出
    if _fs.existsSync file
        res.sendfile file
        return true

#请求html文件
responseHTML = (url, req, res, next)->
    filename = url.pathname
    #处理根目录的问题，自动加上index.html
    filename += 'index.html' if /\/$/.test filename

    #如果html文件存在，则直接返回
    htmlFile = _path.join(SILKY.workbench, 'template', filename)
    return if responseFileIfExists htmlFile, res

    #不存在这个文件，则读取模板
    #替换扩展名
    renderKey = _common.replaceExt(filename, '')
    #替换掉第一个/
    renderKey = renderKey.replace /^\//, ''
    content = _template.render renderKey
    res.end content

#请求css，如果是less则编译
responseCSS = (url, req, res, next)->
    cssFile = _path.join SILKY.workbench, url.pathname
    #如果文件已经存在，则直接返回
    return if responseFileIfExists cssFile, res

    #不存在这个css，则渲染less
    lessFile = _common.replaceExt cssFile, '.less'
    #如果不存在这个文件，则交到下一个路由
    if not _fs.existsSync lessFile
        console.log "CSS或Less无法找到->#{url.pathname}".red
        return next()

    _css.render lessFile, (err, css)->
        #编译发生错误
        return response500 req, res, next, JSON.stringify(err) if err
        res.end css

#响应js
responseJS = (url, req, res, next)->
    jsFile = url.pathname
    #替换掉source的文件名，兼容honey
    #jsFile = jsFile.replace '.source.js', '.js' if _config.replaceSource
    #如果文件已经存在，则直接返回
    jsFile = _path.join SILKY.workbench, jsFile
    return if responseFileIfExists jsFile, res

    #没有找到，考虑去掉.source文件
    if _config.replaceSource
      jsFile = jsFile.replace '.source.js', '.js'
      return if responseFileIfExists jsFile, res

    #如果没有找到，则考虑编译coffee
    coffeeFile = _common.replaceExt jsFile, '.coffee'
    #如果不存在这个文件，则交到下一个路由
    if not _fs.existsSync coffeeFile
        console.log "Coffee或JS无法找到->#{url.pathname}".red
        return next()

    res.send _script.compile coffeeFile


#请求其它静态资源，直接输入出
responseStatic = (req, res, next)->
    file = _path.join SILKY.workbench, req.url
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

module.exports = (app)->
    #silky的文件引用
    app.get "/__/:file", (req, res, next)->
        file = _path.join(__dirname, 'client', req.params.file)
        res.sendfile file

    #匹配所有
    app.get "*", (req, res, next)->
        url = _url.parse(req.url)
        #匹配html
        if /(\.(html|html)|\/)$/.test(url.pathname)
            return responseHTML url, req, res, next
        else if /\.css$/.test(url.pathname)
            return responseCSS url, req, res, next
        else if /\.js$/.test(url.pathname)
            return responseJS url, req, res, next
        else
            responseStatic(req, res, next)


    ###
    #临时模板路由
    app.get "/js/template.js", (req, res, next)->
        dir = _path.join(__dirname, '../samples/js/template')
        #读取模板
        tpl = _path.join __dirname, './client/precompile.hbs'
        content = _precompiler.precompile dir, _fs.readFileSync(tpl, 'utf-8')
        res.end content
    ###

    ###
    #所有html页面
    app.get "#{path}.html", responseHTML

    #所有的css
    app.get "#{path}.css", responseCSS
    #请求目录

    #所有的js
    app.get "#{path}(.source)?.js", responseJS

    #发送客户端要的文件
    app.get "/__/:file", (req, res, next)->
        file = _path.join(__dirname, 'client', req.params.file)
        res.sendfile file
    ###

    #404
    #app.all '*', responseStatic