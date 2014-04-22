_express = require 'express'
_http = require 'http'
_path = require 'path'
_app = _express()
_fs = require 'fs'
_router = require './router'
_common = require './common'
_data = require './data'
_template = require './template'
_config = require _path.join _common.configDir(), 'config.js'

#初始化数据及路由
_data.init()
_template.init()

_router _app    #设置路由
_app.set 'port', _config.port || 14422
_app.listen _app.get 'port'

_common.addListener 'page:change', ()->
    console.log('abc')

console.log "please visit: http://127.0.0.1:#{_app.get 'port'}"