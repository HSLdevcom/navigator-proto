URL_BASE = "http://dev.hel.fi/geocoder/v1/address/"

class Location
    constructor: (@name, @coords) ->
    fetch_details: (callback, args) ->
        # Do nothing by default.
        callback(args, @)
    to_json: ->
        return {name: @name, coords: @coords}
    @from_json: (d) ->
        return new Location d.name, d.coords

window.Location = Location

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

class Prediction
    select: ->
        $.mobile.showPageLoadingMsg()
        if @type == "location"
            @location.fetch_details navigate_to_location, @location
        else
            args = {callback: navigate_to_poi, location: citynavi.get_source_location()}
            if not args.location?
                alert "The device hasn't provided its current location. Using region center instead."
                args.location = citynavi.config.area.center
            @category.fetch_pois args
    render: ->
        icon_html = ''
        name = @name
        if @type == "category"
            dest_page = "select-nearest"
            icon_html = @category.get_icon_html()
            name = "Closest " + name.toLowerCase()
        else
            dest_page = "map-page"
        $el = $("<li><a href='##{dest_page}'>#{icon_html}#{name}</a></li>")
        $el.find('img').height(20).addClass('ui-li-icon')
        return $el

class LocationPrediction extends Prediction
    constructor: (loc) ->
        @location = loc
        @type = "location"
        @name = loc.name

class CategoryPrediction extends Prediction
    constructor: (cat) ->
        @category = cat
        @type = "category"
        @name = cat.name

class Autocompleter

class RemoteAutocompleter extends Autocompleter
    constructor: ->
        @.xhr = null
        @.timeout = null
        @.remote = true

    get_predictions: (query, callback, args) ->
        @.abort()
        timeout_handler = =>
            @timeout = null
            @.fetch_results()
        @.callback = callback
        @.callback_args = args
        @.query = query
        @timeout = window.setTimeout timeout_handler, 200

    submit_location_predictions: (loc_list) ->
        pred_list = []
        for loc in loc_list
            pred_list.push new LocationPrediction(loc)
        @.callback @.callback_args, pred_list

    abort: ->
        if @timeout
            window.clearTimeout @timeout
            @timeout = null
        if @xhr
            @xhr.abort()
            @xhr = null

class GeocoderCompleter extends RemoteAutocompleter
    fetch_results: ->
        @xhr = $.getJSON URL_BASE,
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
            @.submit_location_predictions loc_list

GOOGLE_URL_BASE = "http://dev.hel.fi/geocoder/google/"

class GoogleLocation extends Location
    constructor: (pred) ->
        @name = pred.description
        @info = pred
    fetch_details: (callback, args) ->
        url = GOOGLE_URL_BASE + "details/"
        params = {reference: @info.reference}
        $.getJSON url, params, (data) =>
            res = data.result
            loc = res.geometry.location
            @coords = [loc.lat, loc.lng]
            callback args, @

class GoogleCompleter extends RemoteAutocompleter
    fetch_results: ->
        url = GOOGLE_URL_BASE + "autocomplete/"
        area = citynavi.config.area
        location = citynavi.get_source_location_or_area_center()
        # FIXME
        radius = 12000
        data = {query: @query, location: location.join(','), radius: radius}
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
            @.submit_location_predictions loc_list

NOMINATIM_URL = "http://nominatim.openstreetmap.org/search/"

class OSMCompleter extends RemoteAutocompleter
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
            @.submit_location_predictions loc_list

class POICategoryCompleter extends Autocompleter
    get_predictions: (query, callback, args) ->
        if not query.length
            return
        pred_list = []
        q = query.toLowerCase()
        for cat in citynavi.poi_categories
            ss = cat.name[0...q.length].toLowerCase()
            if ss != q
                continue
            pred_list.push new CategoryPrediction(cat)
        callback args, pred_list

supported_completers =
    poi_categories: new POICategoryCompleter
    geocoder: new GeocoderCompleter
    google: new GoogleCompleter
    osm: new OSMCompleter

generate_area_completers = (area) ->
    (supported_completers[id] for id in area.autocompletion_providers)

completers = generate_area_completers citynavi.config.area

test_completer = ->
    callback = (args, data) ->
        console.log data
    geocoder.get_predictions "Piccadilly", callback

#test_completer()

navigate_to_location = (loc) ->
    idx = location_history.add loc
    page = "#map-page?destination=#{ idx }"
    citynavi.poi_list = []
    $.mobile.changePage page

navigate_to_poi = (poi_list) ->
    poi = poi_list[0]
    loc = new Location poi.name, poi.coords
    idx = location_history.add loc
    page = "#map-page?destination=#{ idx }"
    citynavi.poi_list = poi_list
    $.mobile.changePage page

get_all_predictions = (input, callback, callback_args) ->
    input = $.trim input
    for c in completers
        if c.remote
            # Do not do remote autocompletion if less than 3 characters
            # input.
            if input.length < 3
                continue
        c.get_predictions input, callback, callback_args

pred_list = []

render_autocomplete_results = (args, new_preds) ->
    $ul = args.$ul
    pred_list = pred_list.concat new_preds
    for pred in pred_list
        if pred.rendered
            continue
        $el = pred.render()
        $el.data 'index', pred_list.indexOf(pred)
        pred.rendered = true
        $el.click (e) ->
            e.preventDefault()
            idx = $(this).data 'index'
            pred = pred_list[idx]
            pred.select()
        $ul.append $el
    $ul.listview "refresh"
    $ul.trigger "updatelayout"
        
$(document).on "listviewbeforefilter", "#navigate-to-input", (e, data) ->
    val = $(data.input).val()
    $ul = $(this)
    $ul.html('')
    pred_list = []
    get_all_predictions val, render_autocomplete_results, {$ul: $ul}
