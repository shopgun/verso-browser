propagating = require 'propagating-hammerjs'
Events = require './events'

module.exports = class Zoom extends Events
    defaults:
        transitionDuration: 220
        minScale: 1
        maxScale: 2.5
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
        rect = @el.getBoundingClientRect()

        if @scale is @minScale
            @scaleAtOrigin x, y, @maxScale, @transitionDuration
        else if @scale > @minScale
            @scaleAtOrigin x, y, @minScale, @transitionDuration

        return

    # Courtesy of https://cloudup.com/blog/how-we-made-zoom-on-mobile-using-css3-and-js
    #
    scaleAtOrigin: (x, y, scale, duration, overflow = false) ->
        rect = @el.getBoundingClientRect()
        parentWidth = @el.parentNode.offsetWidth
        parentHeight = @el.parentNode.offsetHeight

        # Find the cursor offset within the element.
        x -= rect.left
        y -= rect.top

        # Find the final position of the coordinate after scaling.
        finalX = x * scale / @scale
        finalY = y * scale / @scale

        # Find the difference between the initial and final position and add the difference to the current position.
        deltaX = @x + x - finalX
        deltaY = @y + y - finalY

        # if overflow is false
        #     if rect.width * scale < parentWidth
        #         deltaX = 0
        #     else
        #         maxX = (parentWidth - rect.width) / 2
        #         minX = maxX * -1

        #         console.log minX, maxX

        #         deltaX = Math.max minX, deltaX
        #         deltaX = Math.min maxX, deltaX

        #         console.log deltaX

            # if rect.height * scale < parentHeight
            #     deltaY = 0
            # else
            #     minY = -(parentHeight - rect.height) / 2
            #     maxY = minY * -1

            #     deltaY = Math.max minY, deltaY
            #     deltaY = Math.min maxY, deltaY

        @x = deltaX
        @y = deltaY
        @prevScale = @scale
        @scale = scale
        @transitioning = true

        @transform @el, @x, @y, @prevScale, @scale, duration, =>
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

    transform: (el, x, y, prevScale, scale, duration, callback) ->
        parentNode = el.parentNode
        scrollTop = -parentNode.scrollTop
        scrollLeft = -parentNode.scrollLeft

        resetScroll = ->
            el.style.transform = "translate3d(#{scrollLeft}px, #{scrollTop}px, 0) scale3d(#{prevScale}, #{prevScale}, 1)"

            parentNode.scrollTop = 0
            parentNode.scrollLeft = 0

            return

        resetTransform = ->
            if scale isnt 1
                el.style.transform = "translate3d(0, 0, 0) scale3d(#{scale}, #{scale}, 1)"

            parentNode.style.overflow = 'auto'
            parentNode.scrollTop = -y
            parentNode.scrollLeft = -x

            return

        transitionEnd = ->
            el.removeEventListener 'transitionend', transitionEnd
            el.style.transition = 'none'

            resetTransform()
            callback()

            return

        transform = ->
            if scale is 1
                el.style.transform = ''
            else
                el.style.transform = "translate3d(#{x}px, #{y}px, 0) scale3d(#{scale}, #{scale}, 1)"

            return

        resetScroll() if scrollLeft isnt 0 or scrollTop isnt 0

        # TODO: get min scale somehow.
        if scale > 1
            parentNode.style.overflow = 'scroll'
        else
            parentNode.style.overflow = 'hidden'

        if duration > 0
            el.addEventListener 'transitionend', transitionEnd, false
            el.style.transition = "all ease-in-out #{duration}ms"

            transform()
        else
            transform()
            callback()

        return
