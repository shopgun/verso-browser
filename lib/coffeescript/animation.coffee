module.exports = class Animation
    constructor: (@el) ->
        @run = 0

        return

    animate: (options = {}, callback = ->) ->
        x = options.x ? 0
        y = options.y ? 0
        scale = options.scale ? 1
        easing = options.easing ? 'ease'
        duration = options.duration ? 0
        run = ++@run
        transform = "translate3d(#{x}, #{y}, 0px) scale3d(#{scale}, #{scale}, 1)"

        if @el.style.transform is transform
            callback()
        else if duration > 0
            @el.addEventListener 'transitionend', =>
                return if run isnt @run

                @el.removeEventListener 'transitionend'
                @el.style.transition = 'none'

                callback()

                return
            , false

            @el.style.transition = "transform #{easing} #{duration}ms"
            @el.style.transform = transform
        else
            @el.style.transition = 'none'
            @el.style.transform = transform

            callback()

        @
