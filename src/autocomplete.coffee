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
        return @history.length - 1

    get: (id) ->
        return @history[id]

    clear: ->
        @array = []
        @history = []
        localStorage.removeItem @ls_id

window.location_history = new LocationHistory "city-navigator-history"

navigate_to = (loc) ->
    idx = location_history.add loc
    page = "#map-page?destination=#{ idx }"
    $.mobile.changePage page

autocomplete_xhr = null
autocomplete_timeout = null

fetch_autocomplete_results = (query, $ul) ->
    autocomplete_timeout = null
    $.getJSON URL_BASE + "&callback=?",
        name: query
        limit: 10
    , (data) ->
        objs = data.objects
        autocomplete_locs = []
        $ul.html ''
        for adr in objs
            $el = $("<li><a href='#map-page'>#{ adr.name }</a></li>")
            $el.data 'index', objs.indexOf(adr)
            $el.click (e) ->
                e.preventDefault()
                idx = $(this).data 'index'
                adr = objs[idx]
                coords = adr.location.coordinates
                loc = new Location adr.name, [coords[1], coords[0]]
                navigate_to loc
            $ul.append $el

        $ul.listview "refresh"
        $ul.trigger "updatelayout"

abort_autocomplete = ->
    if autocomplete_timeout
        window.clearTimeout autocomplete_timeout
        autocomplete_timeout = null
    if autocomplete_xhr
        autocomplete_xhr.abort()
        autocomplete_xhr = null


$(document).on "listviewbeforefilter", "#navigate-to-input", (e, data) ->
    val = $(data.input).val()
    if (!val)
        return
    $ul = $(this)
    abort_autocomplete()
    autocomplete_timeout = window.setTimeout fetch_autocomplete_results, 200, val, $ul
