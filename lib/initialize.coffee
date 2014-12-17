module.exports = (options)->
    require('./common').init(options)
    require('./data').init()
    require('./processor/template').init()
    require('./processor/handlebarHelpers').init()
