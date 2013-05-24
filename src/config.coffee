class Area
    constructor: (opts) ->
        _.extend @, opts

tampere = new Area
    name: "Tampere"
    id: "tampere"
    country: "fi"
    cities: ["Tampere"]
    google_autocomplete_append: "Tampere"
    bbox_ne: [61.8237444, 24.1064742]
    bbox_sw: [61.42863, 23.5611791]
    center: [61.4976348, 23.7688124]
    otp_base_url: "http://dev.hsl.fi/tampere/opentripplanner-api-webapp/ws/"
    poi_muni_id: null
    waag_id: "admr.fi.tampere"
    poi_providers:
        "waag": [
            {type: "library"}
            {type: "park"}
            {type: "swimming_pool"}
            {type: "restaurant"}
            {type: "cafe"}
            {type: "bar"}
            {type: "pub"}
            {type: "supermarket"}
            {type: "toilet"}
            {type: "recycling"}
        ]
    autocompletion_providers: ["poi_categories", "google"]

manchester = new Area(
    name: "Greater Manchester"
    id: "manchester"
    country: "gb"
    cities: ["Bolton", "Bury", "Oldham", "Rochdale", "Stockport", "Tameside", "Trafford", "Wigan", "Manchester", "Salford"]
    google_autocomplete_append: "Manchester"
    bbox_ne: [53.685760, -1.909630]
    bbox_sw: [53.327332, -2.730550]
    center: [53.479167, -2.244167]
    otp_base_url: "http://dev.hsl.fi/manchester/opentripplanner-api-webapp/ws/"
    poi_muni_id: 44001
    waag_id: "admr.uk.gr.manchester"
    poi_providers:
        "waag": [
            {type: "restaurant"}
            {type: "cafe"}
            {type: "bar"}
            {type: "pub"}
            {type: "supermarket"}
            {type: "swimming_pool"}
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
    waag_id: "admr.fi.uusimaa" # XXX should be HSL area
    poi_providers:
        "waag": [
            {type: "restaurant"}
            {type: "cafe"}
            {type: "bar"}
            {type: "pub"}
            {type: "supermarket"}
        ],
        "geocoder": [
            {type: "park"}
            {type: "library"}
            {type: "recycling"}
            {type: "swimming_pool"}
            {type: "toilet"} # XXX is this what's available here?
        ]
    autocompletion_providers: ["poi_categories", "geocoder"]
)

class CityNavigator
    constructor: (opts) ->
        @source_location = null
        _.extend @, opts # Use underscore.js to exten the CityNavigator with the opts
    get_source_location: ->
        return @source_location
    get_source_location_or_area_center: ->
        return @source_location or @config.area.center
    set_source_location: (loc) ->
        @source_location = loc

window.citynavi = new CityNavigator
    config:
        area: manchester
