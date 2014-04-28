#用于非command条件下启动silky web server，用于node-dev调试
_path = require 'path'
_fs = require 'fs'

workbench = _path.join(__dirname, '..', 'samples')
identity = '.silky'
global.SILKY =
    #识别为silky目录
    identity: identity
    #工作环境
    env: 'development'
    #端口
    port: 14422
    #工作目录
    workbench: workbench
    #配置文件
    config: _path.join workbench, identity, 'config.js'

#引入配置文件
global.SILKY.data = _path.join(workbench, identity, SILKY.env)

require('./common').init()
#初始化数据及路由
require('./data').init()
require('./template').init()
require './index'