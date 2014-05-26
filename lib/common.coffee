###
    全局配置
###
_events = require 'events'
_watch = require 'watch'
_fs = require 'fs'
_path = require 'path'
require 'colors'
_ = require 'underscore'

_pageEvent = new _events.EventEmitter()
_config = null      #配置，映射到.silky/config.js文件
_options = null     #用户传入的配置信息

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
deepWatch = exports.watch = (parent, pattern, cb)->
	_watch.watchTree parent, (f, curr, prev)->
		return if typeof f is "object" and not (prev and curr)

		#不适合监控规则的跳过
		return if not (pattern instanceof RegExp and pattern.test(f))
		event = 'change'

		if prev is null
			event = 'new'
		else if curr.nlink is 0
			event = 'delete'

		cb event, f

#初始化watch
initWatch = ()->
    #监控配置文件中的文件变化
    deepWatch _path.join(_options.workbench, _options.identity, _options.env)

    #监控文件
    for key, pattern of _config.watch
        dir = _path.join(_options.workbench, key)

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

#判断是否为产品环境
exports.isProduction = ()-> _options.env is 'production'

#如果是产品环境，则报错，否则返回字符
exports.combError = (error)->
    #如果是产品环境，则直接抛出错误退出
    if this.isProduction()
        console.log 'Error:'.red
        console.log error
        process.exit 1
        return

    error

#替换扩展名为指定的扩展名
exports.replaceExt = (file, ext)->
    #取文件夹再加上扩展名，不能使用path.join
    file.replace _path.extname(file), ext

#读取文件
exports.readFile = (file)-> _fs.readFileSync file, 'utf-8'

#初始化
exports.init = (options)->
    _options =
        env: 'development'
        workbench: null
        buildMode: false

    _.extend _options, options
    _options.version = require('../package.json').version
    _options.identity = '.silky'

    #如果在workbench中没有找到.silky的文件夹，则将目录置为silky的samples目录
    if not _options.workbench or not _fs.existsSync _path.join(_options.workbench, _options.identity)
        _options.workbench = _path.join __dirname, '..', 'samples'

    #配置文件
    configFile = _path.join _options.workbench, _options.identity, 'config.js'
    _config = require configFile

    exports.config = _config
    exports.options = _options

    initWatch()

#输入当前正在操作的文件
exports.fileLog = (file, log)->
    file = _path.relative _options.workbench, file
    #console.log "#{log || " "}>#{file}"

#替换掉slash，所有奇怪的字符
exports.replaceSlash = (file)->
    file.replace(/\W/ig, "_")

