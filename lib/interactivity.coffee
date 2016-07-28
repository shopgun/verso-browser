Hammer = require 'hammerjs'

module.exports = class Interactivity
    defaults:
        swipeDirection: 'horizontal'
        keysPrev: [8, 33, 37, 38] # Backspace, page up, left arrow, up arrow.
        keysNext: [13, 32, 34, 39, 40] # Enter, space, page down, right arrow, down arrow.

    constructor: (@verso, options = {}) ->
        for key, value of @defaults
            @[key] = options[key] ? value

        @bindKeys()

        return

    bindKeys: ->
        @verso.el.addEventListener 'keyup', (e) =>
            if e.keyCode in @keysPrev
                @verso.prev()
            else if e.keyCode in @keysNext
                @verso.next()

            return

        return
