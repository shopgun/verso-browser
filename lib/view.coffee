Events = require './events'
Hammer = require 'hammerjs'
Pages = require './pages'
Page = require './page'

module.exports = class Verso extends Events
    defaults:
        pageIndex: 0
        maxZoomScale: 3
        minZoomScale: 1
        swipeDirection: 'horizontal'
        swipeVelocity: 0.3
        swipeThreshold: 10
        keysPrev: [8, 33, 37, 38] # Backspace, page up, left arrow, up arrow.
        keysNext: [13, 32, 34, 39, 40] # Enter, space, page down, right arrow, down arrow.

    constructor: (@el, options = {}) ->
        super()

        for key, value of @defaults
            @[key] = options[key] ? value

        @pages = new Pages @getPages()
        @pan =
            active: false
            pageIndex: null
        @pinch =
            active: false

        @hammer = new Hammer.Manager @el
        @hammer.add new Hammer.Pinch()
        @hammer.add new Hammer.Pan
            threshold: 0
            direction: do =>
                if @swipeDirection is 'horizontal'
                    Hammer.DIRECTION_HORIZONTAL
                else if @swipeDirection is 'vertical'
                    Hammer.DIRECTION_VERTICAL
                else
                    Hammer.DIRECTION_ALL
        @hammer.add new Hammer.Tap
            event: 'doubletap'
            taps: 2
        @hammer.on 'doubletap', @doubleTap.bind @
        @hammer.on 'panstart', @panStart.bind @
        @hammer.on 'panmove', @panMove.bind @
        @hammer.on 'panend', @panEnd.bind @
        @hammer.on 'pinchstart', @pinchStart.bind @
        @hammer.on 'pinchmove', @pinchMove.bind @
        @hammer.on 'pinchend', @pinchEnd.bind @

        @updateState()
        @pages.at(@pageIndex).show()

        @el.addEventListener 'keyup', @keyUp.bind(@), false
        @el.setAttribute 'tabindex', -1
        @el.focus()

        return

    go: (pageIndex) ->
        return if isNaN(pageIndex) or pageIndex < 0 or pageIndex > @pages.count() - 1 or pageIndex is @pageIndex

        from = @pageIndex
        to = pageIndex

        @trigger 'beforeChange', from, to

        @pageIndex = to
        @updateState()
        @pages.transition from, to

        @trigger 'change', from, to

        return

    prev: ->
        @go @pageIndex - 1

        return

    next: ->
        @go @pageIndex + 1

        return

    updateState: ->
        @pages.at(@pageIndex).el.dataset.state = 'current'
        @pages.at(@pageIndex).el.setAttribute 'aria-hidden', false

        if @pageIndex > 0
            @pages.at(@pageIndex - 1).el.dataset.state = 'previous'
            @pages.at(@pageIndex - 1).el.setAttribute 'aria-hidden', true

        if @pageIndex + 1 < @pages.count()
            @pages.at(@pageIndex + 1).el.dataset.state = 'next'
            @pages.at(@pageIndex + 1).el.setAttribute 'aria-hidden', true

        if @pageIndex > 1
            @pages.slice(0, @pageIndex - 1).forEach (page) ->
                page.el.dataset.state = 'before'
                page.el.setAttribute 'aria-hidden', true

                return

        if @pageIndex + 2 < @pages.count()
            @pages.slice(@pageIndex + 2).forEach (page) ->
                page.el.dataset.state = 'after'
                page.el.setAttribute 'aria-hidden', true

                return

        return

    getPages: ->
        pages = []
        els = @el.querySelectorAll '.verso__page'

        for el, i in els
            position = 0

            if i < @pageIndex
                position = -100
            else if i > @pageIndex
                position = 100

            pages.push new Page(el, i, position)

        pages

    keyUp: (e) ->
        if e.keyCode in @keysPrev
            @prev()
        else if e.keyCode in @keysNext
            @next()

        return

    doubletap: (e) ->
        console.log 'doubletap', e

        return

    panStart: (e) ->
        e.preventDefault()

        return if e.changedPointers[0].pageX <= 20 or e.changedPointers[0].pageX >= window.innerWidth - 20

        pageEl = e.target
        pageIndex = null

        while pageEl.parentNode? and not pageEl.className.match(/\bverso__page\b/)
            pageEl = pageEl.parentNode

        pageIndex = +pageEl.dataset.versoindex

        if pageIndex?
            @pan.active = true
            @pan.pageIndex = pageIndex

            @pages.pause()

        return

    panMove: (e) ->
        e.preventDefault()

        return if @pan.active isnt true

        prevPage = @pages.at @pan.pageIndex - 1
        currPage = @pages.at @pan.pageIndex
        nextPage = @pages.at @pan.pageIndex + 1
        delta = if @swipeDirection is 'horizontal' then e.deltaX else e.deltaY
        delta = delta / @el.offsetWidth * 100

        currPage.updateTransform currPage.position + delta

        if prevPage?
            prevPage.updateTransform currPage.transformPosition - 100
            prevPage.show()
        if nextPage?
            nextPage.updateTransform currPage.transformPosition + 100
            nextPage.show()

        return

    panEnd: (e) ->
        return if @pan.active isnt true

        pageIndex = @pageIndex
        prevPage = @pages.at @pan.pageIndex - 1
        currPage = @pages.at @pan.pageIndex
        nextPage = @pages.at @pan.pageIndex + 1

        prevPage.updatePosition prevPage.transformPosition if prevPage?
        currPage.updatePosition currPage.transformPosition
        nextPage.updatePosition nextPage.transformPosition if nextPage?

        if @swipeDirection is 'horizontal' and Math.abs(e.overallVelocityX) >= @swipeVelocity
            if Math.abs(e.deltaX) >= @swipeThreshold
                if e.offsetDirection is Hammer.DIRECTION_LEFT
                    @next()
                else if e.offsetDirection is Hammer.DIRECTION_RIGHT
                    @prev()
        else if @swipeDirection is 'vertical' and Math.abs(e.overallVelocityY) >= @swipeVelocity
            if Math.abs(e.deltaY) >= @swipeThreshold
                if e.offsetDirection is Hammer.DIRECTION_UP
                    @next()
                else if e.offsetDirection is Hammer.DIRECTION_DOWN
                    @prev()

        # No page change occurred.
        if pageIndex is @pageIndex and @pages.queue.length is 0
            if currPage.position < 0
                @pages.transition pageIndex + 1, pageIndex
            else if currPage.position > 0
                @pages.transition pageIndex - 1, pageIndex

        @pages.resume()
        @pan.active = false

        return

    pinchStart: (e) ->
        return if @pan.active is true

        @pinch.active = true

        return

    pinchMove: (e) ->
        return if @pinch.active isnt true

        return

    pinchEnd: (e) ->
        return if @pinch.active isnt true

        @pinch.active = false

        return

    doubleTap: (e) ->
        return
