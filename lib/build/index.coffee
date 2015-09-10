###
  Author: wvv8oo
  Github: http://github.com/wvv8oo/silky
  npm: http://npmjs.org/
###

_fs = require 'fs-extra'
_path = require 'path'
_async = require 'async'
require 'colors'
_os = require 'os'

_utils = require '../utils'
_make = require './make'
_compress = require './compress'
_hooks = require '../plugin/hooks'
_hookHost = require '../plugin/host'
_aft = require './aft'

exports.execute = (cb)->
  queue = []

  output = _utils.options.output
  #触发将要build的事件
  queue.push(
    (done)->
      data = output: output

      _hookHost.triggerHook _hooks.build.willBuild, data, (err)->
        _utils.options.output = output = data.output
        done null
  )

  #清除目标文件夹
  queue.push(
    (done)->
      return done null if not _fs.existsSync output
      #强制清除目录
      _fs.removeSync output
      console.log "构建目录已经存在，原目录已被删除。 [#{output}]".yellow
      done null
  )

  #即将处理
  queue.push(
    (done)->
      #确定文件夹存在
      _fs.ensureDirSync output

      data = output: output
      _hookHost.triggerHook _hooks.build.willMake, data, (err)->
        done null
  )

  #复制及编译
  queue.push(
    (done)->
      _make.execute output, done
  )

  #处理完成
  queue.push(
    (done)->
      entities = _aft.tree()

      _hookHost.triggerHook  _hooks.build.didMake, entities, (err)->
        done null
  )

  #压缩代码
  queue.push(
    (done)->
      _compress.execute done
  )

  #保存
  queue.push(
    (done)-> _aft.save done
  )

  queue.push(
    (done)->
      data = output: output
      _hookHost.triggerHook _hooks.build.didBuild, data, (err)-> done null
  )

  #添加日志文件
  queue.push(
    (done)->
      logContent = "
        Time: #{new Date().toString()}\n
        Hostname: #{_os.hostname()}\n
        OS: #{_os.type()}\n
        OS Version: #{_os.release()}\n
        UUID: #{_utils.globalConfig.uuid}\n
        Version: #{_utils.options.version}\n\n

        Options:\n
        #{JSON.stringify(_utils.options)}
      "

      file = _path.join output, 'build.log'
      _utils.writeFile file, logContent
      done null
  )

  _async.waterfall queue, cb