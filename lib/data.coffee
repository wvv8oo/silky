###
    读取.silky下的json文件，用这个数据来渲染handlebars
###
_fs = require 'fs-extra'
_path = require 'path'
_common = require './common'
_ = require 'lodash'
_watch = require 'watch'

_data = {
  json: {},
  less: {},
  language: {}
}

#读取单个语言文件
readLanguageFile = (file)->
  extname = _path.extname(file)
  #目前只接受json的文件
  return if extname isnt '.json'

  key = getDataKey file
  _data.language[key] = _fs.readJSONSync(file, 'utf-8')

#读取语言文件
readLanguage = (dir)->
  return if not _fs.existsSync dir
  _fs.readdirSync(dir).forEach (filename)-> readLanguageFile _path.join(dir, filename)

#根据文件名获取key
getDataKey = (file)->
  _path.basename file, _path.extname(file)

#读取js文件，直接require
readScript = (normalFile, overrideFile)->
  #normal中不存在的不处理
  return if not _fs.existsSync normalFile
  delete require.cache[normalFile]

  normal = require normalFile
  #没有需要覆盖的文件
  return normal if not _fs.existsSync overrideFile
  delete require.cache[overrideFile]

  override = require overrideFile
  _.extend normal, override

#全并文件
combineFile = (filename)->
  #只处理json和less的文件
  extname = _path.extname(filename).replace('.', '')
  return false if extname not in ['json', 'less', 'js']

  key = getDataKey filename
  normaFile = _path.join _common.localSilkyIdentityDir(), 'data', 'normal', filename
  overrideFile = _path.join _common.localSilkyIdentityDir(), 'data', _common.options.env, filename

  #如果是js文件，直接引入
  if extname is 'js'
    content = readScript(normaFile, overrideFile)
    return _data.json[key] = content

  normalData = _common.readFile normaFile
  #取特殊环境将要覆盖的数据
  if _fs.existsSync overrideFile
    overrideData = _common.readFile overrideFile

  #将数据存入
  if extname is 'json'
    content = JSON.parse(normalData)
    _.extend content, JSON.parse(overrideData) if overrideData
  else
    content = normalData + (overrideData || '')

  _data[extname][key] = content


#入口
exports.init = ()->
  #读取normal的数据
  normalDir = _path.join _common.localSilkyIdentityDir(), 'data', 'normal'
  #目录不存在，不查读取数据
  return if not _fs.existsSync normalDir

  #循环读取所有数据到缓存中
  _fs.readdirSync(normalDir).forEach (filename)->
    combineFile filename

  #循环读取所有语言到数据中
  readLanguage _common.languageDirectory()

  #监控数据文件的变化
  watch()

#监控文件的改变
watch = ()->
  dataDir = _path.join _common.localSilkyIdentityDir(), 'data'
  #监控数据文件的变化
  _watch.watchTree dataDir, (f, curr, prev)->
#    if typeof f is "object" && prev is null && curr is null
#      console.log 'Finished walking the tree'
#    else if prev is null
#      console.log 'f is a new file'
#    else if curr.nlink is 0
#      console.log 'f was removed'
#    else
#      console.log 'f was changed'

    return if typeof f is "object" && prev is null && curr is null
    combineFile _path.basename(f)

  #监控语言文件的变化
  langDir = _common.languageDirectory()
  _fs.watch langDir, (event, filename)->
    file = _path.join langDir, filename
    readLanguageFile file

exports.whole = _data