module.exports = class Navigation
    constructor: (@verso) ->
        @prevEl = @verso.el.querySelector '.verso__navigation[data-direction="previous"]'
        @nextEl = @verso.el.querySelector '.verso__navigation[data-direction="next"]'

        @verso.on 'change', @updateNav.bind(@)

        @bindEvents()
        @updateNav()

        return

    bindEvents: ->
        @prevEl.addEventListener 'click', => @verso.prev()
        @nextEl.addEventListener 'click', => @verso.next()

        return

    updateNav: ->
        index = @verso.pageIndex
        count = @verso.getPageCount()

        @prevEl.style.opacity = if index is 0 then 0 else 1
        @nextEl.style.opacity = if index is count - 1 then 0 else 1

        return
