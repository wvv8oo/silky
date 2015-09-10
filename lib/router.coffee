_path = require 'path'
_fs = require 'fs'
_url = require 'url'
_handlebars = require 'handlebars'
_async = require 'async'
_mime = require 'mime'
_qs = require 'querystring'

_hookHost = require './plugin/host'
_hooks = require './plugin/hooks'
_utils = require './utils'
_compiler = require './compiler'
_uniqueKey = require './unique_key'
_executable = require './executable'
_response = require './response'

#获路由的物理路径
getRouteRealPath = (route)->
  #html且兼容旧版的template目录，则使用template的目录，新版本不需要template目录
  rootDir = if _utils.config.compatibleModel and route.type is 'html'
    _utils.getTemplateDir()
  else
    _utils.options.workbench

  #物理文件的路径
  _path.join rootDir, route.url

#处理用户自定义的路由
routeRewrite = (origin)->
  route =
    url: origin
    rule: null
    type: 'other'

  rules = _utils.config.routers || []
  for rule in rules
    continue if not rule.path.test(origin)
    route.url = origin.replace rule.path, rule.to
    route.rule = rule
    #强制指定的编译器
    route.compiler = rule.compiler
    break if not rule.next

  console.log "#{origin} -> #{route.url}".green if route.url isnt origin

  #根据url判断类型
  route.type = _utils.detectFileType(route.url, true)
  #探测出mime的类型
  route.mime = _mime.lookup(route.url)
  #如果没有指定编译器，则获取用户在配置文件中指定的编译器
  route.compiler = route.compiler || _compiler.getCompilerWithRule(route.url, true)
  #获取真实的物理路径
  route.realpath = getRouteRealPath route
  route

#初始化常规路由
initNormalRoute = (app)->
 #匹配所有，Silky不响应非GET请求，但可以交给插件实现其它功能
  app.all "*", (req, res, next)->
    url = _url.parse(req.url)
    qs = _qs.parse url.query
    route = routeRewrite url.pathname

    #遇到可执行的路由
    return _executable route, url, req, res, next if route?.rule?.executable

    #如果querystring中已经指定编译器，则使用指定的编译器
    route.compiler = qs.compiler || route.compiler

    #强制指定为目录
    isDir = Boolean(req.query.direcotry)

    data =
      request: req
      response: res
      next: next
      stop: false
      route: route
      pluginData: null
      method: req.method

    #路由处理前的hook
    _hookHost.triggerHook _hooks.route.didRequest, data, (err)->
      #阻止路由的响应
      return next() if data.stop
      #Silky本身不响应非GET的请求
      return next() if not /get/i.test data.method

      realpath = data.route.realpath
      #响应目录
      return _response.responseDirectory(realpath, req, res, next) if isDir or data.route.type is 'directory'

      #非silky项目强制返回静态文件，规则要求直接返回静态文件
      if not _utils.isSilkyProject() or data.route.rule?.static
        _response.responseStatic(realpath, req, res, next)
      else
        #响应其它内容
        _response.responseNormal data.route, data.pluginData, req, res, next

module.exports = (app)->
  #处理silky的文件引用
  app.get "/__/:file", (req, res, next)->
    file = _path.join(__dirname, 'client', req.params.file)
    res.sendfile file

  #处理常规路由
  initNormalRoute app