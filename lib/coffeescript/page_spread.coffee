module.exports = class PageSpread
    constructor: (@el, @options = {}) ->
        @visibility = 'gone'
        @positioned = false
        @active = false
        @id = @options.id
        @pageIds = @options.pageIds
        @width = @options.width
        @left = @options.left
        @maxZoomScale = @options.maxZoomScale

        return

    isZoomable: ->
        @getMaxZoomScale() > 1 and @getEl().dataset.zoomable isnt 'false'

    getEl: ->
        @el

    getOverlayEls: ->
        @el.querySelectorAll '.verso-page-spread__overlay'

    getPageEls: ->
        @el.querySelectorAll '.verso__page'

    getRect: ->
        @getEl().getBoundingClientRect()

    getContentRect: ->
        pageEls = @getPageEls()
        rect =
            top: null
            left: null
            right: null
            bottom: null
            width: null
            height: null

        for pageEl in pageEls
            pageRect = pageEl.getBoundingClientRect()

            rect.top = pageRect.top if pageRect.top < rect.top or not rect.top?
            rect.left = pageRect.left if pageRect.left < rect.left or not rect.left?
            rect.right = pageRect.right if pageRect.right > rect.right or not rect.right?
            rect.bottom = pageRect.bottom if pageRect.bottom > rect.bottom or not rect.bottom?

        rect.top = rect.top ? 0
        rect.left = rect.left ? 0
        rect.right = rect.right ? 0
        rect.bottom = rect.bottom ? 0
        rect.width = rect.right - rect.left
        rect.height = rect.bottom - rect.top

        rect

    getId: ->
        @id

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
