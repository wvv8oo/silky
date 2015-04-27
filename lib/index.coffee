require 'colors'
_proxy = require('json-proxy')
_ = require 'lodash'
_router = require './router'
_utils = require './utils'
_initialize = require './initialize'

#作为一个中间件提供服务
module.exports = (app, server, startServer)->
  #集成代理
  cfgProxy = _utils.config.proxy || {}
  cfgProxy.headers = _.extend cfgProxy.headers || {}, headers: 'X-Forwarded-User': 'Silky'
  app.use _proxy.initialize(proxy: cfgProxy)

  #监听路由
  _router(app)

  #启动服务，如果是第三方调用，则可能不需要启动服务器
  return if not startServer
  app.set 'port', _utils.options.port || _utils.config.port || 14422
  server.on 'error', (err) ->
    if err.code is 'EADDRINUSE'
      console.log "端口冲突，请使用其它端口".red
      return process.exit(1)

    console.log "Silky发生严重错误".red
    console.log err.message.red

  server.listen app.get('port')
  console.log "Port -> #{app.get('port')}"
  console.log "Workbench -> #{_utils.options.workbench}"
  console.log "Environment -> #{_utils.options.env}"
  console.log "Please visit http://localhost:#{app.get('port')}"

  ###
  #监听socket的事件
  io = require('socket.io').listen(server, log: false)
  io.sockets.on 'connection', (socket)->
    event = 'page:change'
    listener = ()-> socket.emit event, null
    #收到页面变更的事件后，通知客户端
    _utils.addListener event, listener

    socket.on 'disconnect', (socket)-> _utils.removeListener event, listener
  ###