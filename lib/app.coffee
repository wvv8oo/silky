_express = require 'express'
_app = _express()
_server = require('http').createServer _app
_silky = require './index'
_initialize = require '../lib/initialize'

options =
    workbench: process.env.WORKBENCH || global.SILKY?.WORKBENCH
    env: process.env.NODE_ENV || global.SILKY?.NODE_ENV
    language: process.env.LANG || global.SILKY?.LANG
    port: process.env.PORT || global.SILKY?.PORT
    debug: process.env.DEBUG || global.SILKY?.DEBUG

_initialize(options)
_silky(_app, _server)

#_app.set 'port', _common.options.port || _common.config.port || 14422
#
#_server.on 'error', (err) ->
#  if err.code is 'EADDRINUSE'
#    console.log "端口冲突，请使用其它端口".red
#    return process.exit(1)
#
#  console.log "Silky发生严重错误".red
#  console.log err.message.red
#
#_server.listen _app.get('port')
#
#console.log "Port -> #{_app.get('port')}"
#console.log "Workbench -> #{_common.options.workbench}"
#console.log "Environment -> #{_common.options.env}"
#console.log "Please visit http://localhost:#{_app.get('port')}"