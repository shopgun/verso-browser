Animation = require './animation'

module.exports = class Pages
    constructor: (@pages = []) ->
        @paused = false
        @queue = []

        return

    at: (i) ->
        @pages[i]

    count: ->
        @pages.length

    slice: (start, end) ->
        @pages.slice start, end

    toArray: ->
        @pages

    clear: ->
        @queue = []

        return

    pause: ->
        @paused = true

        return

    resume: ->
        @paused = false
        @run()

        return

    run: ->
        return if @paused is true or @queue.length is 0

        item = @queue[0]

        item.animation.on 'update', =>
            if item.isComplete() is true
                item.animation.pause()

                @queue.shift()
                @run()

            return
        item.animation.play()

        return

    transition: (from, to, transition = {}) ->
        isComplete = false
        isForward = to > from
        direction = if isForward then -1 else 1
        fromPage = @at from
        toPage = @at to
        fromTarget = 100 * direction
        toTarget = 0
        animation = new Animation()

        animation.on 'update', (delta, time) =>
            distance = 100 * (delta / (transition.baseDuration / 1000))
            distance += distance * Math.abs(transition.velocity) / 1000
            distance += @queue.length

            toPage.updatePosition toPage.position + distance * direction

            if (isForward and toPage.position <= 0) or (not isForward and toPage.position >= 0)
                toPage.updatePosition 0
                isComplete = true

            if fromPage?
                fromPage.updatePosition toPage.position + 100 * direction

            return

        animation.on 'render', (delta) ->
            if fromPage?
                fromPage.updateTransform fromPage.position

                if isComplete
                    fromPage.hide()
                else
                    fromPage.show()

            toPage.updateTransform toPage.position
            toPage.show()

            return

        @queue.push
            isComplete: -> isComplete
            animation: animation

        @run() if @queue.length is 1

        return
