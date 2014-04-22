###
    读取所有模板
###

_fs = require 'fs'
_path = require 'path'
_common = require './common'
_handlebars = require 'handlebars'
_data = require './data'
#模板
_templtes = {}

getTemplateKey = (file)->
    file.replace _common.root(), ''

#读取模板
readTemplate = (file)->
    content = _fs.readFileSync file, 'utf-8'
    key = getTemplateKey file
    #不能直接编译，因为partials可能没有准备好
    if key.split(_path.sep)[0] is 'module'
        _handlebars.registerPartial key, content

    #将所有的模板都缓存起来，partial也被缓存起来，有时候可能需要渲染一模块
    _templtes[key] = content


#监控模板的变更
watch = ()->


#获取所有模板
fetch = (parent)->
    parent = parent || _common.root()
    #读取所有文件
    _fs.readdirSync(parent).forEach (filename) ->
        file = _path.join parent, filename
        return fetch(file) fs.statSync(file).isDirectory()

        #如果是handlebars，则读取文件
        readTemplate if _path.extname(file) is '.handlebars'


#渲染一个模板
exports.render = (key)->
    content = _templtes[key]
    return "无法找到模板[#{key}]" if not content

    try
        template = _handlebars.compile content
        template _data.whole
    catch e
        return e.message

#初始化
exports.init = ()->
    fetch()
    watch()