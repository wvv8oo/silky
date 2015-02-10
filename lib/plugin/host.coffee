_async = require 'async'
_ = require 'lodash'
_common = require '../common'
_handlebars = require 'handlebars'
_compiler = require '../compiler'

HOOKS = {}
COMPILER = {}

#注册一个插件
exports.silkyForHook = (pluginName, pluginPriority)->
  #用于编译的处理器
  compiler: _compiler.execute
  detectFileType: _common.detectFileType

  #注册一个插件数据的存储目录
  registerPluginDirectory: (relativePath)->
    path = _path.join _common.globalSilkyIdentityDir(), 'plugin', '.data', pluginName, relativePath
    _fs.ensureDirSync path
    path

  #注册一个handlebars的helper
  registerHandlebarsHelper: (name, factory)->
    _handlebars.registerHelper name, factory

  #注册一个编译器
  registerCompiler: (type, factory)->
    COMPILER[type] = factory

  #注册一个cli命令
  registerCommand: ()->
    console.log '此功能还没有完成'

  config: _common.config
  options: _common.options
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
exports.getCompilerWith = (type)-> COMPILER[type]

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
      _common.debug "Plugin -> #{hook.pluginName}; Priority -> #{hook.options.priority}; Hook -> #{hookName}"
      #获取插件的配置信息
      #options = _common.config.plugins?[hook.pluginName]
      #异步处理
      if hook.options.async
        hook.factory data, -> done null
      else
        #同步
        hook.factory data
        done null
    ), -> cb null
  )