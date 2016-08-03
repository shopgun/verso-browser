Events = require './events'

requestAnimationFrame = window.requestAnimationFrame or window.mozRequestAnimationFrame or window.webkitRequestAnimationFrame or window.msRequestAnimationFrame
cancelAnimationFrame = window.cancelAnimationFrame or window.mozCancelAnimationFrame or window.webkitCancelAnimationFrame or window.msCancelAnimationFrame

module.exports = class Animation extends Events
    constructor: ->
        super()

        @then = null
        @now = null
        @delta = null
        @paused = false

        return

    play: ->
        @paused = false
        @then = @time()
        @frame()

        return

    pause: ->
        @paused = true

        cancelAnimationFrame @animationFrame

        return

    frame: (time) ->
        return if @paused is true

        @setDelta()
        @trigger 'update', @delta, time
        @trigger 'render', @delta, time
        @animationFrame = requestAnimationFrame @frame.bind(@)

        return

    setDelta: ->
        @now = @time()
        @delta = (@now - @then) / 1000 # Seconds since last frame.
        @then = @now

        return

    time: ->
        if window.performance.now
            performance.now() + performance.timing.navigationStart
        else
            Date.now()
