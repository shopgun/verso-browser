module.exports = class Page
    constructor: (@el, @index = 0, @position = 0) ->
        @transformPosition = @position
        @scrolling = false
        @zoomScale = 1

        @el.setAttribute 'data-versoindex', @index
        @el.addEventListener 'scroll', @scroll.bind(@), false

        # TODO: Generalize data-transition-* and support transform to begin with.
        # @transitions =
        #     start: @el.getAttribute 'data-transition-start'
        #     middle: @el.getAttribute 'data-transition-middle'
        #     end: @el.getAttribute 'data-transition-end'

        return

    scroll: ->
        clearTimeout @scrollTimeout

        @scrolling = true

        @scrollTimeout = setTimeout =>
            @scrolling = false
        , 200

        return

    mayZoom: ->
        @el.dataset.zoom is 'true'

    zoom: (x, y, zoomScale) ->
        console.log 'zoom', x, y, zoomScale

        el = @el.querySelector '.verso__scroll-child'

        if el?
            console.log zoomScale

            if zoomScale is 1
                x = 0
                y = 0

            el.style.transform = "scale3d(#{zoomScale}, #{zoomScale}, 1)"

            @zoomScale = zoomScale

        return

    updateTransform: (position) ->
        position = Math.max -100, position
        position = Math.min 100, position

        @el.style.transform = "translate3d(#{position}%, 0, 0)"

        @transformPosition = position

        @

    updatePosition: (position) ->
        @position = position

        @

    show: ->
        @el.style.visibility = 'visible'

        @

    hide: ->
        @el.style.visibility = 'hidden'

        @
