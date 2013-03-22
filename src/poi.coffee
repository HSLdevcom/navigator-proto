class POI
    constructor: (opts) ->
        _.extend @, opts

URL_BASE = "http://dev.hel.fi:8000/api/v1/poi/?format=jsonp&callback=?"
STATIC_PREFIX = "static/images/" 

class POIProvider
    constructor: (opts) ->
        _.extend @, opts

class GeocoderPOIProvider extends POIProvider
    fetch_pois: (category, opts) ->
        params =
            category__type: @type
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

WAAG_URL = "http://test-api.citysdk.waag.org/admr.uk.gr.manchester/nodes"
class WaagPOIProvider extends POIProvider
    fetch_pois: (category, opts) ->
        opts = _.extend {}, opts
        params =
            layer: "osm"
            geom: 1
            "osm::amenity": category.type
        if opts.location
            params.lat = opts.location[0]
            params.lon = opts.location[1]
        $.getJSON WAAG_URL, params, (data) =>
            poi_list = []
            for res in data.results
                coords = res.geom.coordinates
                poi = new POI
                    name: res.name
                    coords: [coords[1], coords[0]]
                    category: category
                poi_list.push poi
            opts.callback poi_list, opts.callback_args

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
    get_icon_html: ->
        return '<img src="' + STATIC_PREFIX + @.icon + '">'
    fetch_pois: (opts) ->
        @provider.fetch_pois @, opts

supported_poi_categories = {
    "library": new POICategory {type: "library", name: "Library", icon: "library2.svg"}
    "recycling": new POICategory {type: "recycling", name: "Recycling point", icon: "recycling.svg"}
    "park": new POICategory {type: "park", name: "Park", icon: "coniferous_and_deciduous.svg"}
    "bar": new POICategory {type: "bar", name: "Bar", icon: "bar.svg"}
    "pub": new POICategory {type: "pub", name: "Pub", icon: "pub.svg"}
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
