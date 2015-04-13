_handlebars = require 'handlebars'
_path = require 'path'
_common = require '../common'
_fs = require 'fs-extra'
_ = require 'lodash'
_linkHelper = require './linkHelper'
_moment = require 'moment'

#编译partial
compilePartial = (hbsPath, context, options)->
  relativePath = hbsPath + '.hbs'
  #替换其中的路径
  relativePath = relativePath.replace /<(.+)>/, (match, xPath)->
    ##查找xPath
    _common.xPathMapValue xPath, options.data.root

  #如果使用了绝对路径，则从当前项目的根目录开始查找
  if relativePath.indexOf('/') is 0
    file = _path.join _common.options.workbench, relativePath
  #兼容模式，从templateDir中取数据
  else if _common.config.compatibleModel
    file = _path.join _common.getTemplateDir(), relativePath
  else
    #从相对路径中取数据
    file = _path.resolve _path.dirname(context._.$$.file), relativePath

  return "无法找到partial：#{file}" if not _fs.existsSync file

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
  html = compilePartial(name, context || {}, options)
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
    results.push compilePartial(name, context, options)

  new _handlebars.SafeString(results.join(''))

#仅循环block内html
justLoopCommand = (count, options)->
  count = ~~count
  new Array(count + 1).join options.fn(this)

xPathCommand = (path, value, options)->
  if not options
    options = value
    value = options.data.root

  _common.xPathMapValue path, value

#截断字符串
substrHelper = (value, limit, options)->
  return value if typeof value isnt 'string'
  value.substr limit

#日期的处理
#{{date value 'yyyy-mm-dd'}}
dateHelper = (args...)->
  value = args[0] || new Date()
  #用于转换原始值的的格式化字符，即_moment(value, fmtSource)
  fmtSource = undefined
  fmtTarget = 'YYYY-MM-DD'

  fmtSource = args[3] if args.length is 4
  fmtTarget = args[1] if args.length > 2

  date = _moment value, fmtSource
  return value if not date.isValid()
  date.format fmtTarget

#注册handlebars
exports.init = ->
  _handlebars.registerHelper 'substr', substrHelper
  _handlebars.registerHelper 'date', dateHelper
  #获取xPath
  _handlebars.registerHelper 'xPath', xPathCommand

  #获取当前时间
  _handlebars.registerHelper 'now', (formatter, options)->
    now = _moment()
    if typeof(formatter) is 'string' then now.format(formatter) else now.valueOf()

  #打印出变量
  _handlebars.registerHelper 'print', (value)->
    return '<empty>' if value is undefined
    new _handlebars.SafeString JSON.stringify(value)

  _handlebars.registerHelper 'css', _linkHelper.linkCommand
  #引入外部脚本，支持文件夹引用
  _handlebars.registerHelper 'script', _linkHelper.linkCommand
  
  #循环
  _handlebars.registerHelper "loop", loopCommand
  _handlebars.registerHelper "justloop", justLoopCommand

  #partial与import
  _handlebars.registerHelper "partial", importCommand
  _handlebars.registerHelper "import", importCommand
  #条件
  _handlebars.registerHelper "ifEqual", ifEqualCommand

  #or
  _handlebars.registerHelper 'or', orCommand
  #timestamp

