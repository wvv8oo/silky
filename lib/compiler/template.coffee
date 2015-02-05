###
    读取所有模板
###

_fs = require 'fs'
_path = require 'path'
_common = require '../common'
_handlebars = require 'handlebars'
_data = require '../data'
_cheerio = require 'cheerio'
_ = require 'lodash'
_htmlpretty = require('js-beautify').html
require 'colors'

#模板
_templtes = {}
#系统出错的模板
_errorTemplate = null

###
#根据文件名提取key
getTemplateKey = exports.getTemplateKey = (file)->
	#取相对于template的路径
	key = _path.relative _path.join(_common.options.workbench, 'template/'), file

	#替换掉扩展名
	key = key.replace _path.extname(key), ''
	key = _common.replaceSlash key
	key
###


#渲染一个模板
exports.render = (file, pluginData)->
  try
    content = _common.readFile file
    template = _handlebars.compile content
    #使用json的数据进行渲染模板
    data = _data.whole.json
    data.$ = _data.whole.language
    data.$$ = {}
    #附加运行时的环境，兼容旧版本用silky，以后使用$$.silky
    data.silky = _.extend({}, _common.options)
    data.silky.isDevelopment = false
    #额外的附加数据
    data.$$.plugin = pluginData
    data.$$.silky = data.silky
    data.$$.file = file
    data._ = data

    content = template data
#    html = injectScript content
    #暂时不注入script，以后用livereload的时候再考虑
    html = content
    return if _common.config.beautify then _htmlpretty(html) else html;

  catch e
  #调用目的是为了产品环境throw
    _common.combError(e)
    _errorTemplate(e)


#初始化
exports.init = ()->
  #读取系统出错模板，并编译
  file = _path.join __dirname, '../client/error.hbs'
  content =  _common.readFile file
  _errorTemplate = _handlebars.compile content