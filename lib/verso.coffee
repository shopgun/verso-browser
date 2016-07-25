Hammer = require 'hammerjs'

module.exports = class Verso
    defaults:
        keysPrev: [8, 33, 37, 38]
        keysNext: [13, 32, 34, 39, 40]
        swipeDirection: 'horizontal'
        swipeTolerance: 60

    constructor: (@pages = [], options = {}) ->
        for key, value of @defaults
            @[key] = options[key] ? value

        return

    render: ->
        @
