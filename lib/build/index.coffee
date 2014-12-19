###
  Author: wvv8oo
  Github: http://github.com/wvv8oo/silky
  npm: http://npmjs.org/
###

_fs = require 'fs-extra'
_path = require 'path'
_async = require 'async'
require 'colors'

_common = require '../common'
_make = require './make'
_compress = require './compress'
_hooks = require '../plugin/hooks'
_hookHost = require '../plugin/host'


exports.execute = (cb)->
  output = _common.options.output || _common.config.build.output || './build'
  output = _path.resolve _common.options.workbench, output

  queue = []

  #触发将要build的事件
  queue.push(
    (done)->
      data = output: output

      _hookHost.triggerHook _hooks.build.willBuild, data, (err)->
        output = data.output
        done null
  )

  #清除目标文件夹
  queue.push(
    (done)->
      return done null if not _fs.existsSync output
      _fs.removeSync output
      console.log "构建目录已经存在，原目录已被删除。 [#{output}]".yellow
      done null
  )

  #即将处理
  queue.push(
    (done)->
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
      data = output: output

      _hookHost.triggerHook  _hooks.build.didMake, data, (err)->
        done null
  )

  #压缩代码
  queue.push(
    (done)->
      _compress.execute output, done
  )

  queue.push(
    (done)->
      data = output: output
      _hookHost.triggerHook _hooks.build.didBuild, data, (err)-> done null
  )

  _async.waterfall queue, cb