###
    用于处理less
###
_utils = require '../utils'
_fs = require 'fs'
_path = require 'path'
_less = require 'less'
_ = require 'lodash'

_data = require '../data'

#合并用户自定义的path
mergeLessPath = ()->
  workbench = _utils.options.workbench
  #默认路径
  paths = [
    '.'
    _path.join(workbench, 'css')
  ]

  #用户在config.js中的自定义路径
  customPaths = _utils.xPathMapValue('compiler.setting.less.paths', _utils.config)
  return paths if not customPaths

  _.map customPaths, (segment)->
    paths.push _path.resolve workbench, segment

  paths

#编译less
exports.compile = (source, options, cb)->
#  #css文件不处理
#  if _path.extname(source) isnt '.less'
#    return cb null, _utils.readFile(source)

  file = _utils.replaceExt source, 'less'
  return cb null, false if not _fs.existsSync file

  #读取并转换less
  content = _fs.readFileSync file, 'utf-8'
  #选项
  lessOptions =  paths: mergeLessPath()

  parser = new _less.Parser lessOptions
  #将全局配置中的less加入到content后面
  content += value for key, value of _data.whole.less

  #转换
  parser.parse content, (err, tree)->
    return cb err if err

    try
      cssContent = tree.toCSS(cleancss: false)
      fileType = 'css'
      cssContent = options.onCompiled cssContent, fileType if options.onCompiled

      #需要直接保存到文件中
      if options.save and options.target
        target = _utils.replaceExt options.target, fileType
        _utils.writeFile target, cssContent

      cb err, cssContent, target, 'css'
    catch e
      console.log "CSS Error: #{file}".red
      console.log err
      cb e