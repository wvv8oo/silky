###
    读取所有模板
###

_fs = require 'fs'
_path = require 'path'
_common = require './common'
_handlebars = require 'handlebars'
_data = require './data'
require 'colors'

#模板
_templtes = {}

getTemplateKey = (file)->
    #替换掉template及之间的路径
    file = file.replace _path.join(_common.root(), 'template/'), ''
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

#监控模板的变更
watch = ()->


#获取所有模板
fetch = (parent)->
    parent = parent || _path.join _common.root(), 'template'
    #读取所有文件
    _fs.readdirSync(parent).forEach (filename) ->
        file = _path.join parent, filename
        return fetch(file) if _fs.statSync(file).isDirectory()

        #如果是handlebars，则读取文件
        readTemplate(file) if _path.extname(file) is '.handlebars'


#渲染一个模板
exports.render = (key)->
    content = _templtes[key]
    return "无法找到模板[#{key}]" if not content

    try
        console.log _data.whole
        template = _handlebars.compile content
        template _data.whole
    catch e
        return e.message

#初始化
exports.init = ()->
    fetch()
    watch()