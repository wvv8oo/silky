_updateConfig = require './update_config'
_updateSilky = require './update_silky'

#检查配置文件的升级
exports.checkConfig = ()->
  _updateConfig.execute()

#检查主程序是否需要升级
exports.checkSilky = (currentVersion)->
  return;
  try
    _updateSilky.execute(currentVersion)
  catch e
    console.log '升级检测发生错误'
    console.log e
