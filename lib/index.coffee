_express = require 'express'
_http = require 'http'
_path = require 'path'
_app = _express()
_server = require('http').createServer _app
_io = require('socket.io').listen(_server)

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


_server.listen  _app.get('port')

#监听socket的事件
_io.sockets.on 'connection', (socket)->
    event = 'page:change'
    #收到页面变更的事件后，通知客户端
    _common.addListener event, ()->
        socket.emit event, null


console.log "please visit: http://127.0.0.1:#{_app.get 'port'}"