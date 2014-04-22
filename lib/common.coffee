###
    全局配置
###
_events = require 'events'
_deepWatch = require 'deep-watch'
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

#监控文件
exports.watch = (parent, pattern, callback)->
    dw = new _deepWatch parent, (event, file)->
        return if not pattern.test(file)
        return callback(event, file) if event is 'change'

        #rename有两种情况，删除或者新建，如果文件找不到了，则是删除
        event = if _fs.existsSync file then 'create' else 'delete'
        callback event, file

    dw.start()

    ###
    _fs.watch parent, (event, filename)->
        console.log(filename)
        callback(filename) if pattern.test(filename)
    ###