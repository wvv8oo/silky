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

#如果文件存在，则直接响应这个文件
responseFileIfExists = (filename, extname, res)->
    file = _path.join SILKY.workbench, filename + extname
    #如果html文件存在，则直接输出
    if _fs.existsSync file
        res.sendfile file
        return true

#请求html文件
responseHTML = (req, res, next)->
    filename = req.params.file
    #如果文件已经存在，则直接返回，不再渲染为模板
    return if responseFileIfExists filename, '.html', res

    #不存在这个文件，则读取模板
    content = _template.render filename
    res.end content

#请求css，如果是less则编译
responseCSS = (req, res, next)->
    filename = req.params.file
    extname = '.css'
    #如果文件已经存在，则直接返回
    return if responseFileIfExists filename, extname, res

    #不存在这个css，则渲染less
    file = _path.join SILKY.workbench, filename + '.less'
    #如果不存在这个文件，则交到下一个路由
    next() if not _fs.existsSync file

    _css.render file, (err, css)->
        #编译发生错误
        return response500 req, res, next, JSON.stringify(err) if err
        res.end css

#响应js
responseJS = (req, res, next)->
    filename = req.params.file
    extname = '.js'
    #如果文件已经存在，则直接返回
    return if responseFileIfExists filename, extname, res

    #如果没有找到，则考虑编译coffee
    file = _path.join SILKY.workbench, filename + '.coffee'
    res.send _script.compile file


#请求其它静态资源，直接输入出
responseStatic = (req, res, next)->
    file = _path.join SILKY.workbench, req.url
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
    path = '/:file([0-9a-zA-A/]+)'

    #临时模板路由
    app.get "/js/template.js", (req, res, next)->
        dir = _path.join(__dirname, '../samples/js/template')
        #读取模板
        tpl = _path.join __dirname, './client/precompile.hbs'
        content = _precompiler.precompile dir, _fs.readFileSync(tpl, 'utf-8')
        res.end content

    #所有html页面
    app.get "#{path}.html", responseHTML

    #所有的css
    app.get "#{path}.css", responseCSS
    #请求目录

    #所有的js
    app.get "#{path}.js", responseJS

    #发送客户端要的文件
    app.get "/__/:file", (req, res, next)->
        file = _path.join(__dirname, 'client', req.params.file)
        res.sendfile file


    #404
    app.all '*', responseStatic