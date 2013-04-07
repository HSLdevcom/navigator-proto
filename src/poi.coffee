class POI
    constructor: (opts) ->
        _.extend @, opts

URL_BASE = "http://dev.hel.fi/geocoder/v1/poi/?format=jsonp&callback=?"
STATIC_PREFIX = "static/images/" 

class POIProvider
    constructor: (opts) ->
        _.extend @, opts

class GeocoderPOIProvider extends POIProvider
    fetch_pois: (category, opts) ->
        params =
            category__type: category.type
            municipality__id: citynavi.config.area.poi_muni_id
        if opts.location
            params.lat = opts.location[0]
            params.lon = opts.location[1]
        $.getJSON URL_BASE, params, (data) =>
            poi_list = []
            for obj in data.objects
                poi = new POI
                    name: obj.name
                    coords: [obj.location.coordinates[1], obj.location.coordinates[0]]
                    category: category
                poi_list.push poi
            opts.callback poi_list, opts.callback_args

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

WAAG_URL = "http://test-api.citysdk.waag.org"
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
        $.getJSON "#{WAAG_URL}/#{citynavi.config.area.waag_id}/nodes", params, (data) =>
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
        return STATIC_PREFIX + @.icon
    get_icon_html: ->
        return '<img src="' + @.get_icon_path() + '">'
    fetch_pois: (opts) ->
        @provider.fetch_pois @, opts

supported_poi_categories = {
    "library": new POICategory {type: "library", name: "Library", plural_name: "Libraries", icon: "library.svg"}
    "recycling": new POICategory {type: "recycling", name: "Recycling point", icon: "recycling.svg"}
    "park": new POICategory {type: "park", name: "Park", icon: "coniferous_and_deciduous.svg"}
    "swimming_pool": new POICategory {type: "swimming_pool", name: "Swimming pool", icon: "swimming_indoor.svg"}
    "bar": new POICategory {type: "bar", name: "Bar", icon: "bar.svg"}
    "toilet": new POICategory {type: "toilet", name: "Toilet (public)", icon: "toilets_men.svg"}
    "pub": new POICategory {type: "pub", name: "Pub", icon: "pub.svg"}
    "supermarket": new POICategory {type: "supermarket", name: "Supermarket", icon: "supermarket.svg", waag_filter: {"osm::shop": "supermarket"}}
    "restaurant": new POICategory {type: "restaurant", name: "Restaurant", icon: "restaurant.svg"}
}

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

citynavi.poi_categories = generate_area_poi_categories citynavi.config.area
console.log citynavi.poi_categories

#test_it = ->
#    prov = supported_poi_providers['waag'].fetch_pois supported_poi_categories["pub"]
#setTimeout test_it, 500


$('#service-directory').bind 'pageinit', (e, data) ->
        $list = $('#service-directory ul')
        $list.empty()
        $list.listview()

$('#service-list').bind 'pageinit', (e, data) ->
        $list = $('#service-list ul')
        $list.empty()
        $list.listview()

$('#service-directory').bind 'pageshow', (e, data) ->
#    if u.hash.indexOf('#service-directory?') == 0

        $list = $('#service-directory ul')
        $list.empty()

        for category, index in citynavi.poi_categories 
            $list.append("<li><a href=\"#service-list?category=#{index}\"><img src=\"#{category.get_icon_path()}\" class='ui-li-icon' style='height: 20px;'/>#{category.name}</a></li>")

#        setTimeout (() -> $list.listview()), 0
        $list.listview("refresh")

position_missing_alert_shown = false

$(document).bind "pagebeforechange", (e, data) ->
    if typeof data.toPage != "string"
        return
    u = $.mobile.path.parseUrl(data.toPage)

    if u.hash.indexOf('#service-list?category=') == 0
        category_index = u.hash.replace(/.*\?category=/, "")

        category = citynavi.poi_categories[category_index]

        $list = $('#service-list ul')
        $list.empty()

        current_location = citynavi.get_source_location()
        if not current_location?
            if not position_missing_alert_shown
                alert "The device hasn't provided its current location. Using region center instead."
                position_missing_alert_shown = true
            current_location = citynavi.config.area.center
        category.fetch_pois
            location: current_location
            callback: (pois) ->
                for poi in pois
                  do (poi) ->
                    if not poi.name
                        return
                    dist = poi.distance
                    if dist >= 1000
                        dist = Math.round((dist + 100) / 100)
                        dist *= 100
                    else
                        dist = Math.round((dist + 10) / 10)
                        dist *= 10
                    $item = $("<li><a href=\"#map-page\"><img src=\"#{category.get_icon_path()}\" class='ui-li-icon' style=\"height: 20px;\"/>#{poi.name}<span class='ui-li-count'>#{dist} m</span></a></li>")
                    
                    $item.click () ->
                        citynavi.poi_list = pois
                        navigate_to_poi(poi)
                    $list.append($item)
                $list.listview("refresh")

navigate_to_poi = (poi) ->
    loc = new Location poi.name, poi.coords
    idx = location_history.add loc
    page = "#map-page?destination=#{ idx }"
    $.mobile.changePage page
