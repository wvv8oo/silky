_async = require 'async'
_ = require 'lodash'
_utils = require '../utils'
_handlebars = require 'handlebars'
_compiler = require '../compiler'
_data = require '../data'

HOOKS = {}
COMPILER = {}

#注册一个插件
exports.silkyForHook = (pluginName, pluginPriority)->
  utils:
    writeFile: _utils.writeFile
    readFile: _utils.readFile
    homeDirectory: _utils.homeDirectory
    replaceExt: _utils.replaceExt
    replaceSlash: _utils.replaceSlash
    watch: _utils.watch
    saveObjectAsCode: _utils.saveObjectAsCode
    execCommand: _utils.execCommand

  data: _data.whole
  #用于编译的处理器
  compiler: _compiler
  detectFileType: _utils.detectFileType

  #注册一个插件数据的存储目录
  registerPluginDirectory: (relativePath)->
    path = _path.join _utils.globalSilkyIdentityDir(), 'plugin', '.data', pluginName, relativePath
    _fs.ensureDirSync path
    path

  #注册一个handlebars的helper
  registerHandlebarsHelper: (name, factory)->
    _handlebars.registerHelper name, factory

  #注册一个编译器，不同插件后面的会覆盖前面的
  registerCompiler: (compilerName, factory)->
    console.log "警告：编译器#{compilerName}将被覆盖".red if COMPILER[compilerName]
    #保存编译器
    COMPILER[compilerName] = factory

  #注册一个cli命令
  registerCommand: ()->
    console.log '此功能还没有完成'

  config: _utils.config
  options: _utils.options
  #注册一个hook
  registerHook:  (hookName, options, factory)->
    if typeof(options) is 'function'
      factory = options
      options = {}

    options = _.extend {priority: 100, async: false}, options
    #配置文件中强制指定了插件的优先级
    options.priority = pluginPriority if pluginPriority isnt undefined
    HOOKS[hookName] = [] if not HOOKS[hookName]
    HOOKS[hookName].push
      pluginName: pluginName
      options: options
      factory: factory

#插件加载完成后，需要对hook根据优先级进行排序
exports.sort = ()->
  for name, list of HOOKS
    list.sort (left, right)-> if left.options.priority > right.options.priority then 1 else -1

#根据文件类型，获取匹配的编译器类型
exports.getCompiler = (type)-> COMPILER[type]

#解发hook
exports.triggerHook = (hookName, data, cb)->
  hooks = HOOKS[hookName]
  stop = false
  index = 0

  #没有提供data参数
  if arguments.length is 2 and typeof data is 'function'
    cb = data
    data = {}

  return cb null, stop if not hooks

  #依次调用hook
  _async.whilst(
    -> index < hooks.length and not stop
    ((done)->
      hook = hooks[index++]
      _utils.debug "Plugin -> #{hook.pluginName}; Priority -> #{hook.options.priority}; Hook -> #{hookName}"
      #获取插件的配置信息
      #options = _utils.config.plugins?[hook.pluginName]
      #异步处理
      if hook.options.async
        hook.factory data, -> done null
      else
        #同步
        hook.factory data
        done null
    ), -> cb null
  )