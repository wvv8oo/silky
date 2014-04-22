###
    读取.silky下的json文件，用这个数据来渲染handlebars
###
_fs = require 'fs'
_path = require 'path'
_common = require './common'

_isWatch = false        #是否在监控中
_data = {}

#读取json数据到_data中
readData = (filename)->
    #只处理json的文件
    return if _fs.extname(filename) isnt '.json'

    #读取
    file = _path.join(getDataPath(), filename)
    content = _fs.readFileSync(file, 'utf-8')
    _data[filename] = JSON.parse content

#获取数据所在的目录
getDataPath = ()->
    #设置data的主目录，development以后需要从命令行参数中获取
    _path.join _common.root(), '.silky', 'development'

#读取所有的文件到data中，并返回
fetch = ()->
    #循环读取所有数据到缓存中
    _fs.readdirSync(getDataPath()).forEach readData

#监控文件
watch = ()->
    return if _isWatch
    _isWatch = true

    #监控数据目录发生的变化，如果有变化，则实时

#入口
exports.init = ()->
    fetch()
    watch()

exports.whole = _data


