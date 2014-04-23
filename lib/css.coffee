###
    用于处理less
###
_common = require './common'
_fs = require 'fs'
_path = require 'path'
_less = require 'less'
_data = require './data'

#初始化
exports.init = ()->
    #监控less的变化
    _common.watchAndTrigger _path.join(_common.root(), 'css'), /(less|css)$/i

#渲染指定的less
exports.render = (file, callback)->
    #读取并转换less
    content = _fs.readFileSync file, 'utf-8'
    #选项
    options =
        paths: [_path.join(_common.root(), 'css')]

    parser = new _less.Parser options
    #将全局配置中的less加入到content后面
    content += value for key, value of _data.whole.less

    #转换
    parser.parse content, (err, tree)-> callback err, (tree.toCSS() if not err)