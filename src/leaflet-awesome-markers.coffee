#
#  Leaflet.AwesomeMarkers, a plugin that adds colorful iconic markers for Leaflet, based on the Font Awesome icons
#  (c) 2012-2013, Lennard Voogdt
#
#  http://leafletjs.com
#  https://github.com/lvoogdt
#
((window, document, undefined_) ->
    #
    # * Leaflet.AwesomeMarkers assumes that you have already included the Leaflet library.
    #
    L.AwesomeMarkers = {}
    L.AwesomeMarkers.version = "1.0"
    L.AwesomeMarkers.Icon = L.Icon.extend(
        options:
            iconSize: [35, 45]
            iconAnchor: [17, 42]
            popupAnchor: [1, -32]
            shadowAnchor: [10, 12]
            shadowSize: [36, 16]
            className: "awesome-marker"
            icon: "home"
            color: "blue"
            iconColor: "white"

        initialize: (options) ->
            options = L.setOptions(this, options)

        createIcon: ->
            div = document.createElement("div")
            options = @options
            div.innerHTML = @_createInner()  if options.icon
            div.style.backgroundPosition = (-options.bgPos.x) + "px " + (-options.bgPos.y) + "px"  if options.bgPos
            @_setIconStyles div, "icon-" + options.color
            div

        _createInner: ->
            if @options.svg?
                return "<img src='#{@options.svg}' height='18' style='margin-top: 8px; -webkit-filter: invert(1);'>"
            if @options.icon.slice(0, 5) is "icon-"
                iconClass = @options.icon
            else
                iconClass = "icon-" + @options.icon
            return "<i class='" + iconClass + ((if @options.spin then " icon-spin" else "")) + ((if @options.iconColor then " icon-" + @options.iconColor else "")) + "'></i>"

        _setIconStyles: (img, name) ->
            options = @options
            size = L.point(options[(if name is "shadow" then "shadowSize" else "iconSize")])
            anchor = undefined
            if name is "shadow"
                anchor = L.point(options.shadowAnchor or options.iconAnchor)
            else
                anchor = L.point(options.iconAnchor)
            anchor = size.divideBy(2, true)  if not anchor and size
            img.className = "awesome-marker-" + name + " " + options.className
            if anchor
                img.style.marginLeft = (-anchor.x) + "px"
                img.style.marginTop = (-anchor.y) + "px"
            if size
                img.style.width = size.x + "px"
                img.style.height = size.y + "px"

        createShadow: ->
            div = document.createElement("div")
            options = @options
            @_setIconStyles div, "shadow"
            div
    )
    L.AwesomeMarkers.icon = (options) ->
        new L.AwesomeMarkers.Icon(options)
) this, document
