###
    用于处理less
###
_common = require './../common'
_fs = require 'fs'
_path = require 'path'
_less = require 'less'
_data = require './../data'

#渲染指定的less
exports.render = (file, cb)->
    #css文件不处理
    if _path.extname(file) isnt '.less'
      callback null, _common.readFile(file)
      return
    #读取并转换less
    content = _fs.readFileSync file, 'utf-8'
    #选项
    options =
      paths: [
        _path.join(_common.options.workbench, 'css')
#        _path.dirname file
#        _path.join(_common.options.workbench, 'css', 'module')
      ]

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

