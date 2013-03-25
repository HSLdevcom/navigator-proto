class Area
    constructor: (opts) ->
        _.extend @, opts

manchester = new Area(
    name: "Greater Manchester"
    id: "manchester"
    country: "gb"
    cities: ["Bolton", "Bury", "Oldham", "Rochdale", "Stockport", "Tameside", "Trafford", "Wigan", "Manchester", "Salford"]
    google_autocomplete_append: "Manchester"
    bbox_ne: [53.685760, -1.909630]
    bbox_sw: [53.327332, -2.730550]
    center: [53.479167, -2.244167]
    otp_base_url: "http://dev.hsl.fi:8081/opentripplanner-api-webapp/ws/"
    poi_muni_id: 44001
    poi_providers:
        "waag": [
            {type: "bar"}
            {type: "pub"}
            {type: "supermarket"}
        ],
        "geocoder": [
            {type: "park"}
            {type: "library"}
            {type: "recycling"}
            {type: "toilet"}
        ]
    autocompletion_providers: ["poi_categories", "google"]
)

helsinki = new Area(
    name: "Helsinki Region"
    id: "helsinki"
    country: "fi"
    cities: ["Helsinki", "Vantaa", "Espoo", "Kauniainen", "Kerava", "Sipoo"] # XXX more?
    bbox_ne: [60.653728, 25.576590]
    bbox_sw: [59.903339, 23.692820]
    center: [60.170833, 24.9375]
    otp_base_url: "http://dev.hsl.fi/opentripplanner-api-webapp/ws/"
    poi_muni_id: null # XXX is this ok?
    poi_providers:
        "waag": [
            {type: "bar"}
            {type: "pub"}
            {type: "supermarket"}
        ],
        "geocoder": [
            {type: "park"}
            {type: "library"}
            {type: "recycling"}
            {type: "toilet"} # XXX is this what's available here?
        ]
    autocompletion_providers: ["poi_categories", "geocoder"]
)

class CityNavigator
    constructor: (opts) ->
        @source_location = null
        _.extend @, opts
    get_source_location: ->
        return @source_location
    set_source_location: (loc) ->
        @source_location = loc

window.citynavi = new CityNavigator
    config:
        area: manchester
