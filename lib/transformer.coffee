Impetus = require 'impetus'

module.exports = class Transformer
    constructor: (@el) ->
        @options = @getOptions()
        @hammer = new Hammer.Manager @el
        @hammer.add new Hammer.Pinch()
        @hammer.add new Hammer.Pan()
        @hammer.add new Hammer.Tap
            event: 'doubletap'
            interval: 200
            taps: 2
        @hammer.on 'doubletap', @doubleTap.bind @
        @hammer.on 'panmove', @panMove.bind @
        @hammer.on 'pinchstart', @pinchStart.bind @
        @hammer.on 'pinchmove', @pinchMove.bind @
        @hammer.on 'pinchend', @pinchEnd.bind @

        @contextMenu = @contextMenu.bind @
        @el.addEventListener 'contextmenu', @contextMenu, false

        return

    destroy: ->
        @hammer.stop true
        @hammer.destroy()

        @el.removeEventListener 'contextmenu', @contextMenu

        return

    getOptions: ->
        {}

    toggleZoom: (x, y) ->


    contextMenu: (e) ->
        e.preventDefault()
        e.stopPropagation()

        @toggleZoom e.pageX, e.pageY

        return

    doubleTap: (e) ->
        @toggleZoom e.center.x, e.center.y

        return

    panMove: (e) ->
        return

    pinchStart: (e) ->
        return if @pan.active is true or @pages.at(@pageIndex).scrollable is true
        return if @pages.queueCount() > 0

        @pinch.active = true
        @pinch.object = @pages.at(@pageIndex). e.target

        return

    pinchMove: (e) ->
        return if @pinch.active isnt true

        @pinch.manipulation.pinch
            x: e.center.x
            y: e.center.y
            distance: e.distance
            scale: e.scale

        return

    pinchEnd: (e) ->
        return if @pinch.active isnt true

        page = @pages.at @pageIndex

        if page.zoomScale > @maxZoomScale
            page.zoom e.center.x, e.center.y, @maxZoomScale
        else if page.zoomScale < 1
            page.zoom e.center.x, e.center.y, 1

        @pinch.active = false

        return
