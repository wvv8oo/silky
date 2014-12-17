###
  安装卸载插件
###
_path = require 'path'
_common = require '../common'
_fs = require 'fs-extra'
_ = require 'lodash'

#获取插件的目录
getPluginDirectory = (isGlobal)->
  if isGlobal then _common.globalPluginDirectory() else _common.workbenchPluginDirectory()

#更新仓库，如果仓库不存在，则clone仓库
updateGitRepos = (remoteRepos, localRepos, cb)->
  #目录已经存在，则clone
  if _fs.existsSync localRepos
    command = "cd #{localRepos} && git pull"
  else
    command = "git clone #{remoteRepos} #{localRepos}"

  require('child_process').exec command, cb

#从本地目录安装插件
installPluginFromLocalDir = (pluginName, pluginRootDir, sourcePluginDir)->
  return console.log "插件#{pluginName}不存在".red if not _fs.existsSync sourcePluginDir
  targetPluginDir = _path.join pluginRootDir, pluginName
  #删除目录，如果已经存在
  _fs.removeSync targetPluginDir if _fs.existsSync targetPluginDir
  _fs.copySync sourcePluginDir, targetPluginDir
  console.log "#{pluginName}安装成功".green

#在指定仓库中安装插件列表
installPluginsFromLocalDir = (names, pluginRootDir, localRepos)->
  _.map names, (pluginName)->
    #在仓库中的插件目录
    sourcePluginDir = _path.join localRepos, pluginName
    installPluginFromLocalDir pluginName, pluginRootDir, sourcePluginDir

#从标准仓库中安装
installFromStandardRepos = (names, pluginRootDir)->
  remoteRepos = 'https://github.com/wvv8oo/silky-plugins.git'
  localRepos = _path.join _common.globalSilkyIdentityDir(), 'plugin_repos'

  #更新仓库
  updateGitRepos remoteRepos, localRepos, (err)->
    if err
      console.log '安装失败'.red
      return console.log err

    installPluginsFromLocalDir names, pluginRootDir, localRepos

#安装插件
exports.install = (names, isGlobal)->
  pluginRootDir = getPluginDirectory(isGlobal)

  return console.log "当前目录不是有效的Silky目录".red if not isGlobal and not _common.isSilkyProject()
  console.log "installing..."
  #暂时只从标准仓库安装，以后可以从
  installFromStandardRepos names, pluginRootDir

#删除插件
exports.uninstall = (names, isGlobal)->
  pluginRootDir = getPluginDirectory(isGlobal)
  _.map names, (pluginName)->
    pluginDir = _path.join pluginRootDir, pluginName
    return console.log "#{pluginName}不存在" if not _fs.existsSync pluginDir
    _fs.removeSync pluginDir
    console.log "插件#{pluginName}已经被卸载".green

#列出所有的插件
exports.list = (isGlobal)->
  pluginRootDir = getPluginDirectory(isGlobal)
  return console.log "没有安装任何插件".green if not _fs.existsSync pluginRootDir

  total = 0
  console.log '\n'
  console.log pluginRootDir
  console.log 'Plugins: '
  plugins = _fs.readdirSync pluginRootDir
  _.map plugins, (pluginName)->
    pluginDir = _path.join pluginRootDir, pluginName
    pluginPackage = _path.join pluginDir, 'package.json'
    return if not _fs.existsSync pluginPackage

    total++
    pkg = _fs.readJSONFileSync pluginPackage, 'utf-8'
    console.log "#{pluginName}->#{pkg.version}".green

  console.log "#{total} plugin(s) has been already installed."
