_async = require 'async'
_path = require 'path'
_fs = require 'fs-extra'

_hooks = require '../plugin/hooks'
_hookHost = require '../plugin/host'
_utils = require '../utils'
_compiler = require '../compiler'
_host = require '../plugin/host'

_buildConfig = null
_outputRoot = null


#根据build的规则，判断是否要忽略
pathIsIgnore = (source, relativePath)->
  ignore = false
  #跳过build的目录
  return true if _outputRoot is source
  #跳过.silky这个目录
  return true if _utils.options.identity is relativePath

  rules = _utils.config.build.ignore || []
  for rule in rules
    ignore = if typeof rule is 'string'
        rule is relativePath
      else
        rule.test(relativePath)

    break if ignore
  ignore

#根据配置，替换目标路径
replaceTargetWithConfig = (relativePath)->
  for item in _buildConfig.rename || []
    if item.source.test relativePath
      relativePath = relativePath.replace item.source, item.target
      break if not item.next

  relativePath

#替换掉目标的扩展名，内置的几种处理方式
replaceTargetExt = (relativePath)->
  maps = coffee: 'js', hbs: 'html', less: 'css'
  relativePath.replace /\.(coffee|hbs|less)$/i, (full, ext)-> ".#{maps[ext] || ext}"

#  targetExt = null
#  if /\.hbs$/i.test source
#    targetExt = '.html'
#  else if /\.less$/i.test source
#    targetExt = '.css'
#  else if /\.coffee$/i.test source
#    targetExt = '.js'
#
#  return target if not targetExt
#  _utils.replaceExt target, targetExt

#处理文件夹
arrangeDirectory = (source, target, cb)->
  files = _fs.readdirSync source
  index = 0
  _async.whilst(
    -> index < files.length
    ((done)->
      filename = files[index++]
      newSource = _path.join source, filename
      arrangeObject newSource, done
    ),
    cb
  )

#处理单个文件
arrangeSingleFile = (source, target, cb)->
  queue = []
  #编译
  queue.push(
    (done)->
      data =
        source: source
        target: target
        type: _utils.detectFileType(source)
        pluginData: null

      _hookHost.triggerHook _hooks.build.willCompile, data, ()->
        relativeSource = _path.relative _utils.options.workbench, data.source
        options =
          pluginData: data.pluginData
          save: true
          target: target

        #从插件中查找编译器
        compilerName = _host.getCompilerWithExt(data.type) || data.type
        _compiler.execute compilerName, data.source, options, (err, content, newTarget)->
          #编译时出现错误直接中断
          if err
            console.log err
            return process.exit 1

          #如果编译器变更了target，则使用新的target
          target = newTarget || target
          #编译器没有处理，则复制文件
          if content is false
            console.log "Copy -> #{relativeSource}".green
            _fs.copySync source, target

          done null
  )

  #编译完成，响应hook
  queue.push(
    (done)->
      data =
        source: source
        target: target

      _hookHost.triggerHook _hooks.build.didCompile, data, done
  )

  _async.waterfall queue, (err)-> cb err

#处理一个对象，可能是文件或者文件夹
arrangeObject = (source, cb)->
  #相对路径用于识别是否需要跳过或者
  relativePath = _path.relative _utils.options.workbench, source
  ignore = pathIsIgnore(source, relativePath)

  if ignore
    console.log "Ignore -> #{relativePath || '/'}".blue if ignore
    return cb null

  stat = _fs.statSync source
  #根据规则，替换target的路径
  relativePath = replaceTargetWithConfig relativePath
  #对于文件类型，要考虑需要替换为编译后的扩展名
  #替换扩展名的事，交给编译器自己做
  #relativePath = replaceTargetExt relativePath if not stat.isDirectory()
  target = _path.join _outputRoot, relativePath

  copyOnly = false
  queue = []
  queue.push(
    (done)->
      data =
        stat: stat
        source: source
        ignore: _utils.simpleMatch _buildConfig.ignore, relativePath
        copy: _utils.simpleMatch _buildConfig.copy, relativePath
        relativePath: relativePath
        target: target

      _hookHost.triggerHook _hooks.build.willProcess, data, (err)->
        copyOnly = data.copy
        target = data.target
        console.log "Ignore -> #{data.relativePath || '/'}".blue if data.ignore
        done null, data.ignore
  )

  queue.push(
    (ignore, done)->
      return done null if ignore

      if copyOnly   #复制文件
        console.log "Copy -> #{relativePath}".green
        _utils.copyFile source, target, done
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
  _buildConfig = _utils.config?.build
  _outputRoot = output
  arrangeObject _utils.options.workbench, cb