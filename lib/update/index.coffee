_updateConfig = require './update_config'
_https = require 'https'

#检查配置文件的升级
exports.checkConfig = ()->
  _updateConfig.execute()

#检查主程序是否需要升级
exports.checkSilky = (currentVersion)->
  options =
    method: 'GET'
    host: 'registry.npmjs.org'
    port: 443
    path: "/silky"
    headers:
      accept: '*/*'
      agent: false
      contentType: "charset=utf-8",
      connection: 'keep-alive'
      'Content-Type': 'application/json;charset=utf-8'

  req = _https.request options, (res)->
    responseData = ''
    res.on 'data', (chunk)-> responseData += chunk
    res.on 'end', ->
      result = String(responseData)
      return if res.statusCode isnt 200

      data = JSON.parse(result)
      latest = data['dist-tags'].latest

      if currentVersion isnt latest
        console.log '==========================================='
        console.log "===   Silky #{latest} is available".red
        console.log "===   npm install -g silky".green
        console.log '==========================================='
  req.end()