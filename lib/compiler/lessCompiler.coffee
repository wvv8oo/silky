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

  #读取并转换less
  content = _fs.readFileSync source, 'utf-8'
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
      #需要直接保存到文件中
      if options.save and options.target
        target = _utils.replaceExt options.target, 'css'
        _utils.writeFile target, cssContent

      cb err, cssContent
    catch e
      console.log "CSS Error: #{source}".red
      console.log err
      cb e