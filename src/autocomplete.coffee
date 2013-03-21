URL_BASE = "http://dev.hel.fi:8000/api/v1/address/?format=jsonp"

class Location
    constructor: (@name, @coords) ->
    fetch_details: (callback, args) ->
        # Do nothing by default.
        callback(args, @)
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

class Autocompleter
    constructor: ->
        @.xhr = null
        @.timeout = null

    get_predictions: (query, callback, args) ->
        @.abort()
        timeout_handler = =>
            @timeout = null
            @.fetch_results()
        @.callback = callback
        @.callback_args = args
        @.query = query
        @timeout = window.setTimeout timeout_handler, 200

    abort: ->
        if @timeout
            window.clearTimeout @timeout
            @timeout = null
        if @xhr
            @xhr.abort()
            @xhr = null

class GeocoderCompleter extends Autocompleter
    fetch_results: ->
        @xhr = $.getJSON URL_BASE + "&callback=?",
            name: @.query
            limit: 10
        , (data) =>
            @xhr = null
            objs = data.objects
            loc_list = []
            for adr in objs
                coords = adr.location.coordinates
                loc = new Location adr.name, [coords[1], coords[0]]
                loc_list.push loc
            @.callback @.callback_args, loc_list

GOOGLE_URL_BASE = "http://dev.hel.fi:8000/google/"

class GoogleLocation extends Location
    constructor: (pred) ->
        @name = pred.description
        @info = pred
    fetch_details: (callback, args) ->
        url = GOOGLE_URL_BASE + "details/?callback=?"
        params = {reference: @info.reference}
        $.getJSON url, params, (data) =>
            res = data.result
            loc = res.geometry.location
            @coords = [loc.lat, loc.lng]
            callback args, @

class GoogleCompleter extends Autocompleter
    fetch_results: ->
        url = GOOGLE_URL_BASE + "autocomplete/?callback=?"
        area = citynavi.config.area
        location = area.center
        # FIXME
        radius = 12000
        data = {query: @.query, location: location.join(','), radius: radius}
        data['country'] = area.country
        @xhr = $.getJSON url, data, (data) =>
            @xhr = null
            preds = data.predictions
            loc_list = []
            for pred in preds
                city_name = pred.terms[1].value
                if city_name not in area.cities
                    continue
                loc = new GoogleLocation pred
                loc_list.push loc
            @.callback @.callback_args, loc_list

NOMINATIM_URL = "http://nominatim.openstreetmap.org/search/"

class OSMCompleter extends Autocompleter
    fetch_results: ->
        url = NOMINATIM_URL + "?json_callback=?"
        area = citynavi.config.area
        ne = area.bbox_ne
        sw = area.bbox_sw
        bbox = [sw[1], ne[0], ne[1], sw[0]]
        data =
            q: @.query
            format: "json"
            countrycodes: area.country
            limit: 10
            bounded: 1
            addressdetails: 1
            viewbox: bbox.join(',')
        @xhr = $.getJSON url, data, (data) =>
            @xhr = null
            loc_list = []
            for obj in data
                console.log obj
                name = obj.address.road + ", " + obj.address.city
                loc = new Location name, [obj.lat, obj.lon]
                loc_list.push loc
            @.callback @.callback_args, loc_list

geocoder = new GoogleCompleter()

test_completer = ->
    callback = (args, data) ->
        console.log data
    geocoder.get_predictions "Piccadilly", callback

#test_completer()

navigate_to = (loc) ->
    idx = location_history.add loc
    page = "#map-page?destination=#{ idx }"
    $.mobile.changePage page

render_autocomplete_results = (args, loc_list) ->
    $ul = args.$ul
    $ul.html ''
    for loc in loc_list
        $el = $("<li><a href='#map-page'>#{ loc.name }</a></li>")
        $el.data 'index', loc_list.indexOf(loc)
        $el.click (e) ->
            e.preventDefault()
            idx = $(this).data 'index'
            loc = loc_list[idx]
            loc.fetch_details navigate_to, loc
        $ul.append $el

    $ul.listview "refresh"
    $ul.trigger "updatelayout"

$(document).on "listviewbeforefilter", "#navigate-to-input", (e, data) ->
    val = $(data.input).val()
    $ul = $(this)
    if (!val)
        $ul.html ''
        return
    geocoder.get_predictions val, render_autocomplete_results, {$ul: $ul}
