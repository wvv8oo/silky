_uuid = require 'uuid'

_updateConfig = require './update_config'
_updateSilky = require './update_silky'
_utils = require '../utils'

#检查是否设置了UUID，如果没有设置
checkUUID = ()->
  return if _utils.globalConfig.uuid
  _utils.globalConfig.uuid = _uuid.v4()
  _utils.saveGlobalConfig()

#检查配置文件的升级
exports.checkConfig = ()->
  _updateConfig.execute()

#检查主程序是否需要升级
exports.checkSilky = (currentVersion)->
  #检查uuid
  checkUUID()

  #每天只检查一次即可
  lastCheckUpdate = _utils.globalConfig.lastCheckUpdate
  oneDay = 1000 * 60 * 60 * 24
  return if lastCheckUpdate and new Date().valueOf() - lastCheckUpdate < oneDay

  try
    _updateSilky.execute(currentVersion)
    _utils.globalConfig.lastCheckUpdate = new Date().valueOf()
    _utils.saveGlobalConfig()
  catch e
    console.log '升级检测发生错误'
    console.log e
