require 'colors'
require 'shelljs/global'

#需要初始化helper
require './compiler/handlebars/helper'

module.exports = (options)->
    require('./utils').init(options)
    require('./data').init()
#    require('./compiler/template').init()
#    require('./compiler/handlebarHelpers').init()
