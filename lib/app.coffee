_express = require 'express'
_http = require 'http'
_app = _express()
_server = require('http').createServer _app
_path = require 'path'
_fs = require 'fs'
_silky = require './index'
_common = require './common'

options =
    workbench: process.env.WORKBENCH || global.SILKY?.WORKBENCH
    env: process.env.NODE_ENV || global.SILKY?.NODE_ENV
    port: process.env.PORT || global.SILKY?.PORT

_silky(_app, _server, options)
_app.set 'port', _common.options.port || _common.config.port || 14422
_server.listen _app.get('port')

console.log "监听端口 #{_app.get('port')}"
console.log "工作目录 #{_common.options.workbench}"
console.log "工作环境 #{_common.options.env}"