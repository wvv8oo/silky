###
  安装卸载插件
###
_path = require 'path'
_fs = require 'fs-extra'
_ = require 'lodash'
_async = require 'async'

_utils = require '../utils'
_plugin = require './index'
_host = require './host'
_hooks = require './hooks'

##更新仓库，如果仓库不存在，则clone仓库
#updateGitRepos = (remoteRepos, localRepos, cb)->
#  console.log "正在同步git仓库..."
#  #目录已经存在，则clone
#  if _fs.existsSync localRepos
#    command = "cd \"#{localRepos}\" && git pull"
#  else
#    command = "git clone \"#{remoteRepos}\" \"#{localRepos}\""
#
#  _utils.execCommand command, (code)->
#    console.log "同步git仓库完成"
#    cb code

#注册为一个编译器，将编译器的插件写入到全局，启动的时候会调用
registerAsCompiler = (pluginName)->
  allCompiler = _utils.globalConfig?.compiler || {}
  #存在，则不处理
  return if allCompiler[pluginName]
  _utils.xPathSetValue "compiler.#{pluginName}", _utils.globalConfig, {}
  #保存全局配置
  _utils.saveGlobalConfig()

#从本地目录安装插件
installPluginFromLocalDir = (pluginName, pluginRootDir, sourcePluginDir, registry, cb)->
  console.log "准备安装#{pluginName}"
  console.log sourcePluginDir
  return console.log "#插件#{pluginName}不存 在，安装失败".red if not _fs.existsSync sourcePluginDir

  #如果没有给插件名称，则取源的文件名（这里其实应该读package.json，再取名称好一点）
  pluginName = pluginName || _path.basename(sourcePluginDir)
  targetPluginDir = _path.join pluginRootDir, pluginName

  #删除目录，如果已经存在
  _fs.removeSync targetPluginDir if _fs.existsSync targetPluginDir
  _fs.copySync sourcePluginDir, targetPluginDir

  #切换到对应的目录，并运行npm install
  cd targetPluginDir

  result = exec "npm install --verbose --registry #{registry}"
  errMsg = "#{pluginName}安装失败"

  if result.code isnt 0
    console.log errMsg.red
    return cb null

  #安装插件成功，检查是否为编译器
  try
    plugin = require targetPluginDir
    #注册为编译器
    registerAsCompiler pluginName if plugin.compiler
    console.log "#{pluginName}安装成功".green
  catch e
    console.log errMsg.red
    console.log e

  cb null

#在指定仓库中安装插件列表
installPluginsFromLocalDir = (names, pluginRootDir, localRepos, registry, cb)->
  index = 0
  _async.whilst(
    -> index < names.length
    ((done)->
      pluginName = names[index++]
      #在仓库中的插件目录
      sourcePluginDir = _path.join localRepos, pluginName
      installPluginFromLocalDir pluginName, pluginRootDir, sourcePluginDir, registry, (err)-> done null
    ), cb
  )

#从指定源中安装
installFromSpecificSource = (pluginName, pluginRootDir, source, registry, cb)->
  #没有以git结尾，直接从本地安装
  if not /\.git$/i.test source
    #直接从本地安装
    return installPluginFromLocalDir pluginName, pluginRootDir, source, registry, cb

  #从git仓库安装
  cacheDir = _path.join _utils.globalCacheDirectory(), 'cache_repos', pluginName
  _fs.removeSync cacheDir

  _utils.updateGitRepos source, cacheDir, (code)->
    if code isnt 0
      console.log '安装失败'.red
      console.log err
      return cb null

    installPluginFromLocalDir pluginName, pluginRootDir, cacheDir, registry, cb

#从标准仓库中安装
installFromStandardRepos = (names, pluginRootDir, repository, registry, cb)->
  repository = repository || _utils.xPathMapValue('custom.pluginRepository', _utils.globalConfig)
  repository = repository || 'https://github.com/wvv8oo/silky-plugins.git'
  localRepos = _path.join _utils.globalCacheDirectory(), 'plugins'

  #更新仓库
  _utils.updateGitRepos repository, localRepos, (err)->
    if err
      console.log '安装失败'.red
      return console.log err

    installPluginsFromLocalDir names, pluginRootDir, localRepos, registry, cb

#安装插件
exports.install = (names, oringal, repository, registry, cb)->
  pluginRootDir = _utils.globalPluginDirectory()
  console.log "installing..."

  registry = switch registry
    when 'taobao' then 'https://registry.npm.taobao.org'
    when 'cnpmjs' then 'http://registry.cnpmjs.org'
    when 'au' then 'http://registry.npmjs.org.au'
    when 'nodejitsu' then 'https://registry.nodejitsu.com'
    else registry || 'https://registry.npmjs.org'

  #从指定的源安装，只安装一个
  if oringal
    installFromSpecificSource names[0], pluginRootDir, oringal, registry, cb
  else
    #从标准库中安装，可以安装多个
    installFromStandardRepos names, pluginRootDir, repository, registry, cb

#删除插件
exports.uninstall = (names, cb)->
  pluginRootDir = _utils.globalPluginDirectory()

  _.map names, (pluginName)->
    pluginDir = _path.join pluginRootDir, pluginName
    return console.log "#{pluginName}不存在" if not _fs.existsSync pluginDir

    #如果是一个插件，需要在config.js中删除
    plugin = require pluginDir
    _utils.xPathSetValue "compiler.#{pluginName}", _utils.globalConfig, null if plugin.compiler

    _fs.removeSync pluginDir
    console.log "插件#{pluginName}已经被卸载".green

  _utils.saveGlobalConfig()
  cb null

#列出所有的插件
exports.list = ()->
  pluginRootDir = _utils.globalPluginDirectory()
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

#用于执行某个插件一次
exports.run = (pluginName, cb)->
  file = _path.join _utils.globalPluginDirectory(), pluginName
  if not _fs.existsSync file
    console.log "Plugin #{pluginName} is not found."
    return cb null

  options = _utils.config.plugins[pluginName] || {}
  #注册插件
  _plugin.registerPlugin pluginName, options
  #调用插件
  _host.triggerHook _hooks.plugin.run, cb