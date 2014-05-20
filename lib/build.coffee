###
    打包文件
###

_fs = require 'fs-extra'
_path = require 'path'
_mkdirp = require 'mkdirp'
_handlebars = require 'handlebars'
_common = require './common'
_data = require './data'
_template = require './template'
_css = require './css'
_async = require 'async'
_cheerio = require 'cheerio'
_script = require './script'
_uglify = require 'uglify-js'
_cleanCSS = require 'clean-css'

_config = require _path.join(SILKY.config)
require 'colors'

#循环所有文件
fetch = (parent, skip, callback)->
    _fs.readdirSync(parent).forEach (filename) ->
        file = _path.join parent, filename
        #检测是否跳过
        return if skip file
        #递归
        fetch(file, skip, callback)  if _fs.statSync(file).isDirectory()
        #回调
        callback file

#确保目录存在，如果不存在，则创建
directoryPromise = (file)->
    dir = _path.dirname(file)
    _mkdirp.sync dir if not _fs.existsSync dir

#清除目录
clearTarget = ()->
    #如果文件存在，则删除
    if _fs.existsSync SILKY.output
        _fs.removeSync SILKY.output
        console.log "构建目录已经存在，原目录已被删除。 [#{SILKY.output}]".yellow

#
scriptMinify = (content)->
    result = _uglify.minify content, fromString: true
    result.code

#编译js
scriptProcessor = (source, target, callback)->
    #读取文件
    content = _script.compile source

    saveFile target, scriptMinify(content)
    callback()

#编译less和输出CSS
cssProcessor = (source, target, callback)->
    _css.render source, (err, css)->
        if err
            console.log "CSS Error: #{source}".red
            console.log err.message.red
            process.exit(0)
        #判断是否要压缩
        css = new _cleanCSS().minify css if _config.build.compress.css

        saveFile target, css
        callback()

#输出HTML
htmlProcessor = (source, target, callback)->
    content
    #如果html，则直接读取
    if _path.extname(source) in ['.html', '.htm']
        content = _fs.readFileSync source, 'utf-8'
    else
        #交给template渲染
        content = _template.render _template.getTemplateKey(source)
    #检查是否需要压缩内联的script
    content = compressInternalJavascript content if _config.build.compress.internal
    saveFile target, content
    callback()

#调用cheerio，提取并压缩内联的js
compressInternalJavascript = (content)->
    $ = _cheerio.load content
    $('script').each ()->
        $this = $(this)
        return $this.attr('type') is 'html/tpl'
        minify = scriptMinify $this.html()
        $this.html minify

    $.html()


#根据config的配置复制文件到目标
copyFile = ()->
    _config.build.copy.forEach (item)->
        target = _path.join(SILKY.output, item)
        _fs.copySync _path.join(SILKY.workbench, item), target
        console.log "Copy [#{item}] to #{target}".green

#根据文件当前路径，来确定目标路径，并确保文件夹是否存在
getBuildTarget = (file)->
    target = file.replace SILKY.workbench, SILKY.output
    directoryPromise target
    target

#保存文件
saveFile = (file, content)->
    directoryPromise file
    _fs.outputFileSync file, content

#处理文件
fileHandler = (source, target, callback)->
    #确保文件夹存在
    directoryPromise source
    processor = null
    ext = null
    switch _path.extname source
        when '.html', '.hbs'
            processor = htmlProcessor
            ext = '.html'
        when '.less', '.css'
            processor = cssProcessor
            ext = '.css'
        when '.js', '.coffee'
            processor = scriptProcessor
            ext = '.js'

    #如果有使用处理器，则替换为新的扩展名
    target = _common.replaceExt target, ext if processor
    #输出日志
    shortSource = _path.relative SILKY.workbench, source
    shortTarget = _path.relative SILKY.output, target
    console.log "#{shortSource} -> #{shortTarget}".green
    #如果存在处理器，则交由处理器处理
    if processor
        processor source, target, callback
    else
        #复制文件，并回调
        _fs.copySync source, target
        callback()

#根据配置，编译文件
compileFile = (done)->
    queue = []  #待处理的文件列表
    for key, node of _config.build.compile
        source = _path.join SILKY.workbench, key
        #递归文件
        fetch source,
            #是否跳过
            (file)->
                node.ignore and node.ignore.test(file)
            #返回处理
            (file)->
                #获取相当workbench的路径
                relative = _path.relative source, file
                target = _path.join _path.resolve(SILKY.output, node.target || key), relative

                queue.push
                    source: file
                    target: target

    #处理queue中的文件，less不支持同步操作
    _async.mapSeries queue, (item, cb)->
        #跳过文件夹
        return cb() if _fs.statSync(item.source).isDirectory()
        fileHandler item.source, item.target, cb
    ,(err, result)->
        console.log 'done'
        done()

exports.execute = (done)->
    console.log "构建目录： #{SILKY.output}".green
    clearTarget()
    #复制数据
    copyFile()
    compileFile(done)
