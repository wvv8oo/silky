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
_compilerMgr = require '../compiler_manager'

#渲染一个模板
hbsHandler = (content, options, cb)->
  try
    hbsTemplate = _handlebars.compile content

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
    data.$$.file = options.source
    data._ = data

    htmlContent = hbsTemplate data
#    html = injectScript content
    #暂时不注入script，以后用livereload的时候再考虑
    isBeautify =  _utils.xPathMapValue('beautify.html', _utils.config)
    htmlContent = _htmlpretty(htmlContent) if isBeautify
    cb null, htmlContent
  catch e
    console.log e
    cb e, false

module.exports = _compilerMgr.registerCompiler('hbs', 'hbs', 'html', hbsHandler)