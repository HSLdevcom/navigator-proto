# config.coffee contains the default settings and area-specific settings or
# overrides of defaults. To override the settings in config.coffee, for
# example for testing or deployment, use local_config.coffee.

# window.citynavi should have been defined in init.coffee.

# Configuration modification functions.
#######################################

# Merge changes into old configs or store new configs.
citynavi.update_configs = (configs) ->
    citynavi.configs or= {}
    for key, config of configs
        citynavi.configs[key] = _.extend(citynavi.configs[key] or {},
                                         config)

    # Reload current config.
    if citynavi.config?.id
        citynavi.set_config(citynavi.config.id)

# Merge certain configs to create the current config.
citynavi.set_config = (id) ->
    # The current configuration will appear under citynavi.config.
    citynavi.config = _.extend {}, citynavi.configs.defaults,
        citynavi.configs[id], (citynavi.configs.overrides or {})
    citynavi.config.id = id


# Helper data.
##############

# Original structure from:
# https://github.com/reitti/reittiopas/blob/90a4d5f20bed3868b5fb608ee1a1c7ce77b70ed8/web/js/utils.coffee
hsl_colors =
    walk: '#9ab9c9' # walking; HSL official color is too light #bee4f8
    wait: '#999999' # waiting time at a stop
    1:    '#007ac9' # Helsinki internal bus lines
    2:    '#00985f' # Trams
    3:    '#007ac9' # Espoo internal bus lines
    4:    '#007ac9' # Vantaa internal bus lines
    5:    '#007ac9' # Regional bus lines
    6:    '#ff6319' # Metro
    7:    '#00b9e4' # Ferry
    8:    '#007ac9' # U-lines
    12:   '#64be14' # Commuter trains
    21:   '#007ac9' # Helsinki service lines
    22:   '#007ac9' # Helsinki night buses
    23:   '#007ac9' # Espoo service lines
    24:   '#007ac9' # Vantaa service lines
    25:   '#007ac9' # Region night buses
    36:   '#007ac9' # Kirkkonummi internal bus lines
    38:   '#007ac9' # Undocumented, assumed bus
    39:   '#007ac9' # Kerava internal bus lines

hel_geocoder_base_url = "http://dev.hel.fi/geocoder/v1/"
hel_servicemap_base_url = "http://www.hel.fi/palvelukarttaws/rest/v2/"


# Configuration data in plain objects.
######################################

defaults =
    hel_geocoder_address_url: hel_geocoder_base_url + "address/"
    hel_geocoder_poi_url: hel_geocoder_base_url + "poi/"
    waag_url: "http://test-api.citysdk.waag.org/"
    google_url: "http://dev.hel.fi/geocoder/google/"
    nominatim_url: "http://nominatim.openstreetmap.org/search/"
    hel_servicemap_service_url: hel_servicemap_base_url + "service/"
    hel_servicemap_unit_url: hel_servicemap_base_url + "unit/"
    reittiopas_url: "http://tuukka.kapsi.fi/tmp/reittiopas.cgi?callback=?"
    osm_notes_url: "http://api.openstreetmap.org/api/0.6/notes.json"
    faye_url: "http://dev.hsl.fi:9002/faye"

    colors:
        hsl: hsl_colors
        google:
            WALK: hsl_colors.walk
            CAR: hsl_colors.walk
            BICYCLE: hsl_colors.walk
            WAIT: hsl_colors.wait
            0: hsl_colors[2]
            1: hsl_colors[6]
            2: hsl_colors[12]
            3: hsl_colors[5]
            4: hsl_colors[7]
            109: hsl_colors[12]

    icons:
        google:
            WALK: 'walking.svg'
            CAR: 'car.svg'
            BICYCLE: 'bicycle.svg'
            WAIT: 'clock.svg'
            0: 'tram_stop.svg'
            1: 'subway.svg'
            2: 'train_station2.svg'
            3: 'bus_stop.svg'
            4: 'port.svg'
            109: 'train_station2.svg'

    maps:
        cloudmade:
            url_template: 'http://{s}.tile.cloudmade.com/{key}/{style}/256/{z}/{x}/{y}.png'
            attribution: 'Map data &copy; 2011 OpenStreetMap contributors, Imagery &copy; 2012 CloudMade'
            key: 'BC9A493B41014CAABB98F0471D759707'
            style: 998
        osm:
            url_template: 'http://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png'
            attribution: 'Map data &copy; 2011 OpenStreetMap contributors'
        opencyclemap:
            url_template: 'http://{s}.tile.opencyclemap.org/cycle/{z}/{x}/{y}.png'
            attribution: 'Map data &copy; 2011 OpenStreetMap contributors, Imagery by <a href="http://www.opencyclemap.org/" target="_blank">OpenCycleMap</a>'
        mapquest:
            url_template: 'http://otile{s}.mqcdn.com/tiles/1.0.0/map/{z}/{x}/{y}.jpg'
            subdomains: '1234'
            attribution: 'Map data &copy; 2013 OpenStreetMap contributors, Tiles Courtesy of <a href="http://www.mapquest.com/" target="_blank">MapQuest</a> <img src="http://developer.mapquest.com/content/osm/mq_logo.png">'

tampere =
    name: "Tampere"
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

manchester =
    name: "Greater Manchester"
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

helsinki =
    name: "Helsinki Region"
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


# Save and set configuration.
#############################

citynavi.update_configs {
    defaults
    helsinki
    manchester
    tampere
}

citynavi.set_config("manchester")


# Attempt to load local configuration.
######################################
#
# Currently local_config.js is loaded in index.html. If local_config.coffee
# has not been created, the browser can't find local_config.js and will move
# on. No harm done except for a dirty 404.
# FIXME: Load local_config.js from here if it exists.
