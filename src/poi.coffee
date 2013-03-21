class POI
    constructor: (opts) ->
        _.extend @, opts

URL_BASE = "http://dev.hel.fi:8000/api/v1/poi/?format=jsonp&callback=?"

class POICategory
    constructor: (opts) ->
        _.extend @, opts
    fetch_pois: (opts, callback, callback_args) ->
        params =
            category__type: @.type
            municipality__id: citynavi.config.area.poi_muni_id

        $.getJSON URL_BASE, params, (data) =>
            poi_list = []
            for obj in data.objects
                poi = new POI
                    name: obj.name
                    coords: [obj.location.coordinates[1], obj.location.coordinates[0]]
                    category: @
                poi_list.push obj
            callback poi_list, callback_args

poi_categories = [
    new POICategory {type: "library", name: "Library", icon: "library2.svg"}
    new POICategory {type: "recycling", name: "Recycling point", icon: "recycling.svg"}
    new POICategory {type: "park", name: "Park", icon: "coniferous_and_deciduous.svg"}
]

citynavi.poi_categories = poi_categories
