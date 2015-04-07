###
    用于处理less
###
_common = require '../common'
_fs = require 'fs'
_path = require 'path'
_less = require 'less'
_ = require 'lodash'

_data = require '../data'

#合并用户自定义的path
mergeLessPath = ()->
  workbench = _common.options.workbench
  #默认路径
  paths = [
    '.'
    _path.join(workbench, 'css')
  ]

  #用户在config.js中的自定义路径
  customPaths = _common.xPathMapValue('compiler.less.paths', _common.config)
  return paths if not customPaths

  _.map customPaths, (segment)->
    paths.push _path.resolve workbench, segment

  paths

#渲染指定的less
exports.render = (file, cb)->
  #css文件不处理
  if _path.extname(file) isnt '.less'
    cb null, _common.readFile(file)
    return

  #读取并转换less
  content = _fs.readFileSync file, 'utf-8'
  #选项
  options =  paths: mergeLessPath()

  parser = new _less.Parser options
  #将全局配置中的less加入到content后面
  content += value for key, value of _data.whole.less

  #转换
  parser.parse content, (err, tree)->
    return cb err if err
    try
      cssContent = tree.toCSS(cleancss: false)
      cb err, cssContent
    catch e
      cb e