module.exports = class Interactivity
    defaults:
        pan: true
        swipeDirection: 'horizontal'
        swipeVelocity: 0.3
        swipeThreshold: 10
        maxZoomScale: 3
        minZoomScale: 1
        keysPrev: [8, 33, 37, 38] # Backspace, page up, left arrow, up arrow.
        keysNext: [13, 32, 34, 39, 40] # Enter, space, page down, right arrow, down arrow.

    constructor: (@verso, options = {}) ->
        for key, value of @defaults
            @[key] = options[key] ? value

        @panning = false
        @zoomScale = 1
        @activePointers = []

        @bindEvents()

        return

    bindEvents: ->
        # Keyboard.
        @verso.el.addEventListener 'keyup', @keyup.bind(@), false

        # Pointers.
        @verso.el.addEventListener 'touchstart', @pointerStart.bind(@), false
        @verso.el.addEventListener 'touchmove', @pointerMove.bind(@), false
        @verso.el.addEventListener 'touchend', @pointerEnd.bind(@), false
        @verso.el.addEventListener 'touchcancel', @pointerEnd.bind(@), false

        return

    getTransform: (el) ->
        style = window.getComputedStyle el, null
        transform = style['transform']
        values = if transform isnt 'none' then transform.split('(')[1].split(')')[0].split(',') else null

        values

    zoom: (scale, x, y) ->
        pageEl = @verso.pages[@verso.pageIndex]
        scrollChild = pageEl.querySelector '.verso__scroll-child'

        if scrollChild?
            scrollChild.style.transform = "scale3d(#{scale}, #{scale}, 1)"

        @zoomScale = scale

        return

    keyup: (e) =>
        if e.keyCode in @keysPrev
            @verso.prev()
        else if e.keyCode in @keysNext
            @verso.next()

        return

    pointerStart: (e) ->
        e.preventDefault()

        pageEl = e.target

        while not pageEl.className.match(/\bverso__page\b/) and pageEl.parentNode?
            pageEl = pageEl.parentNode

        @panPageIndex = @verso.pages.indexOf pageEl
        @panCurrentTransform = @getTransform @verso.pages[@panPageIndex]


        @panning = true

        @startX = e.pageX

        @pointerMove e

        @verso.el.dataset.panning = true

        return

    pointerMove: (e) ->
        return if @panning is false

        e.preventDefault()

        prevEl = @verso.pages[@panPageIndex - 1]
        currEl = @verso.pages[@panPageIndex]
        nextEl = @verso.pages[@panPageIndex + 1]
        width = @verso.el.offsetWidth
        height = @verso.el.offsetHeight
        deltaX = e.pageX - @startX
        deltaY = e.deltaY
        matrixX = if @panCurrentTransform? then +@panCurrentTransform[4] else 0
        matrixY = if @panCurrentTransform? then +@panCurrentTransform[5] else 0
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

        console.log @panCurrentTransform, x.curr

        prevEl.style.transform = "translate3d(#{x.prev}px, #{y.prev}px, 0)" if prevEl?
        currEl.style.transform = "translate3d(#{x.curr}px, #{y.curr}px, 0)"
        nextEl.style.transform = "translate3d(#{x.next}px, #{y.next}px, 0)" if nextEl?

        return

    pointerEnd: (e) ->
        deltaX = e.pageX - @startX

        if @panning is true
            prevEl = @verso.pages[@panPageIndex - 1]
            currEl = @verso.pages[@panPageIndex]
            nextEl = @verso.pages[@panPageIndex + 1]

            @verso.el.dataset.panning = false

            prevEl.style.transform = '' if prevEl?
            currEl.style.transform = ''
            nextEl.style.transform = '' if nextEl?

        if @swipeDirection is 'horizontal'
            if deltaX <= -@swipeThreshold
                @verso.next()
            else if deltaX >= @swipeThreshold
                @verso.prev()
        else if @swipeDirection is 'vertical'
            return



        return
