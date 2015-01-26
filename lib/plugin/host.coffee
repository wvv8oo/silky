_async = require 'async'
_hooks = {}
_q = require 'q'
_ = require 'lodash'
_common = require '../common'
_handlebars = require 'handlebars'

#注册一个插件
exports.silkyForHook = (pluginName, pluginPriority)->
  #注册一个handlebars的helper
  registerHandlebarsHelper: (name, factory)->
    _handlebars.registerHelper name, factory

  #注册一个cli命令
  registerCommand: ()->
    console.log '此功能还没有完成'

  options: _common.config
  #注册一个hook
  registerHook:  (hookName, options, factory)->
    if typeof(options) is 'function'
      factory = options
      options = {}

    options = _.extend {priority: 100, async: false}, options
    #配置文件中强制指定了插件的优先级
    options.priority = pluginPriority if pluginPriority isnt undefined
    _hooks[hookName] = [] if not _hooks[hookName]
    _hooks[hookName].push
      pluginName: pluginName
      options: options
      factory: factory

#插件加载完成后，需要对hook根据优先级进行排序
exports.sort = ()->
  for name, list of _hooks
    list.sort (left, right)-> if left.options.priority > right.options.priority then 1 else -1

#解发hook
exports.triggerHook = (hookName, data, cb)->
  hooks = _hooks[hookName]
  stop = false
  index = 0
  return cb null, stop if not hooks

  #依次调用hook
  _async.whilst(
    -> index < hooks.length and not stop
    ((done)->
      hook = hooks[index++]
      _common.debug "Plugin -> #{hook.pluginName}; Priority -> #{hook.options.priority}; Hook -> #{hookName}"
      #获取插件的配置信息
      options = _common.config.plugins?[hook.pluginName]
      #异步处理
      if hook.options.async
        hook.factory data, options, -> done null
      else
        #同步
        hook.factory data, options
        done null
    ), -> cb null
  )