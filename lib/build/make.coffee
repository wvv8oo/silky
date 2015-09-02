_async = require 'async'
_path = require 'path'
_fs = require 'fs-extra'

_hooks = require '../plugin/hooks'
_hookHost = require '../plugin/host'
_utils = require '../utils'
_compiler = require '../compiler'
_host = require '../plugin/host'
_uniqueKey = require '../unique_key'
_aft = require './aft'
_compress = require './compress'

_buildConfig = null

##根据build的规则，判断是否要忽略
#pathIsIgnore = (source, relativePath)->
#  ignore = false
#  #跳过build的目录
#  return true if _outputRoot is source
#  #跳过.silky这个目录
#  return true if _utils.options.identity is relativePath
#
#  rules = _utils.config.build.ignore || []
#  for rule in rules
#    ignore = if typeof rule is 'string'
#        rule is relativePath
#      else
#        rule.test(relativePath)
#
#    break if ignore
#  ignore

#根据配置，替换目标路径
replaceTargetWithConfig = (relativePath)->
  for item in _buildConfig.rename || []
    if item.source.test relativePath
      relativePath = relativePath.replace item.source, item.target
      break if not item.next

  relativePath

#根据扩展名判断文件是否为非编译型源代码，一般是纯css/html/js这类，silky也会将这些文件读入到内存
fileIsReadable = (file)->
  #匹配源代码的扩展名
  rules = _utils.xPathMapValue('readable', _utils.config)
  rules = rules || /\.(js|css|html|htm)$/i
  rules.test file

#替换掉目标的扩展名，内置的几种处理方式
#replaceTargetExt = (relativePath)->
#  maps = coffee: 'js', hbs: 'html', less: 'css'
#  relativePath.replace /\.(coffee|hbs|less)$/i, (full, ext)-> ".#{maps[ext] || ext}"

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
makeDirectory = (entity, cb)->
  source = _path.join _utils.options.workbench, entity.source
  files = _fs.readdirSync source
  index = 0

  _async.whilst(
    -> index < files.length
    ((done)->
      filename = files[index++]
      makeEntity _path.join(source, filename), done
    ),
    cb
  )

#处理单个文件
makeSingleFile = (entity, cb)->
  queue = []

  #文件的全路径
  fullSource = _path.join _utils.options.workbench, entity.source

  #触发hook
  queue.push(
    (done)->
      data =
        entity: entity
        pluginData: null

      _hookHost.triggerHook _hooks.build.willCompile, data, ()-> done null, data
  )

  #执行编译
  queue.push(
    (data, done)->
      options =
        pluginData: data.pluginData

      #根据扩展名从插件中查找编译器，如果插件没有捕获，则使用默认的编译器名称
      compilerName = _host.getCompilerWithExt(entity.extension) || entity.compiler

      _compiler.execute compilerName, fullSource, options, (err, content, fileType)->
        #编译时出现错误直接中断
        return console.log(err) and process.exit(1) if err

        #如果编译器指定了新的扩展名，则使用新的扩展名，并更改文件类型
        if fileType
          entity.target = _utils.replaceExt(entity.target, fileType)
          entity.type = fileType

        entity.content = content
        done err
  )

  #写入file map或者复制文件
  queue.push(
    (done)->
      #编译器没处理，且文件不可读（即非代码文件），强制复制
      compileFail = entity.content is false
      return done null if not compileFail

      #以下是编译失败的处理
      #可读文件一般是不编译的源代码文件
      if entity.readable
        entity.content = _utils.readFile fullSource
      else
        entity.copy = true

      done null
  )

  #处理uniqueKey
  queue.push(
    (done)->
      return done null if entity.copy or entity.ignore or entity.content is false
      entity.content = _uniqueKey.execute entity.content, entity.type
      done null
  )

  #编译完成，响应hook
  queue.push(
    (done)->
      _hookHost.triggerHook _hooks.build.didCompile, entity, done
  )

  _async.waterfall queue, (err)-> cb err


#处理一个实体对象，可能是文件或者文件夹
makeEntity = (source, cb)->
  #相对路径用于识别是否需要跳过或者
  relativeSource = _path.relative _utils.options.workbench, source
  #根据配置文件中rename的规则，替换target的路径
  relativeTarget = replaceTargetWithConfig relativeSource
  ext = _path.extname(relativeSource).replace('.', '')

  entity =
    #是否要被合并
    merge: false
    #扩展名
    extension: ext
    #源文件
    source: relativeSource
    #是否忽略
    ignore: _utils.simpleMatch(_buildConfig.ignore, relativeSource)
    #文件的stat信息
    stat: _fs.statSync source
    #保存的目标
    target: relativeTarget
    #是否复制
    copy: _utils.simpleMatch(_buildConfig.copy, relativeSource)
    #编译器类型
    compiler: _compiler.detectCompiler(ext, relativeSource) || ext
    #是否压缩
    compress: _compress.needCompress relativeSource

  isDir = entity.stat.isDirectory()
  #探测文件类型
  entity.type = if isDir then 'directory' else _utils.detectFileType(entity.source)
  #允许读取文件内容至缓存
  entity.readable = not isDir and fileIsReadable(relativeSource)

  _aft.append entity

  queue = []
  #触发hook
  queue.push(
    (done)->
      _hookHost.triggerHook _hooks.build.willProcess, entity, (err)-> done err
  )

  #处理文件
  queue.push(
    (done)->
      #复制或者忽略，直接跳过
      if entity.ignore or entity.copy
        done null
      else if entity.type is 'directory'   #处理目录
        makeDirectory entity, done
      else    #处理单个文件
        makeSingleFile entity, done
  )

  #处理目录后的hook
  queue.push(
    (done)->
      _hookHost.triggerHook _hooks.build.didProcess, null, done
  )

  _async.waterfall queue, (err)-> cb null

#对外的入口
exports.execute = (output, cb)->
  #清除映射，以便写入新的映射
  _aft.clean()
  _buildConfig = _utils.config?.build
  makeEntity _utils.options.workbench, cb