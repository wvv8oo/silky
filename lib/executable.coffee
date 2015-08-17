#处理项目中的可执行的文件
_path = require 'path'
_fs = require 'fs-extra'

_utils = require './utils'
_data = require './data'

#响应JSON
responseJSON = (res, data)->
  res.statusCode = 200
  res.setHeader "Content-Type", "application/json; charset=utf-8"
  res.json data


#处理可执行的路由
module.exports = (route, url, req, res, next)->
  file = _path.join _utils.options.workbench, route.url

  if not _fs.existsSync file
    error = "找不到可执行文件：#{file}"
    return req.end error

  silky =
    options: _utils.options
    config: _utils.options
    data: _data.whole
    responseJSON: responseJSON


  #清除缓存
  delete require.cache[require.resolve(file)]
  executeFile = require file
  executeFile req, res, next, silky