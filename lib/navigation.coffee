module.exports = class Navigation
    constructor: (@verso) ->
        @prevEl = @verso.el.querySelector '.verso__navigation[data-direction="previous"]'
        @nextEl = @verso.el.querySelector '.verso__navigation[data-direction="next"]'

        @prevEl.addEventListener 'click', => @verso.prev()
        @nextEl.addEventListener 'click', => @verso.next()

        @verso.on 'change', @updateNav.bind(@)

        @updateNav()

        return

    updateNav: ->
        index = @verso.pageIndex
        count = @verso.pages.count()

        @prevEl.dataset.active = index > 0
        @nextEl.dataset.active = index < count - 1

        return
