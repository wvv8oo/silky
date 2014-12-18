_https = require 'https'

exports.execute = (currentVersion)->
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

  req = _https.get options, (res)->
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