###
    读取.silky下的json文件，用这个数据来渲染handlebars
###
_fs = require 'fs'
_path = require 'path'
_common = require './common'
_ = require 'underscore'

_isWatch = false        #是否在监控中
_data = {
    json: {},
    less: {}
}

#根据文件名获取key
getDataKey = (file)->
    _path.basename file, _path.extname(file)

#全并文件
combineFile = (workbench, filename)->
  #只处理json和less的文件
  extname = _path.extname(filename).replace('.', '')
  return false if extname not in ['json', 'less', 'js']

  #取正常数据
  normaFile = _path.join workbench, 'normal', filename
  normalData = _common.readFile normaFile

  #取特殊环境将要覆盖的数据
  overrideFile = _path.join workbench, _common.options.env, filename
  if _fs.existsSync overrideFile
    overrideData = _common.readFile overrideFile

  #将数据存入
  if extname is 'json'
    content = JSON.parse(normalData)
    _.extend content, JSON.parse(overrideData) if overrideData
  else
    content = normalData + (overrideData || '')

  key = getDataKey filename
  _data[extname][key] = content


#入口
exports.init = ()->
    ops = _common.options
    #读取normal的数据
    workspace = _path.join ops.workbench, ops.identity
    #循环读取所有数据到缓存中
    _fs.readdirSync(_path.join workspace, 'normal').forEach (filename)->
      combineFile workspace, filename

#    暂时不watch，因为data文件一般改得少
#    #监控数据目录中的json和less以及js是否发生的变化
#    _common.watch workspace, /\.(json|less|js)$/i, (event, file)->
#        extname = _path.extname(file).replace '.', ''
#        #删除数据
#        if event is 'delete'
#            key = getDataKey file
#            delete _data[extname][key]
#        else
#            #更新数据
#            readData file
#
#        _common.onPageChanged()

exports.whole = _data


