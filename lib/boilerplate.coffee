#    Author: 易晓峰
#    E-mail: wvv8oo@gmail.com
#    Date: 4/1/15 3:33 PM
#    Description: 脚手架，用于搭建基础的项目
_async = require 'async'
_path = require 'path'
_fs = require 'fs-extra'

_utils = require './utils'

#从远程仓库中更新
updateFromRepos = (cb)->
  #远程仓库地址
  remoteRepos = _utils.xPathMapValue('custom.boilerplateRepository', _utils.globalConfig)
  remoteRepos = remoteRepos || 'https://github.com/wvv8oo/silky-boilerplate.git'

  localRepos = _utils.globalCacheDirectory('boilerplate')
  _utils.updateGitRepos remoteRepos, localRepos, (code)-> cb code, localRepos

#初始化插件项目
exports.initPlugin = ()->
  source = _path.join _utils.samplesDirectory 'plugin'
  _fs.copySync source, _utils.options.workbench

#如果有指定名称，则从远程仓库复制，如果没有指定，则从默认项目中复制
exports.initSample = (name, full, cb)->
  #默认的sample
  sampleSource = _utils.samplesDirectory('default')
  currentDirectory = _utils.options.workbench

  identityDir = _path.join currentDirectory, _utils.options.identity
  return cb new Error("当前文件夹已经是一个Silky项目") if _fs.existsSync identityDir

  queue = []

  #第一步，获取本地安装目录
  queue.push(
    (done)->
      return done null if not name

      #从git读取
      updateFromRepos (code, localRepos)->
        err = if code is 0 then null else new Error('更新Git数据失败')
        return done err if err

        sampleSource = _path.join localRepos, name
        #检查文件夹是否存在
        err = new Error("初始化失败，[#{name}]不存在") if not _fs.existsSync sampleSource
        done err
  )

  queue.push(
    (done)->
      if full
        _fs.copySync sampleSource, currentDirectory
        console.log "Silky项目初始化成功，示例项目已被创建".green
        return done null

      #只是复制.silky文件夹
      silkyDir = _path.join sampleSource, _utils.options.identity
      if not _fs.existsSync silkyDir
        err = new Error("[#{name}]不是一个合法的Silky项目")
        return done err

      _fs.copySync silkyDir, _path.join(currentDirectory, _utils.options.identity)
      console.log "Silky项目初始化成功".green
      done null
  )

  _async.waterfall queue, cb
