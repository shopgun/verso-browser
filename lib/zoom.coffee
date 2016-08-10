propagating = require 'propagating-hammerjs'
Events = require './events'

module.exports = class Zoom extends Events
    defaults:
        transitionDuration: 220

    constructor: (@el, options = {}) ->
        super()

        for key, value of @defaults
            @[key] = options[key] ? value

        @x = 0
        @y = 0
        @scale = @getScale()
        @prevScale = @scale
        @pinchScale = @scale
        @minScale = @getMinScale()
        @maxScale = @getMaxScale()
        @transitioning = false
        @hammer = propagating new Hammer.Manager(@el)

        @hammer.add new Hammer.Pinch()
        @hammer.add new Hammer.Pan()
        @hammer.add new Hammer.Tap
            event: 'doubletap'
            interval: 200
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

        @el.removeEventListener 'contextmenu', @contextMenu

        return

    getScale: ->
        value = +@el.dataset.zoomscale

        if isNaN value
            1
        else
            value

    getMinScale: ->
        value = +@el.dataset.minzoomscale

        if isNaN value
            1
        else
            value

    getMaxScale: ->
        value = +@el.dataset.maxzoomscale

        if isNaN value
            1
        else
            value

    toggleScale: (x, y) ->
        if @scale is @minScale
            @scaleAtOrigin x, y, @maxScale, @transitionDuration
        else if @scale > @minScale
            @scaleAtOrigin x, y, @minScale, @transitionDuration

        return

    scaleAtOrigin: (x, y, scale, duration) ->
        rect = @el.getBoundingClientRect()
        x -= rect.left
        y -= rect.top
        xf = x * scale / @scale
        yf = y * scale / @scale
        dx = @x + x - xf
        dy = @y + y - yf

        dx = dy = 0 if scale is @minScale

        @x = dx
        @y = dy
        @prevScale = @scale
        @scale = scale
        @transitioning = true

        @transform @el, @x, @y, @scale, duration, =>
            @transitioning = false

            return

        return

    transform: (el, x, y, scale, duration, callback) ->
        if duration > 0
            parentNode = el.parentNode
            scrollTop = -parentNode.scrollTop
            scrollLeft = -parentNode.scrollLeft

            el.style.transform = "translate3d(#{scrollLeft}px, #{scrollTop}px, 0) scale3d(#{@prevScale}, #{@prevScale}, 1)"

            parentNode.style.overflow = 'hidden'
            parentNode.scrollTop = 0
            parentNode.scrollLeft = 0

            end = =>
                el.removeEventListener 'transitionend', end

                el.style.transition = 'none'
                el.style.transform = "translate3d(0, 0, 0) scale3d(#{scale}, #{scale}, 1)"
                parentNode.style.overflow = 'auto'
                parentNode.scrollTop = -y
                parentNode.scrollLeft = -x

                callback()

                return

            el.addEventListener 'transitionend', end, false
            el.style.transition = "transform ease-in-out #{duration}ms"
        else
            callback()

        el.style.transform = "translate3d(#{x}px, #{y}px, 0) scale3d(#{scale}, #{scale}, 1)"

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
