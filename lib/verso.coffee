Events = require './events'

module.exports = class Verso extends Events
    defaults:
        keysPrev: [8, 33, 37, 38]
        keysNext: [13, 32, 34, 39, 40]
        transition: 'horizontal-slide'
        swipeDirection: 'horizontal'
        swipeTolerance: 60

    constructor: (@el, options = {}) ->
        for key, value of @defaults
            @[key] = options[key] ? value

        @pages = @el.querySelectorAll '.verso__page'
        @el.dataset.transition = @transition

        return

    init: ->
        return
