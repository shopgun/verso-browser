Events = require './events'

module.exports = class Verso extends Events
    defaults:
        keysPrev: [8, 33, 37, 38]
        keysNext: [13, 32, 34, 39, 40]
        transition: 'horizontal-slide'
        swipeDirection: 'horizontal'
        swipeTolerance: 60
        pageIndex: 0

    constructor: (@el, options = {}) ->
        super()

        for key, value of @defaults
            @[key] = options[key] ? value

        @pages = Array.prototype.slice.call @el.querySelectorAll('.verso__page'), 0
        @el.dataset.transition = @transition

        @go @pageIndex

        return

    go: (pageIndex) ->
        if isNaN(pageIndex) or pageIndex < 0 or pageIndex > @getPageCount() - 1
            throw new Error('Page index is not valid')

        @pageIndex = pageIndex
        @updateState()

    getPageCount: ->
        @pages.length

    updateState: ->
        @pages.forEach (el) ->
            console.log el
            el.dataset.state = ''

            return

        @pages[@pageIndex].dataset.state = 'current'
        @pages[@pageIndex - 1].dataset.state = 'previous' if @pageIndex > 0
        @pages[@pageIndex + 1].dataset.state = 'next' if @pageIndex + 1 < @getPageCount()

        if @pageIndex > 1
            @pages.slice(0, @pageIndex - 1).forEach (el) -> el.dataset.state = 'before'

        if @pageIndex + 2 < @getPageCount()
            @pages.slice(@pageIndex + 2).forEach (el) -> el.dataset.state = 'after'

        return
