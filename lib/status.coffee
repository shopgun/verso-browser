module.exports = class Status
    constructor: (@verso, @formatter) ->
        @el = @verso.el.querySelector '.verso__status'

        @verso.on 'change', @updateStatus.bind(@)

        @updateStatus()

        return

    updateStatus: ->
        index = @verso.pageIndex
        count = @verso.getPageCount()
        el = @verso.pages[index]
        formatter = if typeof @formatter is 'function' then @formatter else @defaultFormatter
        value = formatter el, index, count

        @el.textContent = value

        return

    defaultFormatter: (el, index, count) ->
        "#{index + 1} / #{count}"
