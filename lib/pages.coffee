requestAnimationFrame = window.requestAnimationFrame or window.mozRequestAnimationFrame or window.webkitRequestAnimationFrame or window.msRequestAnimationFrame

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

        requestAnimationFrame @step.bind(@)

        return

    getPositionChange: (velocity = 1) ->
        base = 2.3
        change = base

        change += @queue.length
        change *= velocity

        change

    step: ->
        return if @paused is true or @queue.length is 0

        item = @queue[0]
        positionDirection = if item.isForward then -1 else 1
        positionChange = @getPositionChange() * positionDirection
        fromPosition = if item.fromPage? then item.fromPage.position else 0
        toPosition = if item.toPage? then item.toPage.position else 0
        fromTarget = 100 * positionDirection
        toTarget = 0
        isComplete = false

        toPosition += positionChange
        fromPosition = toPosition + fromTarget

        if (item.isForward and toPosition <= 0) or (not item.isForward and toPosition >= 0)
            fromPosition = fromTarget
            toPosition = 0
            isComplete = true

        if item.fromPage?
            item.fromPage.updatePosition fromPosition
            item.fromPage.updateTransform fromPosition

            if isComplete
                item.fromPage.hide()
            else
                item.fromPage.show()
        item.toPage.updatePosition toPosition
        item.toPage.updateTransform toPosition
        item.toPage.show()

        @queue.shift() if isComplete is true

        requestAnimationFrame @step.bind(@)

        return

    transition: (from, to) ->
        @queue.push
            isForward: to > from
            fromPage: @at from
            toPage: @at to

        requestAnimationFrame @step.bind(@)

        return
