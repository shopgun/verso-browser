Hammer = require 'hammerjs'
MicroEvent = require 'microevent'
PageSpread = require './page_spread'
Animation = require './animation'

class Verso
    constructor: (@el, @options = {}) ->
        @swipeVelocity = @options.swipeVelocity ? 0.3
        @swipeThreshold = @options.swipeThreshold ? 10
        @navigationDuration = @options.navigationDuration ? 200

        @position = -1
        @transform = x: 0, scale: 1

        @scrollerEl = @el.querySelector '.verso__scroller'
        @pageSpreadEls = @el.querySelectorAll '.verso__page-spread'
        @pageSpreads = @traversePageSpreads @pageSpreadEls
        @pageIds = @buildPageIds @pageSpreads
        @animation = new Animation @scrollerEl
        @hammer = new Hammer.Manager @scrollerEl,
            touchAction: 'auto'
            enable: false

        @hammer.add new Hammer.Pan direction: Hammer.DIRECTION_HORIZONTAL
        @hammer.on 'panstart', @panStart.bind @
        @hammer.on 'panmove', @panMove.bind @
        @hammer.on 'panend', @panEnd.bind @

        return

    start: ->
        @hammer.set enable: true

        @navigateTo @getPageSpreadPositionFromPageId(@options.pageId) ? 0, transition: false

        return

    destroy: ->
        @hammer.destroy()

        @

    prev: (options) ->
        @navigateTo @position - 1, options

    next: (options) ->
        @navigateTo @position + 1, options

    navigateTo: (position, options = {}) ->
        return if position is @position or position < 0 or position > @getPageSpreadCount() - 1

        currentPosition = @position
        activePageSpread = @getPageSpreadFromPosition position
        carousel = @getCarouselFromPageSpread activePageSpread
        velocity = options.velocity ? 1
        duration = if options.transition is false then 0 else @navigationDuration
        duration = duration / Math.abs(velocity)

        @trigger 'beforeNavigation', currentPosition: @position, newPosition: position

        carousel.visible.forEach (pageSpread) -> pageSpread.position().setVisibility 'visible'

        if position is @getPageSpreadCount() - 1
            @transform.x = (100 - activePageSpread.getWidth()) - activePageSpread.getLeft()
        else if position > 0
            @transform.x = (100 - activePageSpread.getWidth()) / 2 - activePageSpread.getLeft()
        else
            @transform.x = 0

        @position = position

        @animation.animate
            x: "#{@transform.x}%"
            duration: duration
        , =>
            activePageSpread = @getPageSpreadFromPosition @position
            carousel = @getCarouselFromPageSpread activePageSpread

            carousel.gone.forEach (pageSpread) -> pageSpread.setVisibility 'gone'

            @trigger 'afterNavigation', newPosition: @position, previousPosition: currentPosition

            return

        return

    getCarouselFromPageSpread: (pageSpreadSubject) ->
        carousel =
            visible: []
            gone: []

        # Identify the page spreads that should be a part of the carousel.
        @pageSpreads.forEach (pageSpread) ->
            visible = false

            if pageSpread.getLeft() <= pageSpreadSubject.getLeft()
                visible = true if pageSpread.getLeft() + pageSpread.getWidth() >= pageSpreadSubject.getLeft() - 100
            else
                visible = true if pageSpread.getLeft() - pageSpread.getWidth() <= pageSpreadSubject.getLeft() + 100

            if visible is true
                carousel.visible.push pageSpread
            else
                carousel.gone.push pageSpread

            return

        carousel

    traversePageSpreads: (els) ->
        pageSpreads = []
        left = 0

        for el in els
            pageIds = el.getAttribute 'data-page-ids'
            pageIds = if pageIds? then pageIds.split(',').map (i) -> +i else []
            maxZoomScale = el.getAttribute 'data-max-zoom-scale'
            maxZoomScale = if maxZoomScale? then +maxZoomScale else 1
            width = el.getAttribute 'data-width'
            width = if width? then +width else 100
            pageSpread = new PageSpread el,
                pageIds: pageIds
                maxZoomScale: maxZoomScale
                width: width
                left: left

            left += width

            pageSpreads.push pageSpread

        pageSpreads

    buildPageIds: (pageSpreads) ->
        pageIds = {}

        pageSpreads.forEach (pageSpread, i) =>
            pageSpread.options.pageIds.forEach (pageId) =>
                pageIds[pageId] = pageSpread

                return

            return

        pageIds

    getPageSpreadCount: ->
        @pageSpreads.length

    getPageSpreadFromPosition: (position) ->
        @pageSpreads[position]

    getPageSpreadPositionFromPageId: (pageId) ->
        for pageSpread, idx in @pageSpreads
            return idx if pageSpread.options.pageIds.indexOf(pageId) > -1

    panStart: (e) ->
        e.preventDefault()

        return

    panMove: (e) ->
        e.preventDefault()

        totalWidth = @scrollerEl.offsetWidth
        deltaX = @transform.x + e.deltaX / totalWidth * 100

        @animation.animate x: "#{deltaX}%", easing: 'linear'

        return

    panEnd: (e) ->
        e.preventDefault()

        position = @position

        if Math.abs(e.overallVelocityX) >= @swipeVelocity
            if Math.abs(e.deltaX) >= @swipeThreshold
                if e.offsetDirection is Hammer.DIRECTION_LEFT
                    @next velocity: e.overallVelocityX
                else if e.offsetDirection is Hammer.DIRECTION_RIGHT
                    @prev velocity: e.overallVelocityX

        if position is @position
            @animation.animate x: "#{@transform.x}%", duration: @navigationDuration

        return

MicroEvent.mixin Verso

module.exports = Verso
