_handlebars = require 'handlebars'
_path = require 'path'
_common = require './common'
_fs = require 'fs-extra'
_ = require 'underscore'
_linkHelper = require './linkHelper'

#编译partial
compilePartial = (name, context)->
  file = _path.join _common.getTemplateDir(), name + '.hbs'
  return "无法找到partial：#{name}" if not _fs.existsSync file

  content = _common.readFile file
  #查找对应的节点数据
  template = _handlebars.compile content
  template(context)

#引入文件的命令
importCommand = (name, context, options)->
  #如果则第二个参数像options，则表示没有提供参数
  if context and context.name in ['import', 'partial']
    options = context
    context = _.extend {}, options.data.root

  context = context || options.data.root
  context = context() if _.isFunction context
  context._ = options.data.root
  #合并silky到context
  context.silky = _.extend {}, _common.options if not context.silky
  html = compilePartial(name, context || {})
  new _handlebars.SafeString(html)

ifEqualCommand = (left, right, options)->
  return if left is right then options.fn(this) else ""

orCommand = (args..., options)->
  for item in args
    return item if item

#循环
loopCommand = (name, count, options)->
  #循环
  count = count || []
  isNumber = typeof count is 'number'
  count = [1..count] if isNumber
  results = []

  for value in count
    #如果循环次数量，则将上级数据传递下去
    context = if isNumber then _.extend({'$index': value}, options.data.root) else value
    results.push compilePartial(name, context)

  new _handlebars.SafeString(results.join(''))


#注册handlebars
exports.init = ->
  #获取xPath
  _handlebars.registerHelper 'xPath', (path, value, options)->
    if not options
      options = value
      value = options.data.root
    _common.xPathMapValue path, value

  #获取当前时间
  _handlebars.registerHelper 'now', ()-> new Date().toString()

  #打印出变量
  _handlebars.registerHelper 'print', (value)->
    return '<empty>' if value is undefined
    new _handlebars.SafeString JSON.stringify(value)

  _handlebars.registerHelper 'css', _linkHelper.linkCommand
  #引入外部脚本，支持文件夹引用
  _handlebars.registerHelper 'script', _linkHelper.linkCommand
  #循环
  _handlebars.registerHelper "loop", loopCommand
  #partial与import
  _handlebars.registerHelper "partial", importCommand
  _handlebars.registerHelper "import", importCommand
  #条件
  _handlebars.registerHelper "ifEqual", ifEqualCommand

  #or
  _handlebars.registerHelper 'or', orCommand