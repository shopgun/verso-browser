module.exports = (el, x = 0, y = 0, scale = 1, easing = 'ease', duration = 0, callback) ->
    animate = ->
        el.style.transform = "translate3d(#{x}%, #{y}%, 0) scale3d(#{scale}, #{scale}, 1)"

        return

    completed = ->
        el.removeEventListener 'transitionend', completed
        el.style.transition = 'none'

        callback()

        return

    if duration > 0
        el.addEventListener 'transitionend', completed, false
        el.style.transition = "transform #{easing} #{duration}ms"

        animate()
    else
        animate()
        callback()

    return
