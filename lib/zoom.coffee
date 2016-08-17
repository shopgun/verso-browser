propagating = require 'propagating-hammerjs'
Events = require './events'
transform = require './transform'

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

        @x = @y = 0
        @easing = @getOption 'easing', 'string', @easing
        @minScale = @getOption 'minzoomscale', 'number', @minScale
        @maxScale = @getOption 'maxzoomscale', 'number', @maxScale
        @scale = @getOption 'zoomscale', 'number', @scale
        @startScale = @scale
        @transforming = false
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

    getOption: (key, type, defaultValue) ->
        value = @el.dataset[key]

        if type is 'number'
            value = +value
            value = defaultValue if isNaN value
        else if typeof value isnt type
            value = defaultValue

        value

    toggleScale: (x, y) ->
        if @scale is @minScale
            @scaleAtOrigin x, y, @maxScale
            @scaleAtEdges()
            @transform @transitionDuration, =>
                @enableScroll x, y

                return
        else if @scale > @minScale
            @disableScroll x, y

            @x = @y = 0
            @scale = @minScale

            @transform @transitionDuration

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

        @startScale = @scale

        @disableScroll()
        @scaleAtOrigin e.center.x, e.center.y, @startScale * e.scale, 0
        @transform()

        return

    pinchMove: (e) ->
        e.stopPropagation()

        @scaleAtOrigin e.center.x, e.center.y, @startScale * e.scale, 0
        @transform()

        return

    pinchEnd: (e) ->
        e.stopPropagation()

        x = @x
        y = @y
        scale = @scale

        if @scale > @maxScale
            @scale = @maxScale

            @scaleAtEdges()
        else if @scale <= @minScale
            @x = 0
            @y = 0
            @scale = @minScale

        if x isnt @x or y isnt @y or scale isnt @scale
            @transform @transitionDuration, =>
                @enableScroll() if @scale > @minScale

                return

        return

    disableScroll: (x, y) ->
        parentNode = @el.parentNode
        style = window.getComputedStyle @el
        childWidth = +style.width.replace 'px', ''
        childHeight = +style.height.replace 'px', ''
        scrollLeft = parentNode.scrollLeft
        scrollTop = parentNode.scrollTop

        @x -= (scrollLeft - @initialScrollLeft) / childWidth * 100
        @y += (@initialScrollTop - scrollTop) / childHeight * 100

        @transform()

        parentNode.scrollTop = 0
        parentNode.scrollLeft = 0
        parentNode.dataset.zoomscroll = false

        return

    enableScroll: ->
        rect = @el.getBoundingClientRect()
        parentNode = @el.parentNode
        plane = @getPlane()
        scrollLeft = Math.abs rect.left
        scrollTop = Math.abs rect.top

        @el.style.transform = "translate3d(#{plane.toX}%, #{plane.toY}%, 0) scale3d(#{@scale}, #{@scale}, 1)"

        parentNode.dataset.zoomscroll = true
        parentNode.scrollLeft = scrollLeft
        parentNode.scrollTop = scrollTop

        @initialScrollLeft = scrollLeft
        @initialScrollTop = scrollTop

        return

    maxEdge: (offset, width) ->
        -offset * (100 / width)

    minEdge: (offset, width, scale, outerWidth) ->
        @maxEdge(offset, width) - (width * scale - outerWidth) * (100 / width)

    # parent_width = 1000
    # child_width = 500
    # child_left = 250
    # scale = 3
    # transformed_child_width = 500 * 3 = 1500

    # 100% transform equals 500px

    # -50% (0px) => 500px overflow
    # 500px equals 100% transform
    # range -50% => -150%

    # max_x = -child_left*(100/child_width) = -50%
    # min_x = max_x - (transformed_child_width-parent_width)*(100/child_width)
    getPlane: ->
        plane =
            fromX: 0
            fromY: 0
            toX: 0
            toY: 0
        style = window.getComputedStyle @el
        parentNode = @el.parentNode
        parentWidth = parentNode.offsetWidth
        parentHeight = parentNode.offsetHeight
        childWidth = +style.width.replace 'px', ''
        childHeight = +style.height.replace 'px', ''
        offsetTop = (parentHeight - childHeight) / 2
        offsetLeft = (parentWidth - childWidth) / 2

        plane.toY = @maxEdge offsetTop, childHeight
        plane.fromY = @minEdge offsetTop, childHeight, @scale, parentHeight
        plane.toX = @maxEdge offsetLeft, childWidth
        plane.fromX = @minEdge offsetLeft, childWidth, @scale, parentWidth

        plane

    # Makes sure the coordinates don't exceed the plane.
    #
    scaleAtEdges: ->
        plane = @getPlane()

        @x = Math.min plane.toX, Math.max(@x, plane.fromX)
        @y = Math.min plane.toY, Math.max(@y, plane.fromY)

        @

    scaleAtOrigin: (x, y, scale) ->
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
        @scale = scale

        @

    transform: (duration, callback) ->
        @transforming = true

        transform @el, @x, @y, @scale, @easing, duration, =>
            @transforming = false

            callback() if typeof callback is 'function'

            return

        return
