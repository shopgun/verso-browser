Hammer = require 'hammerjs'

module.exports = class Interactivity
    defaults:
        swipeDirection: 'horizontal'
        swipeVelocity: 0.3
        swipeThreshold: 10
        keysPrev: [8, 33, 37, 38] # Backspace, page up, left arrow, up arrow.
        keysNext: [13, 32, 34, 39, 40] # Enter, space, page down, right arrow, down arrow.

    constructor: (@verso, options = {}) ->
        for key, value of @defaults
            @[key] = options[key] ? value

        @gestures =
            scale: 1
            initialX: 0

        @bindEvents()

        return

    bindEvents: ->
        # Keyboard.
        @verso.el.addEventListener 'keyup', @keyup.bind(@), false

        # Gestures.
        @hammer = new Hammer.Manager @verso.el
            .on 'doubletap', @doubletap.bind @
            .on 'pinchstart', @pinchstart.bind @
            .on 'pinchmove', @pinchmove.bind @
            .on 'pinchend', @pinchend.bind @
            .on 'panstart', @panstart.bind @
            .on 'panmove', @panmove.bind @
            .on 'panend', @panend.bind @

        @hammer.add new Hammer.Pinch()
        @hammer.add new Hammer.Pan()
        @hammer.add new Hammer.Tap(event: 'doubletap', taps: 2)
        @hammer.add new Hammer.Tap(event: 'singletap')

        @hammer.get('doubletap').recognizeWith 'singletap'
        @hammer.get('singletap').requireFailure 'doubletap'

        return

    keyup: (e) =>
        if e.keyCode in @keysPrev
            @verso.prev()
        else if e.keyCode in @keysNext
            @verso.next()

        return

    doubletap: (e) ->
        console.log 'doubletap', e

        return

    pinchstart: (e) ->
        console.log 'pinchstart', e

        return

    pinchmove: (e) ->
        console.log 'pinchmove', e

        return

    pinchend: (e) ->
        console.log 'pinchend', e

        return

    panstart: (e) ->
        console.log 'panstart', e

        return

    panmove: (e) ->
        console.log 'panmove', e

        return

    panend: (e) ->
        console.log 'panend', e

        #return if @gestures.scale isnt 1 or e.pointerType is 'mouse'

        if @swipeDirection is 'horizontal' and Math.abs(e.overallVelocityX) >= @swipeVelocity
            if Math.abs(e.deltaX) >= @swipeThreshold
                if e.direction is Hammer.DIRECTION_LEFT
                    @verso.next()
                else if e.direction is Hammer.DIRECTION_RIGHT
                    @verso.prev()
        else if @swipeDirection is 'vertical' and Math.abs(e.overallVelocityY) >= @swipeVelocity
            if Math.abs(e.deltaY) >= @swipeThreshold
                if e.direction is Hammer.DIRECTION_UP
                    @verso.next()
                else if e.direction is Hammer.DIRECTION_DOWN
                    @verso.prev()

        return
