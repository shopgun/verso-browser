module.exports = class PageSpread
    constructor: (@el, @options = {}) ->
        @visibility = 'gone'
        @positioned = false
        @active = false
        @pageIds = @options.pageIds
        @width = @options.width
        @left = @options.left
        @maxZoomScale = @options.maxZoomScale

        return

    isZoomable: ->
        @getMaxZoomScale() > 1

    getContentEl: ->
        @el.querySelector '.verso-page-spread__content'

    getPageIds: ->
        @pageIds

    getWidth: ->
        @width

    getLeft: ->
        @left

    getMaxZoomScale: ->
        @maxZoomScale

    getVisibility: ->
        @visibility

    setVisibility: (visibility) ->
        if @visibility isnt visibility
            @el.style.display = if visibility is 'visible' then 'block' else 'none'

            @visibility = visibility

        @

    position: ->
        if @positioned is false
            @el.style.left = "#{@getLeft()}%"

            @positioned = true

        @

    activate: ->
        @active = true
        @el.dataset.active = true

        return

    deactivate: ->
        @active = false
        @el.dataset.active = false

        return
