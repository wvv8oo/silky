###
  支持插件的功能，在启动的时候，会扫描当前工作目录.silky/plugin下的插件
###
_fs = require 'fs-extra'
_path = require 'path'
_common = require '../common'
_host = require './host'
#_plugins = []

##扫描当前工作目录下的插件
#scanPlugins = ()->
#  folder = 'plugin'
#  localPluginDir = _path.join _common.options.workbench, _common.options.identity, folder
#  scanPluginsInSpecificDirectory localPluginDir
#
#  #扫描全局的插件，用户可以在全局配置文件中 指定，如果没有指定，则在home目录
#  defaultGlobalPluginDir = _path.join _common.homeDirectory(), _common.options.identity, folder
#  globalPluginDir = _common.config.globalPluginDirectory || defaultGlobalPluginDir
#  scanPluginsInSpecificDirectory globalPluginDir
#  _common.debug "Global Plugin -> #{globalPluginDir}".green

#根据插件名称，从全局插件目录中注册插件
registerPlugin = (pluginName, options)->
  options = options || {}
  file = _path.join _common.globalPluginDirectory(), pluginName
  #插件已经指定了源，则从指定源中加载
  file = _path.resolve _common.options.workbench, options.source if options.source

  #强制禁止了插件
  if options.enable is false
    console.log "插件#{pluginName}已经被强制禁用".red
    return

  try
    if not _fs.existsSync file
      console.log "插件#{pluginName}不存在，请使用 silky install #{pluginName} 安装".red
      return

    plugin = require file
    return console.log("#{filename}不是一个合法的Silky插件") if not plugin.silkyPlugin
    #将插件加入到插件列表，并注册hook
    #_plugins.push plugin
    silky = _host.silkyForHook(pluginName, options.priority)
    plugin.registerPlugin silky, options
    console.log "插件加载成功 -> #{pluginName}".green
  catch e
    console.log "插件加载失败->#{pluginName}".red
    console.log file
    console.log e
    process.exit 1

##扫描插件
#scanPluginsInSpecificDirectory = (dir)->
#  return if not _fs.existsSync dir
#  #扫描工作目录
#  _fs.readdirSync(dir).forEach (pluginName)->
#    file = _path.join dir, pluginName, 'index'
#    exists = _fs.existsSync(file + ".coffee") or _fs.existsSync(file + ".js")
#    registerPlugin file, pluginName if exists

#根据配置文件加载插件
loadPluginsWithConfig = ()->
  #globalSilkyPluginDir
  plugins = _common.config.plugins || {}
  #注册插件
  registerPlugin(pluginName, options) for pluginName, options of plugins

exports.init = ()->
  loadPluginsWithConfig()
  #扫描完插件需要重新排序，不然无法实现优先级
  _host.sort()
