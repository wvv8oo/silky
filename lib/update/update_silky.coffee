_http = require 'http'
_utils = require '../utils'
_os = require 'os'
_request = require 'request'

exports.execute = (currentVersion)->
  params =
    version: _utils.options.version
    uuid: _utils.globalConfig.uuid
    os: _os.type()
    os_version: _os.release()

  options =
    timeout: 1000 * 5
    method: 'GET'
    json: true
    qs: params
    url: "http://upgrade.silky.wvv8oo.com/api/last_version"

  _request options, (err, res, body)->
    return if err or res.statusCode isnt 200

    latest = body.version
    if currentVersion isnt latest
      console.log '==========================================='
      console.log "===   Silky #{latest} is available".red
      console.log "===   npm install -g silky".green
      console.log '==========================================='