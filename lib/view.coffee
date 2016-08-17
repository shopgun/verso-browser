Events = require './events'
Hammer = require 'hammerjs'
Pages = require './pages'
Page = require './page'
propagating = require 'propagating-hammerjs'

module.exports = class Verso extends Events
    defaults:
        pageIndex: 0
        swipeDirection: 'horizontal'
        swipeVelocity: 0.3
        swipeThreshold: 10
        transitionDuration: 220
        keysPrev: [8, 33, 37, 38] # Backspace, page up, left arrow, up arrow.
        keysNext: [13, 32, 34, 39, 40] # Enter, space, page down, right arrow, down arrow.

    constructor: (@el, options = {}) ->
        super()

        for key, value of @defaults
            @[key] = options[key] ? value

        @pages = new Pages @generatePages()
        @pan =
            active: false
            pageIndex: null
        @pinch =
            active: false
        @hammer = propagating new Hammer.Manager(@el.querySelector('.verso__pages'), touchAction: 'auto')

        @hammer.add new Hammer.Pan
            direction: do =>
                if @swipeDirection is 'horizontal'
                    Hammer.DIRECTION_HORIZONTAL
                else if @swipeDirection is 'vertical'
                    Hammer.DIRECTION_VERTICAL
                else
                    Hammer.DIRECTION_ALL
        @hammer.on 'panstart', @panStart.bind @
        @hammer.on 'panmove', @panMove.bind @
        @hammer.on 'panend', @panEnd.bind @

        @el.addEventListener 'keyup', @keyUp.bind(@), false
        @el.setAttribute 'tabindex', -1

        return

    show: ->
        @updateState()
        @pages.at(@pageIndex).show()

        @el.dataset.shown = true
        @el.focus()

        return

    go: (pageIndex, transition = {}) ->
        return if isNaN(pageIndex) or pageIndex < 0 or pageIndex > @pages.count() - 1 or pageIndex is @pageIndex

        from = @pageIndex
        to = pageIndex
        defaultTransition =
            velocity: 1
            baseDuration: @transitionDuration

        for key, value of defaultTransition
            transition[key] = value if not transition[key]?

        @trigger 'beforeChange', from, to

        @pageIndex = to
        @updateState()
        @pages.transition from, to, transition

        @trigger 'change', from, to

        return

    prev: (transition) ->
        @go @pageIndex - 1, transition

        return

    next: (transition) ->
        @go @pageIndex + 1, transition

        return

    updateState: ->
        @pages.at(@pageIndex).updateState 'current'
        @pages.at(@pageIndex - 1).updateState 'previous' if @pageIndex > 0
        @pages.at(@pageIndex + 1).updateState 'next' if @pageIndex + 1 < @pages.count()

        if @pageIndex > 1
            @pages.slice(0, @pageIndex - 1).forEach (page) ->
                page.updateState 'before'

                return

        if @pageIndex + 2 < @pages.count()
            @pages.slice(@pageIndex + 2).forEach (page) ->
                page.updateState 'after'

                return

        return

    generatePages: ->
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

    panStart: (e) ->
        e.preventDefault()

        return if @pinch.active is true
        return if e.changedPointers[0].pageX <= 20 or e.changedPointers[0].pageX >= window.innerWidth - 20

        pageEl = e.target
        pageIndex = null

        while pageEl.parentNode? and not pageEl.className.match(/\bverso__page\b/)
            pageEl = pageEl.parentNode

        pageIndex = +pageEl.dataset.versoindex
        page = @pages.at pageIndex

        if page? and page.scrolling is false
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
        e.preventDefault()

        return if @pan.active isnt true

        pageIndex = @pageIndex
        transition =
            velocity: e.velocity
            baseDuration: 280
        prevPage = @pages.at @pan.pageIndex - 1
        currPage = @pages.at @pan.pageIndex
        nextPage = @pages.at @pan.pageIndex + 1

        prevPage.updatePosition prevPage.transformPosition if prevPage?
        currPage.updatePosition currPage.transformPosition
        nextPage.updatePosition nextPage.transformPosition if nextPage?

        if @swipeDirection is 'horizontal' and Math.abs(e.overallVelocityX) >= @swipeVelocity
            if Math.abs(e.deltaX) >= @swipeThreshold
                if e.offsetDirection is Hammer.DIRECTION_LEFT
                    @next transition
                else if e.offsetDirection is Hammer.DIRECTION_RIGHT
                    @prev transition
        else if @swipeDirection is 'vertical' and Math.abs(e.overallVelocityY) >= @swipeVelocity
            if Math.abs(e.deltaY) >= @swipeThreshold
                if e.offsetDirection is Hammer.DIRECTION_UP
                    @next transition
                else if e.offsetDirection is Hammer.DIRECTION_DOWN
                    @prev transition

        # No page change occurred.
        if pageIndex is @pageIndex and @pages.queueCount() is 0
            if currPage.position < 0
                @pages.transition pageIndex + 1, pageIndex, transition
            else if currPage.position > 0
                @pages.transition pageIndex - 1, pageIndex, transition

        @pages.resume()
        @pan.active = false

        return
