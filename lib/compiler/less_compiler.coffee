###
    用于处理less
###
_utils = require '../utils'
_fs = require 'fs'
_path = require 'path'
_ = require 'lodash'
_less = null

_compilerMgr = require './compiler_manager'
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

#处理less
lessHandler = (content, options, cb)->
  _less = require 'less' if not _less
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
      cb err, cssContent
    catch e
      console.log "CSS Error: #{file}".red
      console.log err
      cb e, false

module.exports = _compilerMgr.registerCompiler('less', 'less', 'css', lessHandler)