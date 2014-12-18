###
  版本升级时数据迁移与升级
###
_fs = require 'fs-extra'
_path = require 'path'
_common = require '../common'

#升级到1.0版本，即升级到支持插件的版本
updateTo10 = ()->
  identityDir = _path.join _common.options.workbench, _common.options.identity
  configFile = _path.join identityDir, 'config.js'
  #检查配置文件的版本
  config = require configFile
  return if config.version >= 0.2

#  复制development和normal、product到data目录
  ['development', 'production', 'normal'].forEach (folder)->
    source = _path.join identityDir, folder
    target = _path.join(identityDir, 'data', folder)
    #确保目录存在
    _fs.ensureDirSync target

    return if not _fs.existsSync source
    _fs.renameSync source, target

  #升级配置文件
  config.version = 0.2
  config.compatibleModel = true
  config.plugin = {}
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

  #保存并美化代码
  beautify = require('js-beautify').js_beautify
  ott = require '../object2String'
  content = ott config
  content = "module.exports = #{content}"
  content = beautify(content, { indent_size: 2 })

  _common.writeFile configFile, content
  console.log '升级silky配置文件成功，请重新启动silky'.green
  process.exit(0)

exports.execute = ()->
  updateTo10()