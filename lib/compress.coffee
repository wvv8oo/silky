_uglify = require 'uglify-js'
_hookHost = require './plugin/host'
_async = require 'async'
_fs = require 'fs-extra'
_script = require './script'
_uglify = require 'uglify-js'
_cleanCSS = require 'clean-css'
_common = require './common'
_buildConfig = _common.config.build
_hooks = require './plugin/hooks'

#压缩js
compressJS = (file, cb)->
  #不需要压缩
  return cb null if not _buildConfig.compress.js
  _uglify.minify file

#压缩css
compressCSS = (file, cb)->
  return cb null if not _buildConfig.compress.css
  content = _common.readFile file
  content = new _cleanCSS().minify content
  _common.writeFile file, content
  cb null

#压缩html以及internal script
compressHTML = (file, cb)->
  return cb null if not _buildConfig.compress.html and not _buildConfig.compress.internal

  compressInternal = _buildConfig.compress.internal and /<script.+<\/script>/i.test(content)
  rewrite = compressInternal or _buildConfig.compress.html

  content = _common.readFile file
  #如果不包含script在页面中，则不需要压缩
  if compressInternal
    #压缩internal的script
    content = compressInternalJavascript content
  else if _buildConfig.compress.html
    #暂时不压缩html，以后考虑压缩html
    content = content

  _common.writeFile file, content if rewrite
  cb null

#调用cheerio，提取并压缩内联的js
compressInternalJavascript = (content)->
  $ = _cheerio.load content
  #跳过模板部分
  $('script').each ()->
    $this = $(this)
    if $this.attr('type') isnt 'html/tpl'
      minify = scriptMinify $this.html()
      $this.html minify

  $.html()

#压缩javascript的内容
scriptMinify = (content)->
  result = _uglify.minify content, fromString: true
  result.code

#压缩文件，仅压缩html/js/
compressSingleFile = (file, cb)->
  #只处理js/html/css
  if /\.js$/i.test file
    compressJS file, cb
  else if /\.css$/i.test file
    compressCSS file, cb
  else if /\.html?$/i.test file
    compressHTML file, cb
  else
    cb null

#压缩目录
compressDirectory = (dir, cb)->
  files = _fs.readdir dir
  index = 0
  _async.whilst(
    -> index < files.length
    ((done)->
      filename = files[index++]
      path = _path.join dir, filename
      compress path, done
    ),
    cb
  )

#混淆整个目录或者文件
compress = exports.compress = (path, cb)->
  stat = _fs.statSync path

  queue = []
#  压缩之前，先让hook处理
  queue.push(
    (done)->
      data =
        stat: stat
        path: path
        stop: false

      _hookHost.triggerHook _hooks.build.willCompress, data, (err)-> done data.stop
  )

  #处理文件或者目录
  queue.push(
    (done)->
      if stat.isDirectory()
        compressDirectory path, done
      else
        compressSingleFile path, done
  )

  #处理完的hook
  queue.push(
    (done)->
      _hookHost.triggerHook _hooks.build.didCompress, null, done
  )

  _async.waterfall queue, cb