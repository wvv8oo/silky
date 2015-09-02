_uglify = require 'uglify-js'
_async = require 'async'
_fs = require 'fs-extra'
_path = require 'path'
_cleanCSS = require 'clean-css'
_cheerio = require 'cheerio'
_ = require 'lodash'

_hookHost = require '../plugin/host'
_utils = require '../utils'
_hooks = require '../plugin/hooks'
_aft = require './aft'

#压缩js
compressJS = (entity, cb)->
  #不需要压缩
  return cb null if not _utils.xPathMapValue('build.compress.js', _utils.config)
  console.log "Compress JS #{entity.target}"
  entity.content = _uglify.minify(entity.content, {fromString: true}).code
  cb null

#压缩css
compressCSS = (entity, cb)->
  userOptions = _utils.xPathMapValue('build.compress.css', _utils.config)
  return cb null if not userOptions

  #默认的选项，不支持ie6
  options = compatibility: 'ie7'
  options = userOptions if typeof userOptions is 'object'

  console.log "Compress CSS #{entity.target}"
  entity.content = new _cleanCSS(options).minify entity.content
  cb null

#压缩html以及internal script
compressHTML = (entity, cb)->
  compressHtml = _utils.xPathMapValue('build.compress.html', _utils.config)
  compressInternal = _utils.xPathMapValue('build.compress.internal', _utils.config)
  return cb null if not compressHtml and not compressInternal

  console.log "Compress HTML #{entity.target}"
  compressInternal = compressInternal and /<script.+<\/script>/i.test(entity.content)

  #如果不包含script在页面中，则不需要压缩
  if compressInternal
    #压缩internal的script
    entity.content = compressInternalJavascript entity

#  if compressHtml
#    #暂时不压缩html，以后考虑压缩html
#    content = content

  cb null

#调用cheerio，提取并压缩内联的js
compressInternalJavascript = (entity)->
  $ = _cheerio.load entity.content
  #跳过模板部分
  $('script').each ()->
    $this = $(this)
    if $this.attr('type') isnt 'html/tpl'
      minify = scriptMinify entity, $this.html()
      $this.html minify

  $.html()

#压缩javascript的内容
scriptMinify = (entity, script)->
  try
    result = _uglify.minify script, fromString: true
    result.code
  catch e
    console.log "编译JS出错，文件：#{entity.source}".red
    console.log e
    console.log script.red
    return script

#压缩文件，仅压缩html/js/
compressSingleFile = (entity, cb)->
  return cb null if not entity.compress

  #只处理js/html/css
  switch entity.type
    when 'js' then compressJS entity, cb
    when 'css' then compressCSS entity, cb
    when 'html' then compressHTML entity, cb
    else cb null


#混淆整个目录或者文件
compress = (entity, cb)->
  queue = []
#  压缩之前，先让hook处理
  queue.push(
    (done)->
      _hookHost.triggerHook _hooks.build.willCompress, entity, (err)-> done err
  )

  #处理文件或者目录
  queue.push(
    (done)-> compressSingleFile entity, done
  )

  #处理完的hook
  queue.push(
    (done)->
      _hookHost.triggerHook _hooks.build.didCompress, null, done
  )

  _async.waterfall queue, -> cb null

#执行压缩
exports.execute = (cb)->
  entities = _aft.tree()
  index = 0
  keys = _.keys entities

  _async.whilst(
    -> index < keys.length
    ((done)->
      entity = entities[keys[index++]]
      compress entity, done
    ),
    cb
  )

#根据配置文件，检测文件是否需要压缩
exports.needCompress = (source)->
  rules = _utils.xPathMapValue('build.compress.ignore', _utils.config)
  not _utils.simpleMatch(rules, source)