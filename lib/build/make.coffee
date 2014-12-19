_async = require 'async'
_path = require 'path'
_fs = require 'fs-extra'

_hooks = require '../plugin/hooks'
_hookHost = require '../plugin/host'
_common = require '../common'
_script = require '../processor/script'
_css = require '../processor/css'
_template = require '../processor/template'

_buildConfig = null
_outputRoot = null

#编译coffee
coffeeProcessor = (source, target, cb)->
  #读取文件
  content = _script.compile source
  _common.writeFile target, content
  cb null

#编译less
lessProcessor = (source, target, cb)->
  _css.render source, (err, css)->
    if err
      console.log "CSS Error: #{source}".red
      console.log err.message.red
      return process.exit(0)

    _common.writeFile target, css
    cb null

#编译handlebars
handlebarsProcessor = (source, target, cb)->
  #handlebars渲染
  content = _template.render source
  _common.writeFile target, content
  cb null


#复制文件
copyFile = (source, target, cb)->
  _fs.copySync source, target
  cb null

#根据配置，替换目标路径
replaceTargetWithConfig = (target)->
  relativePath = _path.relative _outputRoot, target

  for item in _buildConfig.rename
    if item.source.test relativePath
      relativePath = relativePath.replace item.source, item.target
      break if not item.next

  _path.join _outputRoot, relativePath

#替换掉目标的扩展名，内置的几种处理方式
replaceTargetExt = (source, target)->
  maps = coffee: 'js', hbs: 'html', less: 'css'
  target.replace /\.(coffee|hbs|less)$/i, (full, ext)-> ".#{maps[ext] || ext}"

#  targetExt = null
#  if /\.hbs$/i.test source
#    targetExt = '.html'
#  else if /\.less$/i.test source
#    targetExt = '.css'
#  else if /\.coffee$/i.test source
#    targetExt = '.js'
#
#  return target if not targetExt
#  _common.replaceExt target, targetExt

#处理文件夹
arrangeDirectory = (source, target, cb)->
  files = _fs.readdirSync source
  index = 0
  _async.whilst(
    -> index < files.length
    ((done)->
      filename = files[index++]
      newSource = _path.join source, filename
      newTarget = _path.join target, filename
      arrangeObject newSource, newTarget, done
    ),
    cb
  )

#处理单个文件
arrangeSingleFile = (source, target, cb)->
  processor = null
  if /\.hbs$/i.test source
    processor = handlebarsProcessor
  else if /\.less$/i.test source
    processor = lessProcessor
  else if /\.coffee$/i.test source
    processor = coffeeProcessor

  copyOnly = processor is null
  queue = []
  #编译前
  queue.push(
    (done)->
      data =
        source: source
        target: target

      _hookHost.triggerHook _hooks.build.willCompile, data, (err)->
        done null
  )

  #编译中
  queue.push(
    (done)->
      relativeSource = _path.relative _common.options.workbench, source

      if copyOnly
        _fs.copySync source, target
        console.log "Copy -> #{relativeSource}".green
        return done null

      #编译器处理
      console.log "Compile -> #{relativeSource}".cyan
      processor source, target, done
  )

  queue.push(
    (done)->
      data =
        source: source
        target: target

      _hookHost.triggerHook _hooks.build.didCompile, data, done
  )

  _async.waterfall queue, (err)-> cb err

#处理一个对象，可能是文件或者文件夹
arrangeObject = (source, target, cb)->
  stat = _fs.statSync source
  #对于文件类型，要考虑需要替换为编译后的扩展名
  target = replaceTargetExt source, target if not stat.isDirectory()
  #相对路径用于识别是否需要跳过或者
  relativePath = _path.relative _common.options.workbench, source
  #.silky这个目录需要强制跳过
  return cb null if relativePath is _common.options.identity

  #根据规则，替换target的路径
  target = replaceTargetWithConfig target

  copyOnly = false
  queue = []
  queue.push(
    (done)->
      data =
        stat: stat
        source: source
        ignore: _common.simpleMatch _buildConfig.ignore, relativePath
        copy: _common.simpleMatch _buildConfig.copy, relativePath
        relativePath: relativePath
        target: target

      _hookHost.triggerHook _hooks.build.willProcess, data, (err)->
        copyOnly = data.copy
        target = data.target
        console.log "Ignore -> #{relativePath}".blue if data.ignore
        done data.ignore
  )

  queue.push(
    (done)->
      if copyOnly   #复制文件
        console.log "Copy -> #{relativePath}".green
        copyFile source, target, done
      else if stat.isDirectory()  #处理目录
        arrangeDirectory source, target, done
      else    #处理单个文件
        arrangeSingleFile source, target, done
  )

  #处理目录后的hook
  queue.push(
    (done)->
      _hookHost.triggerHook _hooks.build.didProcess, null, done
  )

  _async.waterfall queue, (err)-> cb null

#对外的入口
exports.execute = (output, cb)->
  _buildConfig = _common.config?.build
  _outputRoot = output
  arrangeObject _common.options.workbench, output, cb