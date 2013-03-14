URL_BASE = "http://dev.hel.fi:8000/api/v1/address/?format=jsonp"

class Location
    constructor: (@name, @coords) ->
    to_json: ->
        return {name: @name, coords: @coords}
    @from_json: (d) ->
        return new Location d.name, d.coords

class LocationHistory
    constructor: (@ls_id) ->
        s = localStorage[@ls_id]
        if s
            @array = JSON.parse s
        else
            @array = []
        @history = []
        for l in @array
            loc = Location.from_json l
            @history.push loc

    add: (loc) ->
        @array.push loc.to_json()
        @history.push loc
        localStorage[@ls_id] = JSON.stringify @array

    get: (id) ->
        return @history[id]

    clear: ->
        @array = []
        @history = []
        localStorage.removeItem @ls_id

window.location_history = new LocationHistory "city-navigator-history"

$(document).on "listviewbeforefilter", "#navigate-to-input", (e, data) ->
    console.log "autocomplete"
    val = $(data.input).val()
    console.log val
    if (!val)
        return
    $ul = $(this)
    $ul.html "<li><div class='ui-loader'><span class='ui-icon ui-icon-loading'></span></div></li>"
    $ul.listview "refresh"
    $.getJSON URL_BASE + "&callback=?",
        name: val
        limit: 10
    , (data) ->
        objs = data.objects
        html = ''
        for adr in objs
            coords = adr.location.coordinates
            link = "#map-page?destination=#{ coords[1]},#{ coords[0] }"
            html += "<li><a href=\"#{ link }\">" + adr.name + "</a></li>"
        $ul.html html
        $ul.listview "refresh"
        $ul.trigger "updatelayout"
