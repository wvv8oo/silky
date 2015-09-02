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
exports.compile = (source, relativeSource, options, cb)->
  fileType = 'css'
  return cb null, false if not _fs.existsSync source

  content = _utils.readFile source
  #不处理非less的文件
  return cb null, content, fileType if /\.css$/i.test source

  console.log "Compile #{relativeSource} by less compiler"
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
      cb err, cssContent, fileType
    catch e
      console.log "CSS Error: #{file}".red
      console.log err
      cb e, false