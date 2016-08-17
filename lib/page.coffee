Events = require './events'
Zoom = require './zoom'

module.exports = class Page extends Events
    constructor: (@el, @index = 0, @position = 0) ->
        super()

        @transformPosition = @position
        @scrollable = @el.dataset.scroll is 'true'
        @scrolling = false
        @shown = false
        @state = null
        @zoom = null

        @el.setAttribute 'data-versoindex', @index
        @el.addEventListener 'scroll', @scroll.bind(@), false if @scrollable is true
        @el.addEventListener 'mousewheel', @mousewheel.bind(@), false

        @on 'statechange', @stateChange.bind(@), false

        # TODO: Generalize data-transition-* and support `translate` to begin with.
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

    mousewheel: (e) ->
        e.preventDefault() if e.deltaX is 0 and e.deltaY is 0

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

    updateState: (state) ->
        if @state isnt state
            @el.dataset.state = state
            @state = state

            @trigger 'statechange', state

        @

    stateChange: (state) ->
        if state is 'current'
            zoomEl = @el.querySelector '.verso__zoom'

            @zoom = new Zoom zoomEl if zoomEl?

            @el.setAttribute 'aria-hidden', false
        else
            if @zoom?
                @zoom.destroy()
                @zoom = null

            @el.setAttribute 'aria-hidden', true

        return

    show: ->
        if @shown is false
            @el.style.visibility = 'visible'

            @shown = true

        @

    hide: ->
        if @shown is true
            @el.style.visibility = 'hidden'

            @shown = false

        @
