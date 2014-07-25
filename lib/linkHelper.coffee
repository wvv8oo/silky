_handlebars = require 'handlebars'
_path = require 'path'
_common = require './common'
_fs = require 'fs-extra'
_ = require 'underscore'

#处理链接
exports.linkCommand = (args...)->
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

#获取css/js的链接
getLinkUrl = (type, url)->
  if type is 'css'
    extname = '.css'
    linkTemplate = '<link rel="stylesheet" href="{{url}}" type="text/css" media="screen" charset="utf-8" />'
  else
    extname = '.js'
    linkTemplate = '<script src="{{url}}" language="javascript"></script>'

  url += extname if not _path.extname(url)    #检查是否有扩展名
  url = linkTemplate.replace '{{url}}', url

#x.y.x这样的文本式路径，从data中找出对应的值
xPathMapValue = (xPath, data)->
  value = data
  xPath.split('.').forEach (key)->
    return if not (value = value[key])
  value

#分析路径
replaceNestVariable = (text, data)->
  text.replace /\<(.+?)\>/g, (k, xPath)-> xPathMapValue xPath, data

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
  dir = _path.join _common.options.workbench, config.dir
  _fs.readdirSync(dir).forEach (filename)->
    #跳过不需要的文件
    return if skipFile filename, config.match, config.ignore

    file = _path.join dir, filename
    stat = _fs.statSync file
    return if stat.isDirectory()
    url = _path.join(baseUrl, filename)
    url = url.replace(config.path, config.to) if config.path and config.to
    result.push url
  result