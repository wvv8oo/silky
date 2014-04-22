_express = require 'express'
_http = require 'http'
_path = require 'path'
_app = _express()
_fs = require 'fs'
_router = require './router'
_common = require './common'

_router _app    #设置路由
_app.set 'port', 8000
_app.listen _app.get 'port'

console.log "please visit: http://127.0.0.1:#{_app.get 'port'}"