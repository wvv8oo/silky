_common = require './common'
_path = require 'path'
_fs = require 'fs'
_template = require './template'
_less = require 'less'
_data = require './data'

#如果文件存在，则直接响应这个文件
responseFileIfExists = (filename, extname, res)->
    file = _path.join _common.root(), filename + extname
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
    file = _path.join _common.root(), filename + '.less'
    #如果不存在这个文件，则交到下一个路由
    next() if not _fs.existsSync file

    #读取并转换less
    content = _fs.readFileSync file, 'utf-8'
    #选项
    options =
        paths: [_path.join(_common.root(), 'css')]

    parser = new _less.Parser options
    #将全局配置中的less加入到content后面
    content += value for key, value of _data.whole.less

    console.log _data.whole.less
    #转换
    parser.parse(content,(err, tree)->
        return res.json err if err
        res.end(tree.toCSS())
    )

#响应js
responseJS = (req, res, next)->
    filename = req.params.file
    extname = '.js'
    #如果文件已经存在，则直接返回
    return if responseFileIfExists filename, extname, res

    #如果没有找到，则考虑编译coffee
    #如果不存在这个文件，则交到下一个路由
    next() if not _fs.existsSync file

#请求其它静态资源，直接输入出
responseStatic = (req, res, next)->
    #res.sendfile

response404 = (req, res, next)->
    res.statusCode = 404
    res.end('404 Not Found')

module.exports = (app)->
    path = '/:file([0-9a-zA-A/]+)'
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
    app.all '*', response404