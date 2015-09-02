#    Author: 易晓峰
#    E-mail: wvv8oo@gmail.com
#    Date: 8/27/15 9:40 AM
#    Description: 虚拟文件树，记录文件信息，对于代码文件，会读取文件的内容
#    abstract file tree
_fs = require 'fs-extra'
_async = require 'async'
_ = require 'lodash'
_path = require 'path'

_util = require '../utils'


#记录文件信息
TREE = {}

###
{
	"md5": {
		source: ""
		target: ""
		stat: ""
		children: {
			"md5": {

			}
		}
	}
}
###

#保存实体
saveEntity = (entity, cb)->
  #忽略的列表和文件夹，以及被合并的，都不处理
  return cb null if entity.ignore or entity.merge
  target = _path.join _util.options.output, entity.target
  source = _path.join _util.options.workbench, entity.source
  targetDir = _path.dirname source
  _fs.ensureDirSync targetDir

  #仅复制目标
  if entity.copy
    console.log "Copy File #{entity.source} -> #{entity.target}"
    _fs.copySync source, target
    return cb null

  #与入文件内容
  if entity.content
    console.log "Save File #{entity.source} -> #{entity.target}"
    _util.writeFile target, entity.content
    return cb null

  cb null

#保存多个实体(文件夹)
saveEntities = (entities, cb)->
  keys = _.keys entities

  index = 0
  _async.whilst(
    -> index < keys.length
    (done)->
      entity = entities[keys[index++]]
      saveEntity entity, done
    cb
  )

#清除现有数据
exports.clean = ()->
  TREE = {}

exports.tree = ()-> TREE

exports.entityKey = (source)-> _util.md5 source

#添加一个文件实体
exports.append = (entity)->
#  console.log "Scan -> #{entity.source}"
  key = exports.entityKey entity.source
  #根目录
  TREE[key] = entity
  entity

#保存文件
exports.save = (cb)-> saveEntities TREE, cb