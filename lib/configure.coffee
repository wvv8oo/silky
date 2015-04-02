#    Author: 易晓峰
#    E-mail: wvv8oo@gmail.com
#    Date: 3/30/15 4:51 PM
#    Description: 处理配置文件
_common = require '../lib/common'
_fs = require 'fs-extra'
_jsonl = require 'json-literal'
_jp = require 'JSONPath'
_ = require 'lodash'

#读取配置文件
readConfig = (isGlobal)->
  configFile = if isGlobal then _common.globalConfigFile() else _common.localConfigFile()
  console.log configFile
  if not _fs.existsSync configFile
    message = "没有找到配置文件"
    message += "，请检查当前目录是否为合法的的Silky项目" if not isGlobal
    console.log message.red
    return false

  configFile

#设置配置
exports.set = (xPath, value, isGlobal)->
  return console.log "要配置的键不能为空".red if not xPath
  return console.log "要配置的值不能为空".red if not value

  return if not file = readConfig isGlobal
  config = require file
  _common.xPathSetValue xPath, config, value
  _common.saveObjectAsCode config, file

#读取
exports.get = (xPath, isGlobal)->
  return if not file = readConfig isGlobal
  config = require file
  value = _common.xPathMapValue xPath, config
  console.log "#{xPath.green} -> #{value}"

#设置honey
exports.setAsHoney = ()->
  return if not file = readConfig true
  config = require file

  for key, value of _common.honeyConfig
    _common.xPathSetValue "custom.#{key}", config, value

  _common.saveObjectAsCode config, file
  console.log "Silky自定义配置成功"
