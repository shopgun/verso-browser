module.exports = class Progress
    constructor: (@verso) ->
        @el = @verso.el.querySelector '.verso-progress__inner'

        @verso.on 'change', @updateProgress.bind(@)

        @updateProgress()

        return

    updateProgress: ->
        progress = parseInt (@verso.pageIndex + 1) / @verso.getPageCount() * 100

        @el.style.width = "#{progress}%"

        return
