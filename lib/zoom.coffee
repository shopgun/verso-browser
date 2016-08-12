propagating = require 'propagating-hammerjs'
Events = require './events'

module.exports = class Zoom extends Events
    defaults:
        transitionDuration: 220
        minScale: 1
        maxScale: 2.5
        easing: 'ease-in-out'
        scale: 1

    constructor: (@el, options = {}) ->
        super()

        for key, value of @defaults
            @[key] = options[key] ? value

        @x = 0
        @y = 0
        @minScale = @getDatasetValue 'minzoomscale', 'number', @minScale
        @maxScale = @getDatasetValue 'maxzoomscale', 'number', @maxScale
        @scale = @getDatasetValue 'zoomscale', 'number', @scale
        @prevScale = @scale
        @pinchScale = @scale
        @transitioning = false
        @hammer = propagating new Hammer.Manager(@el)

        @hammer.add new Hammer.Pinch()
        @hammer.add new Hammer.Pan()
        @hammer.add new Hammer.Tap
            event: 'doubletap'
            interval: 200
            threshold: 10
            taps: 2
        @hammer.on 'doubletap', @doubleTap.bind @
        @hammer.on 'panstart', @panStart.bind @
        @hammer.on 'panmove', @panMove.bind @
        @hammer.on 'panend', @panEnd.bind @
        @hammer.on 'pinchstart', @pinchStart.bind @
        @hammer.on 'pinchmove', @pinchMove.bind @
        @hammer.on 'pinchend', @pinchEnd.bind @

        @contextMenu = @contextMenu.bind @
        @el.addEventListener 'contextmenu', @contextMenu, false

        return

    destroy: ->
        @hammer.stop true
        @hammer.destroy()

        @reset()

        @el.removeEventListener 'contextmenu', @contextMenu

        return

    reset: ->
        return

    getDatasetValue: (key, type, defaultValue) ->
        value = @el.dataset[key]

        if type is 'number'
            value = +value
            value = defaultValue if isNaN value
        else if typeof value isnt type
            value = defaultValue

        value

    toggleScale: (x, y) ->
        if @scale is @minScale
            @scaleAtOrigin x, y, @maxScale, @transitionDuration
        else if @scale > @minScale
            @scaleAtOrigin x, y, @minScale, @transitionDuration

        return

    # Courtesy of https://cloudup.com/blog/how-we-made-zoom-on-mobile-using-css3-and-js
    #
    scaleAtOrigin: (x, y, scale, duration) ->
        rect = @el.getBoundingClientRect()

        # Find the cursor offset within the element.
        x -= rect.left
        y -= rect.top

        # Find the relative position.
        x = x / rect.width * 100
        y = y / rect.height * 100

        # Find the final position of the coordinate after scaling.
        finalX = x * scale / @scale
        finalY = y * scale / @scale

        # Find the difference between the initial and final position and add the difference to the current position.
        deltaX = @x + x - finalX
        deltaY = @y + y - finalY

        @x = deltaX
        @y = deltaY
        @prevScale = @scale
        @scale = scale
        @transitioning = true

        @x -= 50
        @y -= 50

        @transform
            el: @el
            x: @x
            y: @y
            prevScale: @prevScale
            scale: @scale
            duration: duration
            easing: @easing
        , =>
            @transitioning = false

            return

        return

    contextMenu: (e) ->
        e.preventDefault()
        e.stopPropagation()

        @toggleScale e.pageX, e.pageY

        return

    doubleTap: (e) ->
        @toggleScale e.center.x, e.center.y

        return

    panStart: (e) ->
        e.stopPropagation() if @scale isnt @minScale

        return

    panMove: (e) ->
        e.stopPropagation() if @scale isnt @minScale

        return

    panEnd: (e) ->
        e.stopPropagation() if @scale isnt @minScale

        return

    pinchStart: (e) ->
        e.stopPropagation()

        @pinchScale = @scale

        return

    pinchMove: (e) ->
        e.stopPropagation()

        @scaleAtOrigin e.center.x, e.center.y, @pinchScale * e.scale, 0

        return

    pinchEnd: (e) ->
        e.stopPropagation()

        if @scale > @maxScale
            @scaleAtOrigin e.center.x, e.center.y, @maxScale, @transitionDuration
        else if @scale < @minScale
            @scaleAtOrigin e.center.x, e.center.y, @minScale, @transitionDuration

        return

    transform: (options, callback) ->
        parentNode = options.el.parentNode
        scrollTop = -parentNode.scrollTop
        scrollLeft = -parentNode.scrollLeft
        x = options.x
        y = options.y
        scale = options.scale

        resetScroll = ->
            options.el.style.transform = "translate3d(#{scrollLeft}px, #{scrollTop}px, 0) scale3d(#{options.prevScale}, #{options.prevScale}, 1)"

            parentNode.scrollTop = 0
            parentNode.scrollLeft = 0

            return

        transitionEnd = ->
            options.el.removeEventListener 'transitionend', transitionEnd
            options.el.style.transition = 'none'

            if scale isnt 1
                options.el.style.transform = "translate3d(-50%, -50%, 0) scale3d(#{scale}, #{scale}, 1)"

                parentNode.style.overflow = 'scroll'
                parentNode.scrollTop = y / 100 * parentNode.offsetHeight
                parentNode.scrollLeft = x / 100 * parentNode.offsetWidth

            callback()

            return

        transform = ->
            if scale is 1
                options.el.style.transform = ''
            else
                options.el.style.transform = "translate3d(#{x}%, #{y}%, 0) scale3d(#{scale}, #{scale}, 1)"

            return

        resetScroll() if scrollLeft isnt 0 or scrollTop isnt 0

        if options.duration > 0
            options.el.addEventListener 'transitionend', transitionEnd, false
            options.el.style.transition = "transform #{options.easing} #{options.duration}ms"

            transform()
        else
            transform()
            callback()

        return
