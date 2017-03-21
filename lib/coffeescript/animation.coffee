module.exports = class Animation
    constructor: (@el) ->
        @run = 0

        return

    transform: (x, y, scale) ->
        @el.style.transform = "translate3d(#{x}, #{y}, 0) scale3d(#{scale}, #{scale}, 1)"

        @

    animate: (options = {}, callback) ->
        el = @el
        x = options.x ? 0
        y = options.y ? 0
        scale = options.scale ? 1
        easing = options.easing ? 'ease'
        duration = options.duration ? 0
        run = ++@run

        completed = =>
            return if run isnt @run

            el.removeEventListener 'transitionend', completed
            el.style.transition = 'none'

            callback() if typeof callback is 'function'

            return

        if duration > 0
            el.addEventListener 'transitionend', completed, false
            el.style.transition = "transform #{easing} #{duration}ms"

            @transform x, y, scale
        else
            @transform x, y, scale

            callback() if typeof callback is 'function'

        @
