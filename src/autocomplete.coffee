{
    hel_geocoder_address_url,
    google_url,
    nominatim_url
} = citynavi.config

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
                $input.val("#{@location.street} ")
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

    submit_prediction_failure: (error) ->
        @callback @callback_args, null, error

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
    @DESCRIPTION = "Geocoder"

    fetch_results: ->
        if /\d/.test @query
            @fetch_addresses()
        else
            @fetch_streets()

    fetch_addresses: ->
        # Get maximum 10 predictions for the user input (@query) from the
        # dev.hel.fi geocoder.
        @xhr = $.getJSON hel_geocoder_address_url,
            name: @query
            limit: 10
        @xhr.always () ->
            @xhr = null
        @xhr.fail () =>
            @submit_prediction_failure("Request failed")
        @xhr.done (data) =>
            objs = data.objects
            loc_list = []
            # Create Location object of the each received data object,
            # add it to the the list, and finally call submit_location_predictions
            for adr in objs
                coords = adr.location.coordinates
                loc = new Location adr.name, [coords[1], coords[0]]
                loc.street = $.trim adr.street
                if adr.number
                    loc.number = adr.number
                    if adr.letter
                        loc.number += adr.letter
                    if adr.number_end
                        loc.number += "-" + adr.number_end
                loc_list.push loc
            # submit_location_predictions function is defined in RemoteAutocompleter
            @submit_location_predictions loc_list

    fetch_streets: ->
        @xhr = $.getJSON hel_geocoder_address_url,
            name: @query
            limit: 10
            distinct_streets: true
        @xhr.always () ->
            @xhr = null
        @xhr.fail () =>
            @submit_prediction_failure("Request failed")
        @xhr.done (data) =>
            objs = data.objects
            loc_list = []
            loc_dict = {}
            for street in objs
                strt = $.trim street.street
                continue if strt of loc_dict
                loc_dict[strt] = true
                loc = new Location strt+" \u2026", [null, null]
                loc.street = strt
                loc_list.push loc
            if loc_list.length == 1
                # Make another request.
                return @fetch_addresses()
            loc_list = _.sortBy loc_list, (loc) ->
                loc.name.toLowerCase()
            @submit_location_predictions loc_list

# Bag42Completer uses the geocoder at bag42.nl.
class Bag42Completer extends RemoteAutocompleter
    @DESCRIPTION = "Bag42"

    fetch_results: ->
        # Get maximum 10 predictions for the user input (@query) from the
        # dev.hel.fi geocoder.
        @xhr = $.getJSON citynavi.config.bag42_url,
            address: @query
            maxitems: 10
        @xhr.always () ->
            @xhr = null
        @xhr.fail () =>
            @submit_prediction_failure("Request failed")
        @xhr.done (data) =>
            objs = data.results
            loc_list = []
            # Create Location object of the each received data object,
            # add it to the the list, and finally call submit_location_predictions
            for adr in objs or []
                coords = adr.geometry.location
                loc = new Location adr.formatted_address.replace(/\n/g, ", "), [coords.lat, coords.lng]
                loc_list.push loc
            # submit_location_predictions function is defined in RemoteAutocompleter
            @submit_location_predictions loc_list

class GoogleLocation extends Location
    constructor: (pred) ->
        @name = pred.description
        @info = pred
    fetch_details: (callback, args) ->
        url = google_url + "details/"
        params = {reference: @info.reference}
        $.getJSON url, params, (data) =>
            res = data.result
            loc = res.geometry.location
            @coords = [loc.lat, loc.lng]
            callback args, @

# GoogleCompleter is currently undocumented geocoder in the dev.hel.fi
# server that is used by tampere and manchester areas.
class GoogleCompleter extends RemoteAutocompleter
    @DESCRIPTION = "Google geocoder"
    fetch_results: ->
        url = google_url + "autocomplete/"
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
            @submit_prediction_failure("Request failed")
        @xhr.done (data) =>
            #console.log "GoogleCompleter data: ", data
            preds = data.predictions
            loc_list = []
            for pred in preds
                city_name = pred.terms[1].value
                if area.cities and city_name not in area.cities
                    continue
                if area.google_suffix and pred.description.lastIndexOf(area.google_suffix) == pred.description.length - area.google_suffix.length
                    pred.description = pred.description.substring(0, pred.description.length - area.google_suffix.length)
                loc = new GoogleLocation pred
                loc_list.push loc
            # submit_location_predictions is defined in RemoteAutocompleter
            @submit_location_predictions loc_list


# based on http://stackoverflow.com/questions/227950/programatic-accent-reduction-in-javascript-aka-text-normalization-or-unaccentin
accent_insensitive_pattern = (text) ->
    # escape characters that have special meaning in a regex
    text = text.replace /([|()[{.+*?^$\\])/g, "\\$1"
    # replace each letter with a pattern that matches accented variants
    letter_to_diacritic_pattern = (letter) ->
        letters_to_accents[letter.toUpperCase()] or letter
    text = text.replace /./g, letter_to_diacritic_pattern
    return new RegExp(text)

# map from capital letters to patterns that match accents and lowercase too
letters_to_accents =
    'A': '[Aa\xaa\xc0-\xc5\xe0-\xe5\u0100-\u0105\u01cd\u01ce\u0200-\u0203\u0226\u0227\u1d2c\u1d43\u1e00\u1e01\u1e9a\u1ea0-\u1ea3\u2090\u2100\u2101\u213b\u249c\u24b6\u24d0\u3371-\u3374\u3380-\u3384\u3388\u3389\u33a9-\u33af\u33c2\u33ca\u33df\u33ff\uff21\uff41]'
    'B': '[Bb\u1d2e\u1d47\u1e02-\u1e07\u212c\u249d\u24b7\u24d1\u3374\u3385-\u3387\u33c3\u33c8\u33d4\u33dd\uff22\uff42]'
    'C': '[Cc\xc7\xe7\u0106-\u010d\u1d9c\u2100\u2102\u2103\u2105\u2106\u212d\u216d\u217d\u249e\u24b8\u24d2\u3376\u3388\u3389\u339d\u33a0\u33a4\u33c4-\u33c7\uff23\uff43]'
    'D': '[Dd\u010e\u010f\u01c4-\u01c6\u01f1-\u01f3\u1d30\u1d48\u1e0a-\u1e13\u2145\u2146\u216e\u217e\u249f\u24b9\u24d3\u32cf\u3372\u3377-\u3379\u3397\u33ad-\u33af\u33c5\u33c8\uff24\uff44]'
    'E': '[Ee\xc8-\xcb\xe8-\xeb\u0112-\u011b\u0204-\u0207\u0228\u0229\u1d31\u1d49\u1e18-\u1e1b\u1eb8-\u1ebd\u2091\u2121\u212f\u2130\u2147\u24a0\u24ba\u24d4\u3250\u32cd\u32ce\uff25\uff45]'
    'F': '[Ff\u1da0\u1e1e\u1e1f\u2109\u2131\u213b\u24a1\u24bb\u24d5\u338a-\u338c\u3399\ufb00-\ufb04\uff26\uff46]'
    'G': '[Gg\u011c-\u0123\u01e6\u01e7\u01f4\u01f5\u1d33\u1d4d\u1e20\u1e21\u210a\u24a2\u24bc\u24d6\u32cc\u32cd\u3387\u338d-\u338f\u3393\u33ac\u33c6\u33c9\u33d2\u33ff\uff27\uff47]'
    'H': '[Hh\u0124\u0125\u021e\u021f\u02b0\u1d34\u1e22-\u1e2b\u1e96\u210b-\u210e\u24a3\u24bd\u24d7\u32cc\u3371\u3390-\u3394\u33ca\u33cb\u33d7\uff28\uff48]'
    'I': '[Ii\xcc-\xcf\xec-\xef\u0128-\u0130\u0132\u0133\u01cf\u01d0\u0208-\u020b\u1d35\u1d62\u1e2c\u1e2d\u1ec8-\u1ecb\u2071\u2110\u2111\u2139\u2148\u2160-\u2163\u2165-\u2168\u216a\u216b\u2170-\u2173\u2175-\u2178\u217a\u217b\u24a4\u24be\u24d8\u337a\u33cc\u33d5\ufb01\ufb03\uff29\uff49]'
    'J': '[Jj\u0132-\u0135\u01c7-\u01cc\u01f0\u02b2\u1d36\u2149\u24a5\u24bf\u24d9\u2c7c\uff2a\uff4a]'
    'K': '[Kk\u0136\u0137\u01e8\u01e9\u1d37\u1d4f\u1e30-\u1e35\u212a\u24a6\u24c0\u24da\u3384\u3385\u3389\u338f\u3391\u3398\u339e\u33a2\u33a6\u33aa\u33b8\u33be\u33c0\u33c6\u33cd-\u33cf\uff2b\uff4b]'
    'L': '[Ll\u0139-\u0140\u01c7-\u01c9\u02e1\u1d38\u1e36\u1e37\u1e3a-\u1e3d\u2112\u2113\u2121\u216c\u217c\u24a7\u24c1\u24db\u32cf\u3388\u3389\u33d0-\u33d3\u33d5\u33d6\u33ff\ufb02\ufb04\uff2c\uff4c]'
    'M': '[Mm\u1d39\u1d50\u1e3e-\u1e43\u2120\u2122\u2133\u216f\u217f\u24a8\u24c2\u24dc\u3377-\u3379\u3383\u3386\u338e\u3392\u3396\u3399-\u33a8\u33ab\u33b3\u33b7\u33b9\u33bd\u33bf\u33c1\u33c2\u33ce\u33d0\u33d4-\u33d6\u33d8\u33d9\u33de\u33df\uff2d\uff4d]'
    'N': '[Nn\xd1\xf1\u0143-\u0149\u01ca-\u01cc\u01f8\u01f9\u1d3a\u1e44-\u1e4b\u207f\u2115\u2116\u24a9\u24c3\u24dd\u3381\u338b\u339a\u33b1\u33b5\u33bb\u33cc\u33d1\uff2e\uff4e]'
    'O': '[Oo\xba\xd2-\xd6\xf2-\xf6\u014c-\u0151\u01a0\u01a1\u01d1\u01d2\u01ea\u01eb\u020c-\u020f\u022e\u022f\u1d3c\u1d52\u1ecc-\u1ecf\u2092\u2105\u2116\u2134\u24aa\u24c4\u24de\u3375\u33c7\u33d2\u33d6\uff2f\uff4f]'
    'P': '[Pp\u1d3e\u1d56\u1e54-\u1e57\u2119\u24ab\u24c5\u24df\u3250\u3371\u3376\u3380\u338a\u33a9-\u33ac\u33b0\u33b4\u33ba\u33cb\u33d7-\u33da\uff30\uff50]',
    'Q': '[Qq\u211a\u24ac\u24c6\u24e0\u33c3\uff31\uff51]'
    'R': '[Rr\u0154-\u0159\u0210-\u0213\u02b3\u1d3f\u1d63\u1e58-\u1e5b\u1e5e\u1e5f\u20a8\u211b-\u211d\u24ad\u24c7\u24e1\u32cd\u3374\u33ad-\u33af\u33da\u33db\uff32\uff52]'
    'S': '[Ss\u015a-\u0161\u017f\u0218\u0219\u02e2\u1e60-\u1e63\u20a8\u2101\u2120\u24ae\u24c8\u24e2\u33a7\u33a8\u33ae-\u33b3\u33db\u33dc\ufb06\uff33\uff53]'
    'T': '[Tt\u0162-\u0165\u021a\u021b\u1d40\u1d57\u1e6a-\u1e71\u1e97\u2121\u2122\u24af\u24c9\u24e3\u3250\u32cf\u3394\u33cf\ufb05\ufb06\uff34\uff54]'
    'U': '[Uu\xd9-\xdc\xf9-\xfc\u0168-\u0173\u01af\u01b0\u01d3\u01d4\u0214-\u0217\u1d41\u1d58\u1d64\u1e72-\u1e77\u1ee4-\u1ee7\u2106\u24b0\u24ca\u24e4\u3373\u337a\uff35\uff55]'
    'V': '[Vv\u1d5b\u1d65\u1e7c-\u1e7f\u2163-\u2167\u2173-\u2177\u24b1\u24cb\u24e5\u2c7d\u32ce\u3375\u33b4-\u33b9\u33dc\u33de\uff36\uff56]'
    'W': '[Ww\u0174\u0175\u02b7\u1d42\u1e80-\u1e89\u1e98\u24b2\u24cc\u24e6\u33ba-\u33bf\u33dd\uff37\uff57]'
    'X': '[Xx\u02e3\u1e8a-\u1e8d\u2093\u213b\u2168-\u216b\u2178-\u217b\u24b3\u24cd\u24e7\u33d3\uff38\uff58]'
    'Y': '[Yy\xdd\xfd\xff\u0176-\u0178\u0232\u0233\u02b8\u1e8e\u1e8f\u1e99\u1ef2-\u1ef9\u24b4\u24ce\u24e8\u33c9\uff39\uff59]'
    'Z': '[Zz\u0179-\u017e\u01f1-\u01f3\u1dbb\u1e90-\u1e95\u2124\u2128\u24b5\u24cf\u24e9\u3390-\u3394\uff3a\uff5a]'

class OSMCompleter extends RemoteAutocompleter
    @DESCRIPTION = "OpenStreetMap Nominatim"
    fetch_results: ->
        url = nominatim_url
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
            @submit_prediction_failure("Request failed")
        @xhr.done (data) =>
            loc_list = []
            # results must contain matches to all these to be accepted
            query_filter_patterns = (accent_insensitive_pattern(part) for part in @query.split(" "))

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

                type = obj.type
                if type == "yes"
                    type = obj.class

                # XXX mapping from types to more obj.address properties
                if type of addr
                    name = addr[type]

                is_street = type in ['building', 'house', 'living_street', 'pedestrian', 'cycleway', 'service', 'residential','tertiary', 'secondary', 'primary', 'trunk', 'motorway', 'unclassified']

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

                if display.length and name and not (type in ['city', 'suburb', 'neighbourhood', 'pedestrian', 'cycleway'])
                    display = "#{name}, #{display}"

                # XXX own icons, more icons
                if display.length and not obj.icon and (name or not number) and not is_street
                    # ei nimeä eikä numeroa -> tyyppi
                    # ei nimeä mutta numero -> katuosoite -> ei tyyppiä
                    # nimi mutta ei numeroa -> tyyppi
                    # nimi ja numeroa -> tyyppi
                    typename = type.replace /_/g, " "
                    typename = typename.replace /^./, (c) -> c.toUpperCase()
#                    typename = typename.charAt(0).toUpperCase() + typename.slice(1)
                    display = "#{typename}: #{display}"

                if display.length and (name or street or obj.icon) and obj.lat? and obj.lon?
                    if not _.all(display.match(pattern) for pattern in query_filter_patterns)
                        console.log "#{display} doesn't match #{@query}"
                        continue

                    loc = new Location "#{display}", [obj.lat, obj.lon]
                    if obj.icon
                        loc.icon = obj.icon
                    if is_street
                        loc.street = street
                        if number
                            loc.number = number
                    loc_list.push loc

            @submit_location_predictions loc_list

# POICategoryCompleter checks if there are any categories that would match the user input
# and if there are then it will create CategoryPrediction object, add it to the list of
# predictions and call the callback function (render_autocomplete_results).
class POICategoryCompleter extends Autocompleter
    @DESCRIPTION = "POI categories"
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


class HistoryCompleter extends Autocompleter
    @DESCRIPTION = "Destination history"
    get_predictions: (query, callback, args) ->
        console.log "historycompleter"
        pred_list = []
        for location in location_history.history by -1
            if query.length and location.name.toLowerCase().indexOf(query.toLowerCase()) != 0
                continue
            pred_list.push new LocationPrediction(location)
            if pred_list.length >= 10
                break
        callback args, pred_list

supported_completers =
    poi_categories: new POICategoryCompleter
    geocoder: new GeocoderCompleter
    bag42: new Bag42Completer
    google: new GoogleCompleter
    osm: new OSMCompleter
    history: new HistoryCompleter

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
# Async completers run in parallel but the callback gets the results in order
get_all_predictions = (input, callback, callback_options) ->
    input = $.trim input

    # Deferred representing the in-order callback for the previous completer
    prev_deferred = $.Deferred().resolve() # first completer waits nothing

    # call each async completer and wire their in-order callbacks
    for c, i in completers
        if c.remote
            # Do not do remote autocompletion if less than 3 characters
            # input.
            if input.length < 3
                continue
        # a deferred representing the in-order callback for this completer
        deferred = $.Deferred()
        deferred.done callback
        # the out-of-order async callback from this prediction
        prediction_callback = do (c, i, deferred, prev_deferred) ->
            (_options, new_preds, error) ->
                # wire this in-order callback after the previous
                prev_deferred.always () ->
                    deferred.resolve(callback_options, new_preds, error, c)
        c.get_predictions input, prediction_callback, {}
        prev_deferred = deferred

    prev_deferred.always () ->
        callback callback_options, null, null, null

pred_list = []

# FIXME seems that if there are POICategoryCompleter predictions then no other predictions are shown.
render_autocomplete_results = (args, new_preds, error, completer) ->
    $ul = args.$ul # The list where the predictions are to be included in.
    $input = args.$input # The input element.
    if not completer?
        console.log "not completer?"
        if pred_list.length == 0
            $ul.append("<li><em>No search results.</em></li>")
        else
            $ul.append("<li><em>Search done.</em></li>")
    else if not new_preds?
        $ul.append("<li><em>#{completer.constructor.DESCRIPTION} failed#{if error then ": "+error else ""}</em></li>")
    else
        pred_list = pred_list.concat new_preds
    seen = {}
    seen_streets = {}
    seen_addresses = {}
    for pred in pred_list
        if pred.location?.street
            key = pred.location.street
            if seen_streets[key] and not pred.location.number
                continue
            seen_streets[key] = true
            if pred.location.number
                key = pred.location.street + "|" + pred.location.number
                if seen_addresses[key]
                    continue
                seen_addresses[key] = true
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
