class POI
    constructor: (opts) ->
        _.extend @, opts

URL_BASE = "http://dev.hel.fi:8000/api/v1/poi/?format=jsonp&callback=?"
STATIC_PREFIX = "static/images/" 

class POICategory
    constructor: (opts) ->
        _.extend @, opts
    get_icon_html: ->
        return '<img src="' + STATIC_PREFIX + @.icon + '">'
    fetch_pois: (opts) ->
        params =
            category__type: @.type
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
                    category: @
                poi_list.push poi
            opts.callback poi_list, opts.callback_args

poi_categories = [
    new POICategory {type: "library", name: "Library", icon: "library2.svg"}
    new POICategory {type: "recycling", name: "Recycling point", icon: "recycling.svg"}
    new POICategory {type: "park", name: "Park", icon: "coniferous_and_deciduous.svg"}
]

citynavi.poi_categories = poi_categories
