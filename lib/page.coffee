module.exports = class Page
    constructor: (@el, @index = 0, @position = 0) ->
        @transformPosition = @position
        @scrolling = false

        @el.setAttribute 'data-versoindex', @index
        @el.addEventListener 'scroll', @scroll.bind(@), false

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
