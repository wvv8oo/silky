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
require 'colors'

#模板
_templtes = {}
#系统出错的模板
_errorTemplate = null

#根据文件名提取key
getTemplateKey = exports.getTemplateKey = (file)->
    #替换掉template及之间的路径
    file = file.replace _path.join(SILKY.workbench, 'template/'), ''
    #替换掉扩展名
    file.replace _path.extname(file), ''

#读取模板
readTemplate = (file)->
    content = _fs.readFileSync file, 'utf-8'
    key = getTemplateKey file
    #不能直接编译，因为partials可能没有准备好
    if key.split(_path.sep)[0] is 'module'
        try
            _handlebars.registerPartial key, content
        catch e
            console.log "警告：#{key}读取失败，路径：#{file}".error

    #将所有的模板都缓存起来，partial也被缓存起来，有时候可能需要渲染一模块
    _templtes[key] = content

#获取模板的目录
getTemplateDir = ()->
    _path.join SILKY.workbench, 'template'


#获取所有模板
fetch = (parent)->
    parent = parent || getTemplateDir()
    #读取所有文件
    _fs.readdirSync(parent).forEach (filename) ->
        file = _path.join parent, filename
        return fetch(file) if _fs.statSync(file).isDirectory()

        #如果是handlebars，则读取文件
        readTemplate(file) if _path.extname(file) is '.hbs'


#渲染一个模板
exports.render = (key)->
    content = _templtes[key]
    return _common.combError("无法找到模板[#{key}]") if not content

    try
        template = _handlebars.compile content
        #使用json的数据进行渲染模板
        data = _data.whole.json
        #附加运行时的环境
        data.silky = SILKY

        content = template data
        #产品环境，直接返回
        return content if _common.isProduction()

        #在header中，插入websocket
        $ = _cheerio.load content

        #在测试环境下，附加自动刷新的监控代码
        append = "\t<!--自动附加内容-->\n\t<script src='/socket.io/socket.io.js'></script>\n\t<script src='/__/main.js'></script>
        "
        $('head').append(append).append("\n\t<!--生成时间：#{new Date()}-->\n")
        $.html()
    catch e
        #调用目的是为了产品环境throw
        _common.combError(e)
        _errorTemplate(e)

compilePartial = (name, context)->
    partial = _handlebars.partials[name]
    return "无法找到partial：#{name}" if not partial
    #查找对应的节点数据
    template = _handlebars.compile partial
    template(context)

#注册handlebars
registerHandlebars = ()->
    #循环
    _handlebars.registerHelper "loop", (name, count, options)->
        count = [1..count] if typeof count is 'number'
        results = []
        for value in count
            results.push compilePartial(name, value)
        new _handlebars.SafeString(results.join(''))

    #partial
    _handlebars.registerHelper "partial", (name, context, options)->
        #如果则第二个参数像options，则表示没有提供参数
        if context and context.name is 'partial'
            options = context
            context = options.data.root

        html = compilePartial(name, context || {})
        new _handlebars.SafeString(html)

    _handlebars.registerHelper "if", (left, right, options)->
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