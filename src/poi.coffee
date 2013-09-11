{
    hel_geocoder_poi_url,
    waag_url,
    waag_id,
    icon_base_path
} = citynavi.config

class POI
    constructor: (opts) ->
        _.extend @, opts

class POIProvider
    constructor: (opts) ->
        _.extend @, opts

# GeocoderPOIProvider uses the geocoder at dev.hel.fi for fetching POIs.
class GeocoderPOIProvider extends POIProvider
    fetch_pois: (category, opts) ->
        params =
            category__type: category.type
            municipality__id: citynavi.config.poi_muni_id
        if opts.location
            params.lat = opts.location[0]
            params.lon = opts.location[1]
        # Make call to the geocoder, where
        # parameters are: location coordinates, service category type, and id of the municipality if any
        # returned POIs include: name, location coordinates, service category, and dist. to the POI
        $.getJSON hel_geocoder_poi_url, params, (data) =>
            poi_list = []
            for obj in data.objects
                poi = new POI
                    name: obj.name
                    coords: [obj.location.coordinates[1], obj.location.coordinates[0]]
                    category: category
                    distance: obj.distance
                poi_list.push poi
            opts.callback poi_list, opts.callback_args

# This function is used by the WaagPOIProvider when a POI is an area
get_polygon_center = (polygon) ->
  pts = polygon._latlngs
  off_ = pts[0]
  twicearea = x = y = 0
  nPts = pts.length
  p1 = p2 = f = null
  i = 0
  j = nPts - 1

  while i < nPts
    p1 = pts[i]
    p2 = pts[j]
    f = (p1.lat - off_.lat) * (p2.lng - off_.lng) - (p2.lat - off_.lat) * (p1.lng - off_.lng)
    twicearea += f
    x += (p1.lat + p2.lat - 2 * off_.lat) * f
    y += (p1.lng + p2.lng - 2 * off_.lng) * f
    j = i++
  f = twicearea * 3
  return [x / f + off_.lat, y / f + off_.lng]

# WaagPOIProvider fetches POIs based on Open Street Map (OSM) data utilzing Waag City SDK.
class WaagPOIProvider extends POIProvider
    fetch_pois: (category, opts) ->
        count = 10
        opts = _.extend {}, opts
        params =
            layer: "osm"
            geom: 1
            per_page: count*2 # account for inaccuracy in result ordering
        if category.waag_filter
            _.extend params, category.waag_filter
        else
            params["osm::amenity"] = category.type
        console.log params

        if $('#wheelchair').attr('checked')
            params["osm::wheelchair"] = "yes"
        if opts.location
            params.lat = opts.location[0]
            params.lon = opts.location[1]
        # Make call to the geocoder, where
        # parameters are: location coordinates, service category type in "OSM format", possibly osm::wheelchair, layer=osm, geom=1, per_page=20
        # returned 10 POIs include: name, location coordinates, service category, private bool, and dist. to the POI
        $.getJSON "#{waag_url}#{waag_id}/nodes", params, (data) =>
            poi_list = []
            for res in data.results
                type = res.geom.type
                if type == "Polygon"
                    points = res.geom.coordinates[0]
                    latlngs = (new L.LatLng(p[1], p[0]) for p in points)
                    poly = new L.Polygon(latlngs)
                    coords = get_polygon_center poly
                else
                    coords = res.geom.coordinates
                    coords = [coords[1], coords[0]]
                poi = new POI
                    name: res.name
                    coords: coords
                    category: category
                    private: res.layers?.osm?.data?.access == "private"
                poi_list.push poi
            poi_list = _.sortBy poi_list, (poi) ->
                poi_loc = new L.LatLng poi.coords[0], poi.coords[1]
                poi.distance = poi_loc.distanceTo opts.location
                return poi.distance
            opts.callback poi_list[0...count], opts.callback_args

supported_poi_providers = {
    "geocoder": new GeocoderPOIProvider
    "waag": new WaagPOIProvider
}

class POICategory
    constructor: (opts) ->
        _.extend @, opts
        @provider = null
    set_provider: (provider, provider_args) ->
        @provider = provider
        @provider_args = provider_args
    get_icon_path: ->
        return icon_base_path + @icon
    get_icon_html: ->
        return '<img src="' + @get_icon_path() + '">'
    fetch_pois: (opts) ->
        @provider.fetch_pois @, opts

supported_poi_categories = {
    "library": new POICategory {type: "library", name: "Library", plural_name: "Libraries", icon: "library.svg"}
    "recycling": new POICategory {type: "recycling", name: "Recycling point", icon: "recycling.svg"}
    "park": new POICategory {type: "park", name: "Park", icon: "coniferous_and_deciduous.svg", waag_filter: {"osm::leisure": "park"}}
    "swimming_pool": new POICategory {type: "swimming_pool", name: "Swimming pool", icon: "swimming_indoor.svg"}
    "cafe": new POICategory {type: "cafe", name: "Cafe", icon: "cafe.svg"}
    "bar": new POICategory {type: "bar", name: "Bar", icon: "bar.svg"}
    "pharmacy": new POICategory {type: "pharmacy", name: "Pharmacy", icon: "pharmacy.svg", waag_filter: {"osm::amenity": "pharmacy"}}
    "toilet": new POICategory {type: "toilet", name: "Toilet (public)", icon: "toilets_men.svg", waag_filter: {"osm::amenity": "toilets"}}
    "pub": new POICategory {type: "pub", name: "Pub", icon: "pub.svg"}
    "supermarket": new POICategory {type: "supermarket", name: "Supermarket", icon: "supermarket.svg", waag_filter: {"osm::shop": "supermarket"}}
    "restaurant": new POICategory {type: "restaurant", name: "Restaurant", icon: "restaurant.svg"}
}

# Go through the list of POI providers and the list of categories under the POI providers:
# 1. Create new POICategory object for each category that have been defined in the config.coffee
# 2. Create and set the provider object for each category object. The provider type has been defined
#    in the config.coffee and currently can be "waag" or "geocoder".
# 3. Add the POICategory object to the list of categories.
# Finally, return the list of categories.
generate_area_poi_categories = (area) ->
    cat_list = []
    for prov_name of area.poi_providers
        prov = supported_poi_providers[prov_name]
        console.assert prov
        prov_cats = area.poi_providers[prov_name]
        for prov_cat in area.poi_providers[prov_name]
            cat = supported_poi_categories[prov_cat.type]
            console.assert cat
            console.assert cat.provider == null
            cat.set_provider prov
            cat_list.push cat
    return cat_list

# Generate POI categories based on the citynavi.config that has been defined in the config.coffee
citynavi.poi_categories = generate_area_poi_categories citynavi.config
console.log citynavi.poi_categories

#test_it = ->
#    prov = supported_poi_providers['waag'].fetch_pois supported_poi_categories["pub"]
#setTimeout test_it, 500

# This event happens if the user has clicked the "Find nearest services"
# button on the front page which causes showing the content of the page that
# has the id "service-directory" in the index.html.
# pageinit event happens before the pageshow event
$('#service-directory').bind 'pageinit', (e, data) ->
        # Get the ul element(s) (there is only one) inside the div with id "service-directory".
        # and store it to variable $list ($ is just a convention and we could have left it out).
        $list = $('#service-directory ul')
        $list.empty() # If there are child elements in the list then remove them.
        # Initialize the listview and avoid the "cannot call methods on listview prior to
        # initialization" error.
        $list.listview()

# Event happens when the user has selected a service category to show.
$('#service-list').bind 'pageinit', (e, data) ->
        $list = $('#service-list ul')
        $list.empty()
        $list.listview()

# Event happens when the user has selected the "Find nearest services" link from the front page.
# pageinit event happens before the pageshow event
$('#service-directory').bind 'pageshow', (e, data) ->
#    if u.hash.indexOf('#service-directory?') == 0

        $list = $('#service-directory ul')
        $list.empty()

        # Show the service categories in a list. The categories have been defined for this area,
        # e.g. Tampere, in the config.coffee and have been stored to citynavi.poi_categories in
        # this file.
        for category, index in citynavi.poi_categories
            $list.append("<li><a href=\"#service-list?category=#{index}\"><img src=\"#{category.get_icon_path()}\" class='ui-li-icon' style='height: 20px;'/>#{category.name}</a></li>")

#        setTimeout (() -> $list.listview()), 0
        $list.listview("refresh")

position_missing_alert_shown = false

# Event handler for showing nearby services of the service category that the user has selected to show.
# TODO: switch to using '#pageId' instead of the document. See:
# http://stackoverflow.com/questions/8761859/jquery-mobile-pagebeforechange-being-called-twice
# This event is triggered before page transition.
$(document).bind "pagebeforechange", (e, data) ->
    if typeof data.toPage != "string"
        return
    u = $.mobile.path.parseUrl(data.toPage)

    # If URL contains hash "#service-list?category=" then show nearby services related to the category.
    if u.hash.indexOf('#service-list?category=') == 0
        category_index = u.hash.replace(/.*\?category=/, "")

        category = citynavi.poi_categories[category_index]

        # service-list id is defined in the index.html for the page that shows "Nearest serivices" of
        # the selected category. This list will be filled.
        $list = $('#service-list ul')
        $list.empty()

        # Try to get the current location where the user is. The location can be null if the map.locate
        # call in the routing.coffee has not, possibly yet, been successful, and in that case
        # use area center for the location.
        current_location = citynavi.get_source_location()
        if not current_location?
            if not position_missing_alert_shown
                alert "The device hasn't provided its current location. Using region center instead."
                position_missing_alert_shown = true
            current_location = citynavi.config.center
        # Fetch the nearby POIs using the current_location and a callback function that creates the
        # service list that is shown to the user.
        category.fetch_pois
            location: current_location
            callback: (pois) ->
                for poi in pois
                  do (poi) ->
                    if not poi.name
                        poi.name = "Unnamed #{category.name.toLowerCase()}"
                    if poi.private
                        poi.name = "#{poi.name} (private)"
                    dist = poi.distance
                    # Rounding the distance a bit
                    if dist >= 1000
                        dist = Math.round((dist + 100) / 100)
                        dist *= 100
                    else
                        dist = Math.round((dist + 10) / 10)
                        dist *= 10
                    $item = $("<li><a href=\"#map-page\"><img src=\"#{category.get_icon_path()}\" class='ui-li-icon' style=\"height: 20px;\"/>#{poi.name}<span class='ui-li-count'>#{dist} m</span></a></li>")

                    # Bind event handler to the list item
                    $item.click () ->
                        citynavi.poi_list = pois # citynavi has been defined in the config.coffee
                        navigate_to_poi(poi)
                    $list.append($item)
                $list.listview("refresh")

# Show map page and navigation route to the POI.
navigate_to_poi = (poi) ->
    loc = new Location poi.name, poi.coords # Location class has been defined in the autocomplete.coffee
    idx = location_history.add loc # location_history has been defined in the autocomplete.coffee
    page = "#map-page?destination=#{ idx }"
    $.mobile.changePage page # This page change event is handled in the routing.coffee
