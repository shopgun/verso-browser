export default class Animation
    constructor: (@el) ->
        @run = 0

        return

    animate: (options = {}, callback = ->) ->
        x = options.x ? 0
        y = options.y ? 0
        scale = options.scale ? 1
        easing = options.easing ? 'ease-out'
        duration = options.duration ? 0
        run = ++@run
        transform = "translateX(#{x}) translateY(#{y}) scale(#{scale})"

        if @el.style.transform is transform
            callback()
        else if duration > 0
            transitionEnd = =>
                return if run isnt @run

                @el.removeEventListener 'transitionend', transitionEnd
                @el.style.transition = 'none'

                callback()

                return

            @el.addEventListener 'transitionend', transitionEnd, false

            @el.style.transition = "transform #{easing} #{duration}ms"
            @el.style.transform = transform
        else
            @el.style.transition = 'none'
            @el.style.transform = transform

            callback()

        @
