###
    读取.silky下的json文件，用这个数据来渲染handlebars
###
_fs = require 'fs'
_path = require 'path'

_isWatch = false        #是否在监控中
_data = {}
_rootDir    #数据的目录

#读取json数据到_data中
readData = (filename)->
    #只处理json的文件
    return if _fs.extname(filename) not '.json'

    #读取
    file = _path.join(_rootDir, filename)
    content = _fs.readFileSync(file, 'utf-8')
    _data[filename] = JSON.parse content


#读取所有的文件到data中，并返回
fetch = (root)->
    #设置data的主目录，development以后需要从命令行参数中获取
    _rootDir = _path.join root, '.silky', 'development'
    #循环读取所有数据
    _fs.readdirSync(_rootDir).forEach readData

#监控文件
watch = ()->
    return if _isWatch
    _isWatch = true

    #监控数据目录发生的变化，如果有变化，则实时

#入口
module.exports = (root)->
    fetch(root)
    watch()
    _data



