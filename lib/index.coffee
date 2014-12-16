require 'colors'
_proxy = require('json-proxy')
_ = require 'lodash'
_router = require './router'
_common = require './common'
_initialize = require './initialize'

#作为一个中间件提供服务
module.exports = (app, server, options)->
  #初始化项目
  _initialize options

  #集成代理
  cfgProxy = _common.config.proxy || {}
  cfgProxy.headers = _.extend cfgProxy.headers || {}, headers: 'X-Forwarded-User': 'Silky'
  app.use _proxy.initialize(proxy: cfgProxy)

  #监听路由
  _router(app)

  ###
  #监听socket的事件
  io = require('socket.io').listen(server, log: false)
  io.sockets.on 'connection', (socket)->
    event = 'page:change'
    listener = ()-> socket.emit event, null
    #收到页面变更的事件后，通知客户端
    _common.addListener event, listener

    socket.on 'disconnect', (socket)-> _common.removeListener event, listener
  ###