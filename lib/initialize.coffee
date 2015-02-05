module.exports = (options)->
    require('./common').init(options)
    require('./data').init()
    require('./compiler/template').init()
    require('./compiler/handlebarHelpers').init()
