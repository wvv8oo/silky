_moment = require 'moment'
_ = require 'lodash'

_utils = require './utils'

#获取缓存的唯一键
exports.getUniqueKey = ()->
  uniqueKey = _utils.config.uniqueKey
  return "" if not uniqueKey
  uniqueKey = '{md5}' if uniqueKey is true
  uniqueKey = uniqueKey.replace /\{(.+)\}/g, (segment, value)->
    switch value
      when 'md5' then _utils.md5(new Date().toString()).substr(0, 10)
      when 'date' then _moment().format('YYYYMMDD')
      when 'datetime' then _moment().format('YYYYMMDDHHmmss')
      else ''

  uniqueKey = "?#{uniqueKey}" if uniqueKey.substr(0, 1) isnt '?'
  uniqueKey

#替换
replaceUniqueKey = (content, rule, uniqueKey)->
  content = content.replace(rule.firstExpr, (line, match)->
    match += uniqueKey
    line = line.replace rule.secondExpr, ->
      rule.replaceTo.replace '{0}', match
    line
  )
  content

#css的缓存键
cssUniqueKey = (content, uniqueKey)->
  uniqueKey = uniqueKey || exports.getUniqueKey()
  content.replace(/url\(['"]?(.+?)['"]?\)/g, (all, match)->
    match += uniqueKey
    return "url('#{match}')"
  )


#html中的缓存键img/link/script
htmlUniqueKey  = (content, uniqueKey)->
  uniqueKey = uniqueKey || exports.getUniqueKey()

  rules = [
    {
      firstExpr: /<link.+href=['"](.+?)['"].*>/g,
      secondExpr: /href=['"](.+?)['"]/i,
      replaceTo: "href='{0}'"
    },{
      firstExpr: /<script.+src=['"](.+?)['"].*>/g,
      secondExpr: /src=['"](.+?)['"]/i,
      replaceTo: "src='{0}'"
    },{
      firstExpr: /<img.+src=['"](.+?)['"].*>/g,
      secondExpr: /src=['"](.+?)['"]/i,
      replaceTo: "src='{0}'"
    }
  ]

  _.map rules, (rule)-> content = replaceUniqueKey content, rule, uniqueKey
  content

#添加uniqueKey
exports.execute = (content, type, uniqueKey)->
  switch type
    when 'css' then cssUniqueKey(content, uniqueKey)
    when 'html' then htmlUniqueKey(content, uniqueKey)
    else content