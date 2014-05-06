###
    处理js和coffee
###
_path = require 'path'
_common = require './common'
_coffee = require 'coffee-script'
_fs = require 'fs'

exports.compile = (file)->
    #如果是js文件，则直接返回
    return _common.readFile file if _path.extname(file) is '.js'

    #编译coffee
    file = _path.join _common.replaceExt file, '.coffee'
    #文件不存在
    return null if not _fs.existsSync file
    _coffee.compile _common.readFile(file), bare: true
