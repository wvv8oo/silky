###
    全局配置
###
_events = require 'events'
_deepWatch = require 'deep-watch'
_fs = require 'fs'
_path = require 'path'
_root = null
_configDir = '.silky'
_pageEvent = new _events.EventEmitter()

exports.root = ()->
    return _root if _root

    #在当前目录下查找.silky文件，如果找不到则将主目录切换为系统安装目录
    root = process.cwd()
    root = _path.join(__dirname, '../', 'samples') if not _fs.existsSync(_path.join(root, _configDir))
    root

#配置文件的目录
exports.configDir = ()->
    _path.join exports.root(), _configDir

#触发页面被改变事件
exports.onPageChanged = ()->
    exports.trigger 'page:change'

#触发事件
exports.trigger = (name, arg...)->
    _pageEvent.emit(name, arg)

#监听事件
exports.addListener = (name, callback)->
    _pageEvent.addListener name, callback

#监控文件夹，如果发生改变，就触发页面被改变的事件
exports.watchAndTrigger = (parent, pattern)->
    exports.watch parent, pattern, exports.onPageChanged


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