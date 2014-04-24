###
    全局配置
###
_events = require 'events'
_deepWatch = require 'deep-watch'
_fs = require 'fs'
_path = require 'path'
_pageEvent = new _events.EventEmitter()
_config = null

###
#配置文件的目录
exports.configDir = ()->
    _path.join exports.root(), _configDir
###

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
deepWatch = exports.watch = (parent, pattern, callback)->
    dw = new _deepWatch parent, (event, file)->
        #console.log file, pattern, file, event
        #console.log (not pattern or ((typeof pattern is 'object') && not pattern.test(file)))
        #return if not pattern or ((typeof pattern is 'object') && not pattern.test(file))

        #return callback(event, file) if event is 'change'

        if pattern instanceof RegExp and pattern.test(file)
            #rename有两种情况，删除或者新建，如果文件找不到了，则是删除
            event = if _fs.existsSync file then 'change' else 'delete'
            callback event, file

    dw.start()

    ###
    _fs.watch parent, (event, filename)->
        console.log(filename)
        callback(filename) if pattern.test(filename)
    ###

#判断是否为产品环境
exports.isProduction = ()-> SILKY.env is 'production'

#如果是产品环境，则报错，否则返回字符
exports.combError = (error)->
    #如果是产品环境，则直接抛出错误退出
    return console.log error.red and process.exit 1 if this.isProduction()
    error

#替换扩展名为指定的扩展名
exports.replaceExt = (file, ext)->
    #取文件夹再加上扩展名，不能使用path.join
    file.replace _path.extname(file), ext

#读取文件
exports.readFile = (file)->
    _fs.readFileSync file, 'utf-8'

exports.init = ()->
    _config = require SILKY.config

    #监控配置文件中的文件变化
    deepWatch _path.join(SILKY.workbench, SILKY.identity, SILKY.env)

    #监控文件
    for key, pattern of _config.watch
        dir = _path.join(SILKY.workbench, key)

        deepWatch dir, pattern, (event, file)->
            extname = _path.extname file
            triggerType = 'html'
            if extname in ['.less', '.css']
                triggerType = 'css'
            else if extname in ['.js', '.coffee']
                triggerType = 'js'

            _pageEvent.emit 'file:change:' + triggerType, event, file
            console.log "#{event} - #{file}".green
            #同时引发页面内容被改变的事件
            exports.onPageChanged()
