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
        @pinching = false
        @panning = false
        @transform = left: 0, top: 0, scale: 1
        @startTransform = left: 0, top: 0, scale: 1

        @scrollerEl = @el.querySelector '.verso__scroller'
        @pageSpreadEls = @el.querySelectorAll '.verso__page-spread'
        @pageSpreads = @traversePageSpreads @pageSpreadEls
        @pageIds = @buildPageIds @pageSpreads
        @animation = new Animation @scrollerEl
        @hammer = new Hammer.Manager @scrollerEl,
            touchAction: 'auto'
            enable: false
            # Prefer touch input if possible since Android acts weird when using pointer events.
            inputClass: if 'ontouchstart' of window then Hammer.TouchInput else null

        @hammer.add new Hammer.Pan direction: Hammer.DIRECTION_ALL
        @hammer.add new Hammer.Tap event: 'doubletap', taps: 2, threshold: 16, posThreshold: 25
        @hammer.add new Hammer.Tap event: 'singletap'
        @hammer.add new Hammer.Pinch()
        @hammer.add new Hammer.Press time: 500
        @hammer.get('doubletap').recognizeWith 'singletap'
        @hammer.get('singletap').requireFailure 'doubletap'
        @hammer.on 'panstart', @panStart.bind @
        @hammer.on 'panmove', @panMove.bind @
        @hammer.on 'panend', @panEnd.bind @
        @hammer.on 'pancancel', @panEnd.bind @
        @hammer.on 'singletap', @singleTap.bind @
        @hammer.on 'doubletap', @doubleTap.bind @
        @hammer.on 'pinchstart', @pinchStart.bind @
        @hammer.on 'pinchmove', @pinchMove.bind @
        @hammer.on 'pinchend', @pinchEnd.bind @
        @hammer.on 'pinchcancel', @pinchEnd.bind @
        @hammer.on 'press', @press.bind @

        return

    start: ->
        @hammer.set enable: true

        @navigateTo @getPageSpreadPositionFromPageId(@options.pageId) ? 0, duration: 0

        return

    destroy: ->
        @hammer.destroy()

        @

    first: (options) ->
        @navigateTo 0, options

    prev: (options) ->
        @navigateTo @position - 1, options

    next: (options) ->
        @navigateTo @position + 1, options

    last: (options) ->
        @navigateTo @getPageSpreadCount() - 1, options

    navigateTo: (position, options = {}) ->
        return if position is @position or position < 0 or position > @getPageSpreadCount() - 1

        currentPosition = @position
        currentPageSpread = @getPageSpreadFromPosition currentPosition
        activePageSpread = @getPageSpreadFromPosition position
        carousel = @getCarouselFromPageSpread activePageSpread
        velocity = options.velocity ? 1
        duration = options.duration ? @navigationDuration
        duration = duration / Math.abs(velocity)

        currentPageSpread.deactivate() if currentPageSpread?
        activePageSpread.activate()

        carousel.visible.forEach (pageSpread) -> pageSpread.position().setVisibility 'visible'

        @transform.left = @getLeftTransformFromPageSpread position, activePageSpread
        @position = position

        if @transform.scale > 1
            @transform.top = 0
            @transform.scale = 1

            @trigger 'zoomedOut', position: currentPosition

        @trigger 'beforeNavigation', currentPosition: currentPosition, newPosition: position

        @animation.animate
            x: "#{@transform.left}%"
            duration: duration
        , =>
            carousel = @getCarouselFromPageSpread @getActivePageSpread()

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
            id = el.getAttribute 'data-id'
            pageIds = el.getAttribute 'data-page-ids'
            pageIds = if pageIds? then pageIds.split(',').map (i) -> i else []
            maxZoomScale = el.getAttribute 'data-max-zoom-scale'
            maxZoomScale = if maxZoomScale? then +maxZoomScale else 1
            width = el.getAttribute 'data-width'
            width = if width? then +width else 100
            pageSpread = new PageSpread el,
                id: id
                pageIds: pageIds
                maxZoomScale: maxZoomScale
                width: width
                left: left

            left += width

            pageSpreads.push pageSpread

        pageSpreads

    buildPageIds: (pageSpreads) ->
        pageIds = {}

        pageSpreads.forEach (pageSpread, i) ->
            pageSpread.options.pageIds.forEach (pageId) ->
                pageIds[pageId] = pageSpread

                return

            return

        pageIds

    getOverlayElementsFromPoint: (els, x, y) ->
        overlayEls = []

        for el in els
            if el.classList? and el.classList.contains 'verso-page-spread__overlay'
                rect = el.getBoundingClientRect()

                if x >= rect.left and x <= rect.right and y >= rect.top and y <= rect.bottom
                    overlayEls.push el

        overlayEls

    getPageSpreadCount: ->
        @pageSpreads.length

    getActivePageSpread: ->
        @getPageSpreadFromPosition @position

    getPageSpreadFromPosition: (position) ->
        @pageSpreads[position]

    getPageSpreadPositionFromPageId: (pageId) ->
        for pageSpread, idx in @pageSpreads
            return idx if pageSpread.options.pageIds.indexOf(pageId) > -1

    getPageSpreadBounds: (pageSpread) ->
        pageSpreadRect = pageSpread.el.getBoundingClientRect()
        pageSpreadContentRect = pageSpread.getContentEl().getBoundingClientRect()

        left: (pageSpreadContentRect.left - pageSpreadRect.left) / pageSpreadRect.width * 100
        top: (pageSpreadContentRect.top - pageSpreadRect.top) / pageSpreadRect.height * 100
        width: pageSpreadContentRect.width / pageSpreadRect.width * 100
        height: pageSpreadContentRect.height / pageSpreadRect.height * 100
        pageSpreadRect: pageSpreadRect
        pageSpreadContentRect: pageSpreadContentRect

    clipLeftFromPageSpreadBounds: (x, scale, pageSpreadBounds) ->
        x = Math.min x, pageSpreadBounds.left * -scale
        x = Math.max x, pageSpreadBounds.left * -scale - pageSpreadBounds.width * scale + 100

        x

    clipTopFromPageSpreadBounds: (y, scale, pageSpreadBounds) ->
        y = Math.min y, pageSpreadBounds.top * -scale
        y = Math.max y, pageSpreadBounds.top * -scale - pageSpreadBounds.height * scale + 100

        y

    zoomTo: (options = {}, callback) ->
        scale = options.scale
        activePageSpread = @getActivePageSpread()
        pageSpreadBounds = @getPageSpreadBounds activePageSpread
        carouselOffset = activePageSpread.getLeft()
        carouselScaledOffset = carouselOffset * @transform.scale
        x = options.x ? 0
        y = options.y ? 0

        if scale isnt 1
            x -= pageSpreadBounds.pageSpreadRect.left
            y -= pageSpreadBounds.pageSpreadRect.top
            x = x / (pageSpreadBounds.pageSpreadRect.width / @transform.scale) * 100
            y = y / (pageSpreadBounds.pageSpreadRect.height / @transform.scale) * 100
            x = @transform.left + carouselScaledOffset + x - (x * scale / @transform.scale)
            y = @transform.top + y - (y * scale / @transform.scale)

            # Make sure the animation doesn't exceed the content bounds.
            if options.bounds isnt false and scale > 1
                x = @clipLeftFromPageSpreadBounds x, scale, pageSpreadBounds
                y = @clipTopFromPageSpreadBounds y, scale, pageSpreadBounds
        else
            x = 0
            y = 0

        # Account for the page spreads left of the active one.
        x -= carouselOffset * scale

        @transform.left = x
        @transform.top = y
        @transform.scale = scale

        @animation.animate
            x: "#{x}%"
            y: "#{y}%"
            scale: scale
            easing: options.easing
            duration: options.duration
        , callback

        return

    panStart: (e) ->
        x = e.center.x
        edgeThreshold = 30
        width = @scrollerEl.offsetWidth

        # Prevent panning when edge-swiping on iOS.
        if x > edgeThreshold and x < width - edgeThreshold
            @startTransform.left = @transform.left
            @startTransform.top = @transform.top

            @panning = true

            @trigger 'panStart'

        return

    panMove: (e) ->
        return if @pinching is true or @panning is false

        if @transform.scale > 1
            activePageSpread = @getActivePageSpread()
            carouselOffset = activePageSpread.getLeft()
            carouselScaledOffset = carouselOffset * @transform.scale
            pageSpreadBounds = @getPageSpreadBounds activePageSpread
            scale = @transform.scale
            x = @startTransform.left + carouselScaledOffset + e.deltaX / @scrollerEl.offsetWidth * 100
            y = @startTransform.top + e.deltaY / @scrollerEl.offsetHeight * 100
            x = @clipLeftFromPageSpreadBounds x, scale, pageSpreadBounds
            y = @clipTopFromPageSpreadBounds y, scale, pageSpreadBounds
            x -= carouselScaledOffset

            @transform.left = x
            @transform.top = y

            @animation.animate
                x: "#{x}%"
                y: "#{y}%"
                scale: scale
                easing: 'linear'
        else
            x = @transform.left + e.deltaX / @scrollerEl.offsetWidth * 100

            @animation.animate
                x: "#{x}%"
                easing: 'linear'

        return

    panEnd: (e) ->
        return if @panning is false

        @panning = false
        @trigger 'panEnd'

        if @transform.scale is 1 and @pinching is false
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

    pinchStart: (e) ->
        return if not @getActivePageSpread().isZoomable()

        @pinching = true
        @el.dataset.pinching = true
        @startTransform.scale = @transform.scale

        return

    pinchMove: (e) ->
        return if @pinching is false

        @zoomTo
            x: e.center.x
            y: e.center.y
            scale: @startTransform.scale * e.scale
            bounds: false
            easing: 'linear'

        return

    pinchEnd: (e) ->
        return if @pinching is false

        activePageSpread = @getActivePageSpread()
        maxZoomScale = activePageSpread.getMaxZoomScale()
        scale = Math.max 1, Math.min(@transform.scale, maxZoomScale)

        if @startTransform.scale is 1 and scale > 1
            @trigger 'zoomedIn', position: @position
        else if @startTransform.scale > 1 and scale is 1
            @trigger 'zoomedOut', position: @position

        @zoomTo
            x: e.center.x
            y: e.center.y
            scale: scale
            duration: @zoomDuration
        , =>
            @pinching = false
            @el.dataset.pinching = false

            return

        return

    press: (e) ->
        overlayEls = @getOverlayElementsFromPoint e.target.parentNode.childNodes, e.center.x, e.center.y

        @trigger 'overlaysPressed', overlayEls: overlayEls if overlayEls.length > 0

        return

    singleTap: (e) ->
        overlayEls = @getOverlayElementsFromPoint e.target.parentNode.childNodes, e.center.x, e.center.y

        @trigger 'overlaysClicked', overlayEls: overlayEls if overlayEls.length > 0

        return

    doubleTap: (e) ->
        activePageSpread = @getActivePageSpread()

        if activePageSpread.isZoomable()
            maxZoomScale = activePageSpread.getMaxZoomScale()
            zoomedIn = @transform.scale > 1
            scale = if zoomedIn then 1 else maxZoomScale
            zoomEvent = if zoomedIn then 'zoomedOut' else 'zoomedIn'

            @trigger zoomEvent, position: @position

            @zoomTo
                x: e.center.x
                y: e.center.y
                scale: scale
                duration: @zoomDuration

        return

MicroEvent.mixin Verso

module.exports = Verso
