class Area
    constructor: (@name, @country, @bbox_ne, @bbox_sw) ->

manchester = new Area("Greater Manchester", "gb", [53.685760, -1.909630], [53.327332, -2.730550])
helsinki = new Area("Helsinki Metropolitan", "fi", [60.653728, 25.576590], [59.903339, 23.692820])

config = {area: manchester}

window.navi_config = config
