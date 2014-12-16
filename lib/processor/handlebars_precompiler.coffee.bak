###
    根据规则对handlebars进行预编译
    可以扫描一个文件夹中的所有文件，预编译为一个文件
###
_fs = require 'fs'
_path = require 'path'
_handlebars = require 'handlebars'

scanTemplateFile = (dirs, cb)->
    #转换为array
    dirs = [dirs] if typeof dirs is 'string'

    for dir in dirs
        #如果parent是文件，则直接处理
        return cb dir if not _fs.statSync(dir).isDirectory()

        #处理文件
        _fs.readdirSync(dir).forEach (filename)->
            file = _path.join dir, filename
            return scanTemplateFile file, cb if _fs.statSync(file).isDirectory()
            cb file

#扫描指定文件夹下的handlebars进行编译
exports.precompile = (source, tplContent, filter = /\.hbs$/i)->
    data = {}
    #扫描所有的模板
    scanTemplateFile source, (file)->
        #只处理符合条件的文件名
        return if not filter.test(file)
        key = _path.relative source, file
        key = key.replace _path.extname(key), ''
        content = _fs.readFileSync file, 'utf-8'
        data[key] = _handlebars.precompile content

    return data if not tplContent

    #如果有提供模板，再根据模板渲染
    template = _handlebars.compile tplContent
    template data



