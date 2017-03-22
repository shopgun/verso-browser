Hammer = require 'hammerjs'
MicroEvent = require 'microevent'
PageSpread = require './page_spread'
Animation = require './animation'

class Verso
    constructor: (@el, @options = {}) ->
        @swipeVelocity = @options.swipeVelocity ? 0.3
        @swipeThreshold = @options.swipeThreshold ? 10
        @navigationDuration = @options.navigationDuration ? 200
        @navigationPanDuration = @options.navigationPanDuration ? 200
        @zoomDuration = @options.zoomDuration ? 200

        @position = -1
        @transform = left: 0, top: 0, scale: 1

        @scrollerEl = @el.querySelector '.verso__scroller'
        @pageSpreadEls = @el.querySelectorAll '.verso__page-spread'
        @pageSpreads = @traversePageSpreads @pageSpreadEls
        @pageIds = @buildPageIds @pageSpreads
        @animation = new Animation @scrollerEl
        @hammer = new Hammer.Manager @scrollerEl,
            touchAction: 'auto'
            enable: false

        @hammer.add new Hammer.Pan direction: Hammer.DIRECTION_HORIZONTAL
        @hammer.add new Hammer.Tap event: 'doubletap', taps: 2
        @hammer.add new Hammer.Tap event: 'singletap'
        @hammer.get('doubletap').recognizeWith 'singletap'
        @hammer.get('singletap').requireFailure 'doubletap'
        @hammer.on 'panmove', @panMove.bind @
        @hammer.on 'panend', @panEnd.bind @
        @hammer.on 'singletap', @singleTap.bind @
        @hammer.on 'doubletap', @doubleTap.bind @
        @hammer.on 'pinchstart', @pinchStart.bind @
        @hammer.on 'pinchmove', @pinchMove.bind @
        @hammer.on 'pinchend', @pinchEnd.bind @

        return

    start: ->
        @hammer.set enable: true

        @navigateTo @getPageSpreadPositionFromPageId(@options.pageId) ? 0, duration: 0

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
        duration = options.duration ? @navigationDuration
        duration = duration / Math.abs(velocity)

        carousel.visible.forEach (pageSpread) -> pageSpread.position().setVisibility 'visible'

        @transform.left = @getLeftTransformFromPageSpread position, activePageSpread
        @position = position

        @trigger 'beforeNavigation', currentPosition: currentPosition, newPosition: position

        @animation.animate
            x: "#{@transform.left}%"
            duration: duration
        , =>
            activePageSpread = @getPageSpreadFromPosition @position
            carousel = @getCarouselFromPageSpread activePageSpread

            carousel.gone.forEach (pageSpread) -> pageSpread.setVisibility 'gone'

            @trigger 'afterNavigation', newPosition: @position, previousPosition: currentPosition

            return

        return

    getLeftTransformFromPageSpread: (position, pageSpread) ->
        left = 0

        if position is @getPageSpreadCount() - 1
            left = (100 - pageSpread.getWidth()) - pageSpread.getLeft()
        else if position > 0
            left = (100 - pageSpread.getWidth()) / 2 - pageSpread.getLeft()

        left

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

    zoomTo: (options = {}) ->
        activePageSpread = @getPageSpreadFromPosition @position
        width = activePageSpread.el.offsetWidth
        height = activePageSpread.el.offsetHeight
        scale = options.scale
        x = (options.x ? 0) / width * 100
        y = (options.y ? 0) / height * 100
        x = -(x * scale)
        y = -(y * scale)
        x -= x / scale
        y -= y / scale
        x -= activePageSpread.getLeft() * scale

        @transform.left = x
        @transform.top = y
        @transform.scale = scale

        @animation.animate
            x: "#{x}%"
            y: "#{y}%"
            scale: scale
            duration: options.duration
            easing: 'ease-out'

        return

    panMove: (e) ->
        e.preventDefault()

        totalWidth = @scrollerEl.offsetWidth
        deltaX = @transform.left + e.deltaX / totalWidth * 100

        @animation.animate x: "#{deltaX}%", easing: 'linear'

        return

    panEnd: (e) ->
        e.preventDefault()

        position = @position
        velocity = e.overallVelocityX

        if Math.abs(velocity) >= @swipeVelocity
            if Math.abs(e.deltaX) >= @swipeThreshold
                if e.offsetDirection is Hammer.DIRECTION_LEFT
                    @next
                        velocity: velocity
                        duration: @navigationPanDuration
                else if e.offsetDirection is Hammer.DIRECTION_RIGHT
                    @prev
                        velocity: velocity
                        duration: @navigationPanDuration

        if position is @position
            @animation.animate
                x: "#{@transform.left}%"
                duration: @navigationPanDuration

        return

    singleTap: (e) ->
        els = e.target.parentNode.childNodes
        overlayEls = []
        x = e.center.x
        y = e.center.y

        for el in els
            if el.classList? and el.classList.contains 'verso-page-spread__overlay'
                rect = el.getBoundingClientRect()

                if x >= rect.left and x <= rect.right and y >= rect.top and y <= rect.bottom
                    overlayEls.push el

        @trigger 'overlaysClicked', overlayEls: overlayEls if overlayEls.length > 0

        return

    # https://github.com/shopgun/verso-browser/blob/master/lib/zoom.coffee#L273
    doubleTap: (e) ->
        activePageSpread = @getPageSpreadFromPosition @position
        maxZoomScale = activePageSpread.getMaxZoomScale()

        if maxZoomScale > 1
            @zoomTo
                x: e.center.x
                y: e.center.y
                scale: if @transform.scale is 1 then maxZoomScale else 1
                duration: @zoomDuration

        return

    pinchStart: (e) ->
        return

    pinchMove: (e) ->
        return

    pinchEnd: (e) ->
        return

MicroEvent.mixin Verso

module.exports = Verso
