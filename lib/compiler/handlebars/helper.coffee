_handlebars = require 'handlebars'
_path = require 'path'
_fs = require 'fs-extra'
_ = require 'lodash'
_moment = require 'moment'

_utils = require '../../utils'

########################################################处理linkHelper############################
#获取css/js的链接
getLinkUrl = (type, url)->
  if type is 'css'
    extname = '.css'
    linkTemplate = '<link rel="stylesheet" href="{{url}}" type="text/css" charset="utf-8" />'
  else
    extname = '.js'
    linkTemplate = '<script src="{{url}}" language="javascript"></script>'

  url += extname if not _path.extname(url)    #检查是否有扩展名
  url = linkTemplate.replace '{{url}}', url


#分析路径
replaceNestVariable = (text, data)->
  text.replace /\<(.+?)\>/g, (k, xPath)-> _utils.xPathMapValue xPath, data

#拼接多个文件
joinFile = (path, files, data)->
  result = []
  path = replaceNestVariable path, data
  files.split(',').forEach (file)-> result.push _path.join(path, file)
  result

#检查某个字符是否在匹配列表中，支持正则，或者完全匹配
isMatch = (text, list)->
  for item in list
    match =  if item instanceof RegExp then item.test(text) else item is text
    break if match

  match

#是否跳过文件
skipFile = (filename, match, ignore)->
  match = [match] if not (match instanceof Array)
  ignore = [ignore] if not (ignore instanceof Array)

  #检查是否跳过
  isMatch(filename, ignore) or not isMatch(filename, match)

#获取
joinFileWithConfig = (config, data)->
  baseUrl = replaceNestVariable config.baseUrl, data

  result = []
  #扫描文件夹
  dir = _path.join _utils.options.workbench, config.dir
  _fs.readdirSync(dir).forEach (filename)->
    #跳过不需要的文件
    return if skipFile filename, config.match, config.ignore

    file = _path.join dir, filename
    stat = _fs.statSync file
    return if stat.isDirectory()
    #主动加上/
    baseUrl += '/' if not /\/$/.test baseUrl
    url = baseUrl + filename
    url = url.replace(config.path, config.to) if config.path and config.to
    result.push url
  result

#编译partial
compilePartial = (hbsPath, context, options)->
  relativePath = hbsPath + '.hbs'
  #替换其中的路径
  relativePath = relativePath.replace /<(.+)>/, (match, xPath)->
    ##查找xPath
    _utils.xPathMapValue xPath, options.data.root

  #如果使用了绝对路径，则从当前项目的根目录开始查找
  if relativePath.indexOf('/') is 0
    file = _path.join _utils.options.workbench, relativePath
  #兼容模式，从templateDir中取数据
  else if _utils.config.compatibleModel
    file = _path.join _utils.getTemplateDir(), relativePath
  else
    #从相对路径中取数据
    file = _path.resolve _path.dirname(context._.$$.file), relativePath

  return "无法找到partial：#{file}" if not _fs.existsSync file

  content = _utils.readFile file

  #扫描子模块中的所有{{}}，如果发现有直接取值的，则考虑提醒用户
  content.replace /\{\{(\w+)\}\}/ig, (entire, core)->
    return if /else|now|raw|date/i.test core
    console.log "#{entire} -> {{$0.#{core}}}".red
    console.log "File: #{_path.relative(_utils.options.workbench, file)}".red

  #查找对应的节点数据
  template = _handlebars.compile content
  template(context)


########################################################处理扩展命令############################
#处理链接
linkCommand = (args...)->
  #第二个(即调用时的第一个参数)参数是object，表示是从配置文件中读取的
  if typeof args[0] is 'object'
    #{{link global.linkCSS}}
    options = args[1]
    files = joinFileWithConfig(args[0], options.data.root)
  else if typeof args[0] is 'string' and typeof args[1] is 'object'
    #{{link '<global.root>/css/main.css'}}
    options = args[1]
    files = [replaceNestVariable(args[0], options.data.root)]
  else
    #{{link '<global.root>/css/' 'css1,css2'}}
    options = args[2]
    files = joinFile args[0], args[1], options.data.root

  links = []

  links.push getLinkUrl(options.name, url) for url in files
  new _handlebars.SafeString links.join('\n')

#引入文件的命令
importCommand = (name, args...)->
  options = args.pop()
  data = _.extend {}, options.data.root._ || options.data.root

  #要清掉旧数据中的$index
  #注意，此处不需要删除，因为data是从root中clone过来的
  #(delete data[key] if /^\$\d+$/.test key) for key, value of data

  #收集每一个参数，按$+index的方式存入data
  for value, index in args
    #如果是函数，则先调用
    value = value() if _.isFunction value
    data["$#{index}"] = value

  data.$current = data.$0

  html = compilePartial(name, data, options)
  new _handlebars.SafeString(html)

#如果两者等于，则输出
ifEqualCommand = (left, right, options)->
  return if left is right then options.fn(this) else ""

#或
orCommand = (args..., options)->
  for item in args
    return item if item

#循环
loopCommand = (name, condition, options)->
  return console.log "Loop必需提供两个参数".red if arguments.length isnt 3

  #循环
  condition = condition || []
  isNumber = typeof condition is 'number'
  list = if isNumber then [1..condition] else condition
  results = []

  _.map list, (item, index)->
    current = if _.isObject(item) then item else {$current: item}
    current.$index = index

    context = _.extend current, options.data.root
    results.push compilePartial(name, context, options)

  new _handlebars.SafeString(results.join(''))

#仅重复block内html
repeatCommand = (count, options)->
  console.log "警告：justloop将会停止使用，请使用repeat".red if options.name is 'justloop'

  count = ~~count
  self = this
  html = ''
  for index in [0...count]
    self.$index = index
    html += options.fn(self)
  html

#获取xPath
xPathCommand = (path, value, options)->
  if not options
    options = value
    value = options.data.root

  _utils.xPathMapValue path, value

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

#输出不解析的数据
rawHelper = (options)->options.fn()

#执行数据库的命令
executeCommand = (cmd, args...)->
  fn = if _.isFunction cmd then cmd else _utils.xPathMapValue(cmd, this)
  return "#{cmd} is not a valid function." if not _.isFunction fn

  options = args.pop()
  result = fn.apply null, args
  return result if not (options.fn and options.inverse)
  if result then options.fn this else options.inverse this

#比较
compareCommand = (left, symbol, right, options)->
  console.log _.indexOf(right, left)
  result = switch symbol
    when '==' then `left == right`
    when '===' then left is right
    when 'in' then _.indexOf(right, left) >= 0
    when '<' then left < right
    when '<=' then left <= right
    when '>' then left > right
    when '>=' then left >= right
    when '!=' then left != right
    when '!==' then left isnt right

  if result
    options.fn this
  else
    options.inverse this

#注册handlebars，直接执行
(->
  _handlebars.registerHelper 'raw', rawHelper
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
    return 'Print: is not JSON object' if not _.isPlainObject value
    new _handlebars.SafeString JSON.stringify(value)

  _handlebars.registerHelper 'css', linkCommand
  #引入外部脚本，支持文件夹引用
  _handlebars.registerHelper 'script', linkCommand
  
  #循环
  _handlebars.registerHelper "loop", loopCommand
  _handlebars.registerHelper "justloop", repeatCommand
  _handlebars.registerHelper "repeat", repeatCommand

  #partial与import
  _handlebars.registerHelper "partial", importCommand
  _handlebars.registerHelper "import", importCommand
  #条件
  _handlebars.registerHelper "ifEqual", ifEqualCommand

  #or
  _handlebars.registerHelper 'or', orCommand
  #timestamp

  #比较
  _handlebars.registerHelper 'compare', compareCommand

  #执行data中的函数
  _handlebars.registerHelper 'execute', executeCommand
)()