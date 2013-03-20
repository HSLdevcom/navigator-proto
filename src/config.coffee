class Area
    constructor: (opts) ->
        _.extend @, opts



    (@name, @country, @bbox_ne, @bbox_sw, @center) ->

manchester = new Area(
    name: "Greater Manchester"
    country: "gb"
    bbox_ne: [53.685760, -1.909630]
    bbox_sw: [53.327332, -2.730550]
    center: [53.479167, -2.244167]
)

helsinki = new Area(
    name: "Helsinki Metropolitan"
    country: "fi"
    bbox_ne: [60.653728, 25.576590]
    bbox_sw: [59.903339, 23.692820]
    center: [60.170833, 24.9375]

config =
    area: manchester

window.navi_config = config
