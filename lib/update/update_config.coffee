###
  版本升级时数据迁移与升级
###
_fs = require 'fs-extra'
_path = require 'path'
_utils = require '../utils'

#升级到1.0版本，即升级到支持插件的版本
updateTo10 = ()->
  #检查配置文件的版本
  config = require _utils.localConfigFile()
  return if config.version >= 0.2

#  复制development和normal、product到data目录
  ['development', 'production', 'normal'].forEach (folder)->
    source = _path.join _utils.localSilkyIdentityDir(), folder
    target = _path.join(_utils.localSilkyIdentityDir(), 'data', folder)

    return if not _fs.existsSync source
    #确保目录存在
    _fs.ensureDirSync target
    _fs.renameSync source, target

  #升级配置文件
  config.version = 0.2
  config.compatibleModel = true
  #默认加载honey的插件
  config.plugins = honey: {}
  config.routers = [
    path: /^(.+)\.source(\.js)$/, to: '$1$2', next: false
  ].concat(config.routers)

  delete config.beautify
  delete config.livereload
  delete config.replaceSource
  delete config.watch
  delete config.build.compile

  config.build.ignore = [/^template\/module$/i, /^css\/module$/i, /(^|\/)\.(.+)$/]
  config.build.rename = [
    {
      source: /^template\/(.+)/i, target: '$1', next: false
    }
  ].concat(config.build.rename)

  #默认忽略掉带min的文件名
  config.build.compress.ignore = [/\.(min|pack)\.js$/]

  _utils.saveObjectAsCode config, _utils.localConfigFile()
  console.log '升级silky配置文件成功，请重新启动silky'.green
  process.exit(0)

exports.execute = ()->
  #非silky project不用升级
  return if not _utils.isSilkyProject()
  updateTo10()