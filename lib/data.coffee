###
    读取.silky下的json文件，用这个数据来渲染handlebars
###
_fs = require 'fs'
_path = require 'path'
_common = require './common'

_isWatch = false        #是否在监控中
_data = {
    json: {},
    less: {}
}

#根据文件名获取key
getDataKey = (file)->
    _path.basename file, _path.extname(file)

#读取json数据到_data中
readData = (file)->
    #只处理json和less的文件
    extname = _path.extname(file).replace('.', '')
    return if extname not in ['json', 'less', 'js']

    #读取
    content = _fs.readFileSync(file, 'utf-8')
    key = getDataKey file

    #将数据存入
    _data[extname][key] = (if extname is 'json' then JSON.parse(content) else content)


#入口
exports.init = ()->
    #循环读取所有数据到缓存中
    _fs.readdirSync(SILKY.data).forEach (filename)->
        readData _path.join(SILKY.data, filename)

    #监控数据目录中的json和less以及js是否发生的变化
    _common.watch SILKY.data, /\.(json|less|js)$/i, (event, file)->
        extname = _path.extname(file).replace '.', ''
        #删除数据
        if event is 'delete'
            key = getDataKey file
            delete _data[extname][key]
        else
            #更新数据
            readData file

        _common.onPageChanged()

exports.whole = _data


