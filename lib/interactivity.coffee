Hammer = require 'hammerjs'

module.exports = class Interactivity
    defaults:
        pan: true
        swipeDirection: 'horizontal'
        swipeVelocity: 0.3
        swipeThreshold: 10
        keysPrev: [8, 33, 37, 38] # Backspace, page up, left arrow, up arrow.
        keysNext: [13, 32, 34, 39, 40] # Enter, space, page down, right arrow, down arrow.

    constructor: (@verso, options = {}) ->
        for key, value of @defaults
            @[key] = options[key] ? value

        @pinching = false
        @panning = false
        @scale = 1
        @panPageIndex = -1
        @panCurrentTransform = null

        @bindEvents()

        return

    bindEvents: ->
        # Keyboard.
        @verso.el.addEventListener 'keyup', @keyup.bind(@), false

        # Gestures.
        @hammer = new Hammer.Manager @verso.el
            .on 'doubletap', @doubletap.bind @
            .on 'pinchmove', @pinchmove.bind @
            .on 'pinchend', @pinchend.bind @
            .on 'panstart', @panstart.bind @
            .on 'panmove', @panmove.bind @
            .on 'panend', @panend.bind @
            .on 'pancancel', @panend.bind @

        @hammer.add new Hammer.Pinch()
        @hammer.add new Hammer.Pan(threshold: 0)
        @hammer.add new Hammer.Tap(event: 'doubletap', taps: 2)

        return

    getTransform: (el) ->
        style = window.getComputedStyle el, null
        transform = style['transform']
        values = if transform isnt 'none' then transform.split('(')[1].split(')')[0].split(',') else null

        values

    keyup: (e) =>
        if e.keyCode in @keysPrev
            @verso.prev()
        else if e.keyCode in @keysNext
            @verso.next()

        return

    doubletap: (e) ->
        console.log 'doubletap', e

        return

    pinchmove: (e) ->
        console.log 'pinchmove', e

        return

    pinchend: (e) ->
        console.log 'pinchend', e

        return

    panstart: (e) ->
        return if @pan is false or @scale isnt 1
        return if e.changedPointers[0].pageX <= 20 or e.changedPointers[0].pageX >= window.innerWidth - 20

        pageEl = e.target

        while not pageEl.className.match(/\bverso__page\b/) and pageEl.parentNode?
            pageEl = pageEl.parentNode

        @panPageIndex = @verso.pages.indexOf pageEl
        @panCurrentTransform = @getTransform pageEl

        @verso.el.dataset.panning = true
        @panning = true

        @panmove e

        return

    panmove: (e) ->
        return if @panning is false

        prevEl = @verso.pages[@panPageIndex - 1]
        currEl = @verso.pages[@panPageIndex]
        nextEl = @verso.pages[@panPageIndex + 1]
        width = @verso.el.offsetWidth
        height = @verso.el.offsetHeight
        deltaX = e.deltaX
        deltaY = e.deltaY
        matrixX = if @transform? then +@transform[4] else 0
        matrixY = if @transform? then +@transform[5] else 0
        x =
            prev: 0
            curr: 0
            next: 0
        y =
            prev: 0
            curr: 0
            next: 0

        if @swipeDirection is 'horizontal'
            x.prev = -width + matrixX + deltaX
            x.curr = matrixX + deltaX
            x.next = width + matrixX + deltaX
        else if @swipeDirection is 'vertical'
            y.prev = -height + matrixY + deltaY
            y.curr = matrixY + deltaY
            y.next = height + matrixY + deltaY

        prevEl.style.transform = "translate3d(#{x.prev}px, #{y.prev}px, 0)" if prevEl?
        currEl.style.transform = "translate3d(#{x.curr}px, #{y.curr}px, 0)"
        nextEl.style.transform = "translate3d(#{x.next}px, #{y.next}px, 0)" if nextEl?

        return

    panend: (e) ->
        if @panning is true
            prevEl = @verso.pages[@panPageIndex - 1]
            currEl = @verso.pages[@panPageIndex]
            nextEl = @verso.pages[@panPageIndex + 1]

            @verso.el.dataset.panning = false

            prevEl.style.transform = '' if prevEl?
            currEl.style.transform = ''
            nextEl.style.transform = '' if nextEl?

        if @swipeDirection is 'horizontal' and Math.abs(e.overallVelocityX) >= @swipeVelocity
            if Math.abs(e.deltaX) >= @swipeThreshold
                if e.offsetDirection is Hammer.DIRECTION_LEFT
                    @verso.next()
                else if e.offsetDirection is Hammer.DIRECTION_RIGHT
                    @verso.prev()
        else if @swipeDirection is 'vertical' and Math.abs(e.overallVelocityY) >= @swipeVelocity
            if Math.abs(e.deltaY) >= @swipeThreshold
                if e.offsetDirection is Hammer.DIRECTION_UP
                    @verso.next()
                else if e.offsetDirection is Hammer.DIRECTION_DOWN
                    @verso.prev()

        return
