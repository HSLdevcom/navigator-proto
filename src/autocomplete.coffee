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

# Locations are added to the history when user selects a location or POI as a
# navigation target. Last entry in the history is currently used for routing.
# History is also stored to the local storage (local storage is a HTML5 feature)
class LocationHistory
    constructor: (@ls_id) ->
        # Try to get history from the local storage. If there is no history,
        # just create empty arrays where locations will be added to.
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

# This is used in pagebeforechange event handler in the routing.coffee.
# Locations are added to the history when user selects a location or POI
# as a navigation target.
window.location_history = new LocationHistory "city-navigator-history"

class Prediction
    select: ($input, $ul) ->
        if @type == "location"
            coords = @location.coords
            if (not coords?) or (coords[0]? and coords[1]?)
                $.mobile.showPageLoadingMsg()
                # Call fetch_details that by default does nothing but for GoogleLocation gets
                # the location coordinates. The fetch_details function will call navigate_to_location
                # function defined later in this file with the @location as a parameter.
                @location.fetch_details navigate_to_location, @location
            else
                $input.val("#{@name} ")
                $input.focus()
                $input.trigger("keyup")
        else
            $.mobile.showPageLoadingMsg()
            # Fetch POIs corresponding the category (that has been set in sub class constructor) by
            # calling fetch_pois function defined for POICategory class in poi.coffee that will
            # eventually call navigate_to_poi function that will show map page where the POIs and
            # the route to the closest POI is shown.
            args = {callback: navigate_to_poi, location: citynavi.get_source_location()}
            if not args.location?
                alert "The device hasn't provided its current location. Using region center instead."
                args.location = citynavi.config.center
            @category.fetch_pois args
    render: -> # create the list element
        icon_html = ''
        name = @name
        if @type == "category" # Prediction is for a category
            dest_page = "select-nearest"
            icon_html = @category.get_icon_html()
            name = "Closest " + name.toLowerCase() # For example, "Closest library"
        else
            dest_page = "map-page"
        if @location?.icon?
            icon_html = "<img src='#{@location.icon}'>"
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
        @xhr = null
        @timeout = null
        @remote = true

    # Get predictions but use timeout of 200 milliseconds before making remote
    # fetch and also if previous timeout has been set but it has not yet completed,
    # then abort it before setting the new one.
    get_predictions: (query, callback, args) ->
        @abort()
        timeout_handler = =>
            @timeout = null
            @fetch_results()
        @callback = callback
        @callback_args = args
        @query = query
        @timeout = window.setTimeout timeout_handler, 200

    # Called when there are results from the remote autocompleter service.
    # Callback is the render_autocomplete_results function and the callback_args
    # is the list that will be shown to the user.
    submit_location_predictions: (loc_list) ->
        pred_list = []
        for loc in loc_list
            pred_list.push new LocationPrediction(loc)
        @callback @callback_args, pred_list

    submit_prediction_failure: () ->
        @callback @callback_args, []

    # Abort the timeout that would have caused fetch_results call.
    abort: ->
        if @timeout
            window.clearTimeout @timeout
            @timeout = null
        if @xhr
            @xhr.abort()
            @xhr = null

# GeocoderCompleter uses the geocoder at the dev.hel.fi server.
class GeocoderCompleter extends RemoteAutocompleter
    fetch_results: ->
        if /\d/.test @query
            @fetch_addresses()
        else
            @fetch_streets()

    fetch_addresses: ->
        # Get maximum 10 predictions for the user input (@query) from the
        # dev.hel.fi geocoder.
        @xhr = $.getJSON URL_BASE,
            name: @query
            limit: 10
        @xhr.always () ->
            @xhr = null
        @xhr.fail () =>
            @submit_prediction_failure()
        @xhr.done (data) =>
            objs = data.objects
            loc_list = []
            # Create Location object of the each received data object,
            # add it to the the list, and finally call submit_location_predictions
            for adr in objs
                coords = adr.location.coordinates
                loc = new Location adr.name, [coords[1], coords[0]]
                loc_list.push loc
            # submit_location_predictions function is defined in RemoteAutocompleter
            @submit_location_predictions loc_list

    fetch_streets: ->
        @xhr = $.getJSON URL_BASE,
            name: @query
            limit: 10
            distinct_streets: true
        @xhr.always () ->
            @xhr = null
        @xhr.fail () =>
            @submit_prediction_failure()
        @xhr.done (data) =>
            objs = data.objects
            loc_list = []
            loc_dict = {}
            for street in objs
                strt = $.trim street.street
                continue if strt of loc_dict
                loc_dict[strt] = true
                loc = new Location strt, [null, null]
                loc_list.push loc
            if loc_list.length == 1
                # Make another request.
                return @fetch_addresses()
            loc_list = _.sortBy loc_list, (loc) ->
                loc.name.toLowerCase()
            @submit_location_predictions loc_list

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

# GoogleCompleter is currently undocumented geocoder in the dev.hel.fi
# server that is used by tampere and manchester areas.
class GoogleCompleter extends RemoteAutocompleter
    fetch_results: ->
        url = GOOGLE_URL_BASE + "autocomplete/"
        area = citynavi.config
        location = citynavi.get_source_location_or_area_center()
        # FIXME
        radius = 12000
        # Query is the user input.
        data = {query: @query, location: location.join(','), radius: radius}
        data['country'] = area.country
        @xhr = $.getJSON url, data
        @xhr.always = () ->
            @xhr = null
        @xhr.fail () =>
            @submit_prediction_failure()
        @xhr.done (data) =>
            #console.log "GoogleCompleter data: ", data
            preds = data.predictions
            loc_list = []
            for pred in preds
                city_name = pred.terms[1].value
                if city_name not in area.cities
                    continue
                loc = new GoogleLocation pred
                loc_list.push loc
            # submit_location_predictions is defined in RemoteAutocompleter
            @submit_location_predictions loc_list

NOMINATIM_URL = "http://open.mapquestapi.com/nominatim/v1/search.php"

class OSMCompleter extends RemoteAutocompleter
    fetch_results: ->
        url = NOMINATIM_URL
        area = citynavi.config
        ne = area.bbox_ne
        sw = area.bbox_sw
        bbox = [sw[1], ne[0], ne[1], sw[0]]
        data =
            q: @query
            format: "json"
            countrycodes: area.country
            limit: 20
            bounded: 1
            addressdetails: 1
            viewbox: bbox.join(',')
        @xhr = $.getJSON url, data
        @xhr.always () =>
            @xhr = null
        @xhr.fail () =>
            @submit_prediction_failure()
        @xhr.done (data) =>
            loc_list = []
            for obj in data
                console.log "#{obj.osm_type} #{obj.class} #{obj.type} #{obj.display_name}", obj

# example queries:
# kamppi
# kampin
# mannerheimintie 100
# nam
# hsl
# opastinsilta 6a

# example results:
# Vantaa
# Pasila, Helsinki
# Itä-Pasila, Helsinki
# Mannerheimintie, Helsinki
# Mannerheimintie 100, Helsinki
# Alepa, Mannerheimintie 100, Helsinki
# HSL, Opastinsilta 6a, Helsinki

                addr = obj.address
                display = ""
                name = null

                if area.cities?.length and not (addr.city in area.cities)
                    continue

                # XXX mapping from types to more obj.address properties
                if obj.type of addr
                    name = addr[obj.type]

                # XXX full list of "road" properties?
                street = addr.road or addr.cycleway or addr.pedestrian

                number = addr.house_number

                suburb = addr.neighbourhood or addr.suburb

                if street
                    display += street
                    if number
                        display += " #{number}"
                    display += ", #{addr.city}"
                else if suburb
                    # XXX how to detect that this is a suburb?
                    display += "#{suburb}, #{addr.city}"
                else
                    display += addr.city

                if display.length and name and not (obj.type in ['city', 'suburb', 'neighbourhood', 'pedestrian'])
                    display = "#{name}, #{display}"

                # XXX own icons, more icons
                if display.length and not obj.icon and (name or not number) and not (obj.type in ['house', 'pedestrian', 'cycleway', 'service', 'residential','tertiary', 'secondary', 'primary', 'trunk', 'motorway', 'unclassified'])
                    # ei nimeä eikä numeroa -> tyyppi
                    # ei nimeä mutta numero -> katuosoite -> ei tyyppiä
                    # nimi mutta ei numeroa -> tyyppi
                    # nimi ja numeroa -> tyyppi
                    typename = obj.type
                    if typename == "yes"
                        typename = obj.class
                    typename = typename.replace /_/g, " "
                    typename = typename.replace /^./, (c) -> c.toUpperCase()
#                    typename = typename.charAt(0).toUpperCase() + typename.slice(1)
                    display = "#{typename}: #{display}"

                if display.length and (name or street or obj.icon) and obj.lat? and obj.lon?
                    if not _.all(display.toLowerCase().indexOf(part) != -1 for part in @query.toLowerCase().split(" "))
                        console.log "#{display} doesn't match #{@query}"
                        continue

                    loc = new Location "#{display}", [obj.lat, obj.lon]
                    if obj.icon
                        loc.icon = obj.icon

                    loc_list.push loc

            @submit_location_predictions loc_list

# POICategoryCompleter checks if there are any categories that would match the user input
# and if there are then it will create CategoryPrediction object, add it to the list of
# predictions and call the callback function (render_autocomplete_results).
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
    osm: new OSMCompleter # This is not currently used.

generate_area_completers = (area) ->
    (supported_completers[id] for id in area.autocompletion_providers)

# completers is a subset of the supported_completers.
completers = generate_area_completers citynavi.config

test_completer = ->
    callback = (args, data) ->
        console.log data
    geocoder.get_predictions "Piccadilly", callback

#test_completer()

# Will show a map page where the location and the route to it from the current location is shown.
# Also stores the location to the location history
navigate_to_location = (loc) ->
    idx = location_history.add loc
    page = "#map-page?destination=#{ idx }"
    citynavi.poi_list = []
    $.mobile.changePage page

# Will show a map page where the POIs and the route to the closest POI
# from the current location is shown. Also creates Location object of the
# closest POI and stores the location to the location history.
#FIXME? this is redefined in the poi.coffee
navigate_to_poi = (poi_list) ->
    poi = poi_list[0]
    loc = new Location poi.name, poi.coords
    idx = location_history.add loc
    page = "#map-page?destination=#{ idx }"
    citynavi.poi_list = poi_list
    $.mobile.changePage page

# Use all completers that have been defined in config.coffee (autocompletion_providers)
# for the area to collect the predictions.
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

# FIXME seems that if there are POICategoryCompleter predictions then no other predictions are shown.
render_autocomplete_results = (args, new_preds) ->
    $ul = args.$ul # The list where the predictions are to be included in.
    $input = args.$input # The input element.
    pred_list = pred_list.concat new_preds
    seen = {}
    for pred in pred_list
        key = pred.type + "|" + pred.location?.icon + "|" + pred.name
        if pred.rendered
            seen[key] = true
            continue
        if seen[key]
            console.log "#{key} already seen"
            continue
        seen[key] = true
        $el = pred.render() # render function of the Prediction object defined in this file
        $el.data 'index', pred_list.indexOf(pred) # Store the index of the prediction to the element
        pred.rendered = true
        $el.click (e) -> # Bind event handler to the list item
            e.preventDefault()
            idx = $(this).data 'index'
            pred = pred_list[idx]
            pred.select($input, $ul) # select function of the Prediction object  defined in this file
        $ul.append $el
    $ul.listview "refresh"
    $ul.trigger "updatelayout"

# Event handler for the listview defined in the index.html with id "navigate-to-input"
# The listview is the search box that shows the list of location suggestions when user types
# where he wants to go.
$(document).on "listviewbeforefilter", "#navigate-to-input", (e, data) ->
    $input = $(data.input)
    val = $input.val() # Get the value user has inputted in the search box.
    $ul = $(this) # The list that sent the event.
    $ul.html('')
    pred_list = []
    # Get all predictions (= location suggestions), and render the results to the list.
    get_all_predictions val, render_autocomplete_results,
        {$input: $input, $ul: $ul}

    # $input is available only here so install the event handler here
    $input.off 'keypress.enter'
    $input.on 'keypress.enter', (event) ->
        # XXX should wait for all ongoing predictions to finish first
        if event.keyCode == 13 # if enter is pressed
            if pred_list.length == 1 # if there's a unique prediction
                pred_list[0].select $input, $ul # select it
