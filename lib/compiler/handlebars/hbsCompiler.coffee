###
    读取所有模板
###

_fs = require 'fs'
_path = require 'path'
_handlebars = require 'handlebars'
_ = require 'lodash'
_htmlpretty = require('js-beautify').html

_utils = require '../../utils'
_data = require '../../data'

#渲染一个模板
exports.compile = (source, options, cb)->
  try
    content = _utils.readFile source
    template = _handlebars.compile content

    #使用json的数据进行渲染模板
    data = _data.whole.json
    data.$ = _data.whole.language
    data.$$ = {}
    #附加运行时的环境，兼容旧版本用silky，以后使用$$.silky
    data.silky = _.extend({}, _utils.options)
    data.silky.isDevelopment = false
    #额外的附加数据
    data.$$.plugin = options.pluginData
    data.$$.silky = data.silky
    data.$$.file = source
    data._ = data

    content = template data
#    html = injectScript content
    #暂时不注入script，以后用livereload的时候再考虑
    isBeautify =  _utils.xPathMapValue('beautify.html', _utils.config)
    html = if isBeautify then _htmlpretty(content) else content

    #需要写入文件
    _utils.writeFile options.target, content if options.save and options.target
    cb null, html
  catch e
    #调用目的是为了产品环境throw
    _utils.combError(e)
    cb e
