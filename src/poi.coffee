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

WAAG_URL = "http://test-api.citysdk.waag.org/admr.uk.gr.manchester/nodes"
class WaagPOIProvider extends POIProvider
    fetch_pois: (category, opts) ->
        opts = _.extend {}, opts
        params =
            layer: "osm"
            geom: 1
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
        $.getJSON WAAG_URL, params, (data) =>
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
    get_icon_path: ->
        return STATIC_PREFIX + @.icon
    get_icon_html: ->
        return '<img src="' + @.get_icon_path() + '">'
    fetch_pois: (opts) ->
        @provider.fetch_pois @, opts

supported_poi_categories = {
    "library": new POICategory {type: "library", name: "Library", plural_name: "Libraries", icon: "library2.svg"}
    "recycling": new POICategory {type: "recycling", name: "Recycling point", icon: "recycling.svg"}
    "park": new POICategory {type: "park", name: "Park", icon: "coniferous_and_deciduous.svg"}
    "bar": new POICategory {type: "bar", name: "Bar", icon: "bar.svg"}
    "pub": new POICategory {type: "pub", name: "Pub", icon: "pub.svg"}
    "supermarket": new POICategory {type: "supermarket", name: "Supermarket", icon: "supermarket.svg", waag_filter: {"osm::shop": "supermarket"}}
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
