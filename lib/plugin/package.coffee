###
  安装卸载插件
###
_path = require 'path'
_common = require '../common'
_fs = require 'fs-extra'
_ = require 'lodash'
_async = require 'async'

#更新仓库，如果仓库不存在，则clone仓库
updateGitRepos = (remoteRepos, localRepos, cb)->
  console.log "正在同步git仓库..."
  #目录已经存在，则clone
  if _fs.existsSync localRepos
    command = "cd \"#{localRepos}\" && git pull"
  else
    command = "git clone \"#{remoteRepos}\" \"#{localRepos}\""

  _common.execCommand command, (code)->
    console.log "同步git仓库完成"
    cb code

#从本地目录安装插件
installPluginFromLocalDir = (pluginName, pluginRootDir, sourcePluginDir, cb)->
  console.log "准备安装#{pluginName}"
  return console.log "#插件{pluginName}不存在，安装失败".red if not _fs.existsSync sourcePluginDir
  #如果没有给插件名称，则取源的文件名（这里其实应该读package.json，再取名称好一点）
  pluginName = pluginName || _path.basename(sourcePluginDir)
  targetPluginDir = _path.join pluginRootDir, pluginName
  #删除目录，如果已经存在
  _fs.removeSync targetPluginDir if _fs.existsSync targetPluginDir
  _fs.copySync sourcePluginDir, targetPluginDir

  #运行npm install
  command = "cd \"#{targetPluginDir}\" && npm install"
  _common.execCommand command, (code, message, error)->
    if code is 0
      console.log "#{pluginName}安装成功".green
    else
      console.log "#{pluginName}安装失败".red

    cb null

#在指定仓库中安装插件列表
installPluginsFromLocalDir = (names, pluginRootDir, localRepos, cb)->
  index = 0
  _async.whilst(
    -> index < names.length
    ((done)->
      pluginName = names[index++]
      #在仓库中的插件目录
      sourcePluginDir = _path.join localRepos, pluginName
      installPluginFromLocalDir pluginName, pluginRootDir, sourcePluginDir, (err)-> done null
    ), cb
  )

#从指定源中安装
installFromSpecificSource = (pluginName, pluginRootDir, source, cb)->
  #没有以git结尾，直接从本地安装
  if not /\.git$/i.test source
    #直接从本地安装
    return installPluginFromLocalDir pluginName, pluginRootDir, source, cb

  #从git仓库安装
  cacheDir = _path.join _common.globalCacheDirectory(), 'cache_repos', pluginName
  _fs.removeSync cacheDir

  updateGitRepos source, cacheDir, (code)->
    if code isnt 0
      console.log '安装失败'.red
      console.log err
      return cb null

    installPluginFromLocalDir pluginName, pluginRootDir, cacheDir, cb

#从标准仓库中安装
installFromStandardRepos = (names, pluginRootDir, repository, cb)->
  repository = repository || _common.xPathMapValue('custom.plugin-repository', _common.globalConfig)
  repository = repository || 'https://github.com/wvv8oo/silky-plugins.git'
  localRepos = _path.join _common.globalCacheDirectory(), 'plugins'

  #更新仓库
  updateGitRepos repository, localRepos, (err)->
    if err
      console.log '安装失败'.red
      return console.log err

    installPluginsFromLocalDir names, pluginRootDir, localRepos, cb

#安装插件
exports.install = (names, oringal, repository, cb)->
  pluginRootDir = _common.globalPluginDirectory()
  console.log "installing..."

  #从指定的源安装，只安装一个
  if oringal
    installFromSpecificSource names[0], pluginRootDir, oringal, cb
  else
    #从标准库中安装，可以安装多个
    installFromStandardRepos names, pluginRootDir, repository, cb

#删除插件
exports.uninstall = (names, cb)->
  pluginRootDir = _common.globalPluginDirectory()

  _.map names, (pluginName)->
    pluginDir = _path.join pluginRootDir, pluginName
    return console.log "#{pluginName}不存在" if not _fs.existsSync pluginDir
    _fs.removeSync pluginDir
    console.log "插件#{pluginName}已经被卸载".green

  cb null

#列出所有的插件
exports.list = ()->
  pluginRootDir = _common.globalPluginDirectory()
  return console.log "没有安装任何插件".green if not _fs.existsSync pluginRootDir

  total = 0
  console.log '正在检测已经安装的插件'
  console.log "插件安装目录：#{pluginRootDir}"
#  console.log 'Plugins: '
  plugins = _fs.readdirSync pluginRootDir
  _.map plugins, (pluginName)->
    pluginDir = _path.join pluginRootDir, pluginName
    pluginPackage = _path.join pluginDir, 'package.json'
    return if not _fs.existsSync pluginPackage

    total++
    pkg = _fs.readJSONFileSync pluginPackage, 'utf-8'
    console.log "#{pluginName}->#{pkg.version}".green

  console.log "#{total}个插件已经被安装"
