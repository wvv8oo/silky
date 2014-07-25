module.exports = (options)->
    require('./common').init(options)
    require('./data').init()
    require('./template').init()
    require('./handlebarHelpers.coffee').init()
