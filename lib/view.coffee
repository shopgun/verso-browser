Events = require './events'

module.exports = class Verso extends Events
    defaults:
        transition: 'horizontal-slide'
        pageIndex: 0

    initialized: false

    constructor: (@el, options = {}) ->
        super()

        for key, value of @defaults
            @[key] = options[key] ? value

        @pages = Array.prototype.slice.call @el.querySelectorAll('.verso__page'), 0

        return

    init: ->
        return if @initialized is true

        @trigger 'beforeInit'

        @el.dataset.ready = 'true'
        @el.dataset.transition = @transition
        @el.setAttribute 'tabindex', -1
        @el.focus()

        @updateState()

        @initialized = true

        @trigger 'init'

        @

    go: (pageIndex) ->
        return if isNaN(pageIndex) or pageIndex < 0 or pageIndex > @getPageCount() - 1

        from = @pageIndex
        to = pageIndex

        @trigger 'beforeChange', from, to

        @pageIndex = to
        @updateState()

        @trigger 'change', from, to

        return

    prev: ->
        @go @pageIndex - 1

        return

    next: ->
        @go @pageIndex + 1

        return

    getPageCount: ->
        @pages.length

    updateState: ->
        @pages[@pageIndex].dataset.state = 'current'
        @pages[@pageIndex - 1].dataset.state = 'previous' if @pageIndex > 0
        @pages[@pageIndex + 1].dataset.state = 'next' if @pageIndex + 1 < @getPageCount()

        if @pageIndex > 1
            @pages.slice(0, @pageIndex - 1).forEach (el) -> el.dataset.state = 'before'

        if @pageIndex + 2 < @getPageCount()
            @pages.slice(@pageIndex + 2).forEach (el) -> el.dataset.state = 'after'

        return
