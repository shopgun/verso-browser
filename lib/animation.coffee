Events = require './events'

requestAnimationFrame = window.requestAnimationFrame or window.mozRequestAnimationFrame or window.webkitRequestAnimationFrame or window.msRequestAnimationFrame or (callback) -> window.setTimeout callback, 1000 / 60

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

        return

    frame: (time) ->
        return if @paused is true

        @setDelta()

        @trigger 'update', @delta, time
        @trigger 'render', @delta, time

        requestAnimationFrame @frame.bind(@)

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
