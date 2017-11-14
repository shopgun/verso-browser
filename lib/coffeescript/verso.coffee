Hammer = require 'hammerjs'
MicroEvent = require 'microevent'
PageSpread = require './page_spread'
Animation = require './animation'

class Verso
    constructor: (@el, @options = {}) ->
        @swipeVelocity = @options.swipeVelocity ? 0.3
        @swipeThreshold = @options.swipeThreshold ? 10
        @navigationDuration = @options.navigationDuration ? 240
        @navigationPanDuration = @options.navigationPanDuration ? 200
        @zoomDuration = @options.zoomDuration ? 200
        @doubleTapDelay = @options.doubleTapDelay ? 250

        @position = -1
        @pinching = false
        @panning = false
        @transform = left: 0, top: 0, scale: 1
        @startTransform = left: 0, top: 0, scale: 1
        @tap =
            count: 0
            delay: @doubleTapDelay
        @contextmenu =
            count: 0
            delay: @doubleTapDelay

        @scrollerEl = @el.querySelector '.verso__scroller'
        @pageSpreadEls = @el.querySelectorAll '.verso__page-spread'
        @pageSpreads = @traversePageSpreads @pageSpreadEls
        @pageIds = @buildPageIds @pageSpreads
        @animation = new Animation @scrollerEl
        @hammer = new Hammer.Manager @scrollerEl,
            touchAction: 'none'
            enable: false
            # Prefer touch input if possible since Android acts weird when using pointer events.
            inputClass: if 'ontouchstart' of window then Hammer.TouchInput else null

        @hammer.add new Hammer.Pan threshold: 5, direction: Hammer.DIRECTION_ALL
        @hammer.add new Hammer.Tap event: 'singletap', interval: 0
        @hammer.add new Hammer.Pinch()
        @hammer.add new Hammer.Press time: 500
        @hammer.on 'panstart', @onPanStart.bind @
        @hammer.on 'panmove', @onPanMove.bind @
        @hammer.on 'panend', @onPanEnd.bind @
        @hammer.on 'pancancel', @onPanEnd.bind @
        @hammer.on 'singletap', @onSingletap.bind @
        @hammer.on 'pinchstart', @onPinchStart.bind @
        @hammer.on 'pinchmove', @onPinchMove.bind @
        @hammer.on 'pinchend', @onPinchEnd.bind @
        @hammer.on 'pinchcancel', @onPinchEnd.bind @
        @hammer.on 'press', @onPress.bind @

        @scrollerEl.addEventListener 'contextmenu', @onContextmenu.bind @

        return

    start: ->
        pageId = @getPageSpreadPositionFromPageId(@options.pageId) ? 0

        @hammer.set enable: true
        @navigateTo pageId, duration: 0

        @resizeListener = @onResize.bind @
        @touchStartListener = @onTouchStart.bind @
        @touchEndListener = @onTouchEnd.bind @

        @el.addEventListener 'touchstart', @touchStartListener, false
        @el.addEventListener 'touchend', @touchEndListener, false

        window.addEventListener 'resize', @resizeListener, false

        @

    destroy: ->
        @hammer.destroy()

        @el.removeEventListener 'touchstart', @touchStartListener
        @el.removeEventListener 'touchend', @touchEndListener

        window.removeEventListener 'resize', @resizeListener

        @

    first: (options) ->
        @navigateTo 0, options

    prev: (options) ->
        @navigateTo @getPosition() - 1, options

    next: (options) ->
        @navigateTo @getPosition() + 1, options

    last: (options) ->
        @navigateTo @getPageSpreadCount() - 1, options

    navigateTo: (position, options = {}) ->
        return if position < 0 or position > @getPageSpreadCount() - 1

        currentPosition = @getPosition()
        currentPageSpread = @getPageSpreadFromPosition currentPosition
        activePageSpread = @getPageSpreadFromPosition position
        carousel = @getCarouselFromPageSpread activePageSpread
        velocity = options.velocity ? 1
        duration = options.duration ? @navigationDuration
        duration = duration / Math.abs(velocity)
        touchAction = if activePageSpread.isScrollable() then 'pan-y' else 'none'

        currentPageSpread.deactivate() if currentPageSpread?
        activePageSpread.activate()

        carousel.visible.forEach (pageSpread) -> pageSpread.position().setVisibility 'visible'

        @hammer.set touchAction: touchAction

        @transform.left = @getLeftTransformFromPageSpread position, activePageSpread
        @setPosition position

        if @transform.scale > 1
            @transform.top = 0
            @transform.scale = 1

            @trigger 'zoomedOut', position: currentPosition

        @trigger 'beforeNavigation',
            currentPosition: currentPosition
            newPosition: position

        @animation.animate
            x: "#{@transform.left}%"
            duration: duration
        , =>
            carousel = @getCarouselFromPageSpread @getActivePageSpread()

            carousel.gone.forEach (pageSpread) -> pageSpread.setVisibility 'gone'

            @trigger 'afterNavigation',
                newPosition: @getPosition()
                previousPosition: currentPosition

            return

        return

    getPosition: ->
        @position

    setPosition: (position) ->
        @position = position

        @

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
                visible = true if pageSpread.getLeft() + pageSpread.getWidth() > pageSpreadSubject.getLeft() - 100
            else
                visible = true if pageSpread.getLeft() - pageSpread.getWidth() < pageSpreadSubject.getLeft() + 100

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
            type = el.getAttribute 'data-type'
            pageIds = el.getAttribute 'data-page-ids'
            pageIds = if pageIds? then pageIds.split(',').map (i) -> i else []
            maxZoomScale = el.getAttribute 'data-max-zoom-scale'
            maxZoomScale = if maxZoomScale? then +maxZoomScale else 1
            width = el.getAttribute 'data-width'
            width = if width? then +width else 100
            pageSpread = new PageSpread el,
                id: id
                type: type
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

    isCoordinateInsideElement: (x, y, el) ->
        rect = el.getBoundingClientRect()

        x >= rect.left and x <= rect.right and y >= rect.top and y <= rect.bottom

    getCoordinateInfo: (x, y, pageSpread) ->
        x -= @el.offsetLeft
        y -= @el.offsetTop
        info =
            x: x
            y: y
            contentX: 0
            contentY: 0
            pageX: 0
            pageY: 0
            overlayEls: []
            pageEl: null
            isInsideContentX: false
            isInsideContentY: false
            isInsideContent: false
        contentRect = pageSpread.getContentRect()
        overlayEls = pageSpread.getOverlayEls()
        pageEls = pageSpread.getPageEls()

        for overlayEl in overlayEls
            info.overlayEls.push overlayEl if @isCoordinateInsideElement(x, y, overlayEl)

        for pageEl in pageEls
            if @isCoordinateInsideElement(x, y, pageEl)
                info.pageEl = pageEl
                break

        info.contentX = (x - contentRect.left) / Math.max(1, contentRect.width)
        info.contentY = (y - contentRect.top) / Math.max(1, contentRect.height)

        if info.pageEl?
            info.isInsideContentX = info.contentX >= 0 and info.contentX <= 1
            info.isInsideContentY = info.contentY >= 0 and info.contentY <= 1
            info.isInsideContent = info.isInsideContentX and info.isInsideContentY

        info

    getPageSpreadCount: ->
        @pageSpreads.length

    getActivePageSpread: ->
        @getPageSpreadFromPosition @getPosition()

    getPageSpreadFromPosition: (position) ->
        @pageSpreads[position]

    getPageSpreadPositionFromPageId: (pageId) ->
        for pageSpread, idx in @pageSpreads
            return idx if pageSpread.options.pageIds.indexOf(pageId) > -1

    getPageSpreadBounds: (pageSpread) ->
        pageSpreadRect = pageSpread.getRect()
        pageSpreadContentRect = pageSpread.getContentRect()

        left: (pageSpreadContentRect.left - pageSpreadRect.left) / pageSpreadRect.width * 100
        top: (pageSpreadContentRect.top - pageSpreadRect.top) / pageSpreadRect.height * 100
        width: pageSpreadContentRect.width / pageSpreadRect.width * 100
        height: pageSpreadContentRect.height / pageSpreadRect.height * 100
        pageSpreadRect: pageSpreadRect
        pageSpreadContentRect: pageSpreadContentRect

    clipCoordinate: (coordinate, scale, size, offset) ->
        if size * scale < 100
            coordinate = offset * -scale + 50 - (size * scale / 2)
        else
            coordinate = Math.min coordinate, offset * -scale
            coordinate = Math.max coordinate, offset * -scale - size * scale + 100

        coordinate

    zoomTo: (options = {}, callback) ->
        scale = options.scale
        curScale = @transform.scale
        activePageSpread = @getActivePageSpread()
        pageSpreadBounds = @getPageSpreadBounds activePageSpread
        carouselOffset = activePageSpread.getLeft()
        carouselScaledOffset = carouselOffset * curScale
        x = options.x ? 0
        y = options.y ? 0

        if scale isnt 1
            x -= pageSpreadBounds.pageSpreadRect.left
            y -= pageSpreadBounds.pageSpreadRect.top
            x = x / (pageSpreadBounds.pageSpreadRect.width / curScale) * 100
            y = y / (pageSpreadBounds.pageSpreadRect.height / curScale) * 100
            x = @transform.left + carouselScaledOffset + x - (x * scale / curScale)
            y = @transform.top + y - (y * scale / curScale)

            # Make sure the animation doesn't exceed the content bounds.
            if options.bounds isnt false and scale > 1
                x = @clipCoordinate x, scale, pageSpreadBounds.width, pageSpreadBounds.left
                y = @clipCoordinate y, scale, pageSpreadBounds.height, pageSpreadBounds.top
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

    refresh: ->
        @pageSpreadEls = @el.querySelectorAll '.verso__page-spread'
        @pageSpreads = @traversePageSpreads @pageSpreadEls
        @pageIds = @buildPageIds @pageSpreads

        @

    ##############
    ### Events ###
    ##############

    onPanStart: (e) ->
        # Only allow panning if zoomed in or doing a horizontal pan.
        # This ensures vertical scrolling works for scrollable page spreads.
        if @transform.scale > 1 or (e.direction is Hammer.DIRECTION_LEFT or e.direction is Hammer.DIRECTION_RIGHT)
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

    onPanMove: (e) ->
        return if @pinching is true or @panning is false

        if @transform.scale > 1
            activePageSpread = @getActivePageSpread()
            carouselOffset = activePageSpread.getLeft()
            carouselScaledOffset = carouselOffset * @transform.scale
            pageSpreadBounds = @getPageSpreadBounds activePageSpread
            scale = @transform.scale
            x = @startTransform.left + carouselScaledOffset + e.deltaX / @scrollerEl.offsetWidth * 100
            y = @startTransform.top + e.deltaY / @scrollerEl.offsetHeight * 100
            x = @clipCoordinate x, scale, pageSpreadBounds.width, pageSpreadBounds.left
            y = @clipCoordinate y, scale, pageSpreadBounds.height, pageSpreadBounds.top
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

    onPanEnd: (e) ->
        return if @panning is false

        @panning = false
        @trigger 'panEnd'

        if @transform.scale is 1 and @pinching is false
            position = @getPosition()
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

            if position is @getPosition()
                @animation.animate
                    x: "#{@transform.left}%"
                    duration: @navigationPanDuration

                @trigger 'attemptedNavigation', position: @getPosition()

        return

    onPinchStart: (e) ->
        return if not @getActivePageSpread().isZoomable()

        @pinching = true
        @el.setAttribute 'data-pinching', true
        @startTransform.scale = @transform.scale

        return

    onPinchMove: (e) ->
        return if @pinching is false

        @zoomTo
            x: e.center.x
            y: e.center.y
            scale: @startTransform.scale * e.scale
            bounds: false
            easing: 'linear'

        return

    onPinchEnd: (e) ->
        return if @pinching is false

        activePageSpread = @getActivePageSpread()
        maxZoomScale = activePageSpread.getMaxZoomScale()
        scale = Math.max 1, Math.min(@transform.scale, maxZoomScale)
        position = @getPosition()

        if @startTransform.scale is 1 and scale > 1
            @trigger 'zoomedIn', position: position
        else if @startTransform.scale > 1 and scale is 1
            @trigger 'zoomedOut', position: position

        @zoomTo
            x: e.center.x
            y: e.center.y
            scale: scale
            duration: @zoomDuration
        , =>
            @pinching = false
            @el.setAttribute 'data-pinching', false

            return

        return

    onPress: (e) ->
        @trigger 'pressed', @getCoordinateInfo(e.center.x, e.center.y, @getActivePageSpread())

        return

    onContextmenu: (e) ->
        e.preventDefault()

        clearTimeout @contextmenu.timeout

        if @contextmenu.count is 1
            @contextmenu.count = 0

            if @getActivePageSpread().isZoomable() and @transform.scale > 1
                position = @getPosition()

                @zoomTo
                    x: e.clientX
                    y: e.clientY
                    scale: 1
                    duration: @zoomDuration
                , =>
                    @trigger 'zoomedOut', position: position

                    return

            @trigger 'doubleContextmenu', @getCoordinateInfo(e.clientX, e.clientY, @getActivePageSpread())
        else
            @contextmenu.count++
            @contextmenu.timeout = setTimeout =>
                @contextmenu.count = 0

                @trigger 'contextmenu', @getCoordinateInfo(e.clientX, e.clientY, @getActivePageSpread())
            , @contextmenu.delay

        false

    onSingletap: (e) ->
        activePageSpread = @getActivePageSpread()
        coordinateInfo = @getCoordinateInfo e.center.x, e.center.y, activePageSpread

        clearTimeout @tap.timeout

        if @tap.count is 1
            @tap.count = 0

            @trigger 'doubleClicked', coordinateInfo

            if activePageSpread.isZoomable()
                maxZoomScale = activePageSpread.getMaxZoomScale()
                zoomedIn = @transform.scale > 1
                scale = if zoomedIn then 1 else maxZoomScale
                zoomEvent = if zoomedIn then 'zoomedOut' else 'zoomedIn'
                position = @getPosition()

                @zoomTo
                    x: e.center.x
                    y: e.center.y
                    scale: scale
                    duration: @zoomDuration
                , =>
                    @trigger zoomEvent, position: position

                    return
        else
            @tap.count++
            @tap.timeout = setTimeout =>
                @tap.count = 0

                @trigger 'clicked', coordinateInfo

                return
            , @tap.delay

        return

    onTouchStart: (e) ->
        e.preventDefault() if not @getActivePageSpread().isScrollable()

        return

    onTouchEnd: (e) ->
        e.preventDefault()

        return

    onResize: ->
        if @transform.scale > 1
            position = @getPosition()
            activePageSpread = @getActivePageSpread()

            @transform.left = @getLeftTransformFromPageSpread position, activePageSpread
            @transform.top = 0
            @transform.scale = 1

            @zoomTo
                x: @transform.left
                y: @transform.top
                scale: @transform.scale
                duration: 0

            @trigger 'zoomedOut', position: position

        return

MicroEvent.mixin Verso

module.exports = Verso
