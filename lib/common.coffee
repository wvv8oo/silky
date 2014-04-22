###
    全局配置
###
_events = require 'events'
_fs = require 'fs'
_path = require 'path'
_root = null
_configDir = '.silky'

exports.root = ()->
    return _root if _root

    #在当前目录下查找.silky文件，如果找不到则将主目录切换为系统安装目录
    root = process.cwd()
    root = _path.join(__dirname, '../', 'samples') if not _fs.existsSync(_path.join(root, _configDir))
    root

#配置文件的目录
exports.configDir = ()->
    _path.join exports.root(), _configDir

#触发事件
exports.trigger = (name, arg...)->
    emitter = new events.EventEmitter()
    emitter.emit(name, arg)