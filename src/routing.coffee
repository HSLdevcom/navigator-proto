
## module state variables

# map
map = null

# map markers for current position, routing source, routing target
positionMarker = sourceMarker = targetMarker = null

# map feature for accuracy of geolocated routing source
sourceCircle = null

# map layer for routing results
routeLayer = null

# latest geolocation event info
position_point = position_bounds = null

$(document).bind "pagebeforechange", (e, data) ->
    if typeof data.toPage != "string"
        return
    u = $.mobile.path.parseUrl(data.toPage)

    if u.hash.indexOf('#map-page?service=') == 0
        srv_id = u.hash.replace(/.*\?service=/, "")
        e.preventDefault()
        route_to_service(srv_id)

    if u.hash.indexOf('#map-page?destination=') == 0
        destination = u.hash.replace(/.*\?destination=/, "")
        e.preventDefault()
        location = location_history.get(destination)
        route_to_destination(location)

route_to_destination = (target_location) ->
    [lat, lng] = target_location.coords
    target = new L.LatLng(lat, lng)
    if targetMarker?
        map.removeLayer(targetMarker)
    targetMarker = L.marker(target, {draggable: true}).addTo(map)
        .on('dragend', onSourceDragEnd)
        .bindPopup("#{target_location.name}").openPopup()
    $.mobile.changePage("#map-page")
    if sourceMarker?
        source = sourceMarker.getLatLng()
        find_route sourceMarker.getLatLng(), target, (route) ->
            map.fitBounds(route.getBounds())

route_to_service = (srv_id) ->
    if not sourceMarker?
        alert("Laite ei ole antanut nykyistä sijaintia!")
        return
    source = sourceMarker.getLatLng()
    $.getJSON "http://www.hel.fi/palvelukarttaws/rest/v2/unit/?service=#{srv_id}&distance=1000&lat=#{source.lat.toPrecision(7)}&lon=#{source.lng.toPrecision(7)}&callback=?", (data) ->
        window.service_dbg = data
        if data.length == 0
            alert("Ei palvelua lähellä nykyistä sijaintia")
            return
        target = new L.LatLng(data[0].latitude, data[0].longitude)
        if targetMarker?
            map.removeLayer(targetMarker)
        targetMarker = L.marker(target, {draggable: true}).addTo(map)
            .on('dragend', onSourceDragEnd)
            .bindPopup("#{data[0].name_fi}<br>(lähin #{srv_id})").openPopup()
        $.mobile.changePage("#map-page")
        find_route sourceMarker.getLatLng(), target, (route) ->
            map.fitBounds(route.getBounds())

$(document).bind "mobileinit", ->
    $.mobile.defaultPageTransition = "slide"
    $.mobile.defaultHomeScroll = 0
    $.mobile.page.prototype.options.keepNative = "form input"

$('#map-page').bind 'pageshow', (e, data) ->
    height = window.innerHeight-$('[data-role=header]').height()-
                                $('[data-role=footer]').height()-
                                $('[data-role=listview]').height()
    $('#map').height(height)
    map.invalidateSize()

    if targetMarker?
        if sourceMarker?
            sourceMarker.closePopup()
        targetMarker.closePopup()
        targetMarker.openPopup()
    else if sourceMarker?
        sourceMarker.closePopup()
        sourceMarker.openPopup()

    if routeLayer?
        map.fitBounds(routeLayer.getBounds())
    else if position_point?
        zoom = Math.min(map.getBoundsZoom(position_bounds), 15)
        map.setView(position_point, zoom)

window.map_dbg = map = L.map('map', {minZoom: 10, zoomControl: false})
    .setView([60.29532, 24.93073], 10)
map.locate
    setView: false
    maxZoom: 15
    watch: true
    timeout: Infinity
    enableHighAccuracy: true

# from https://github.com/reitti/reittiopas/blob/master/web/js/utils.coffee
transportColors =
    walk: '#000000'
    1:  '#193695' # Helsinki internal bus lines
    2:  '#00ab66' # Trams
    3:  '#193695' # Espoo internal bus lines
    4:  '#193695' # Vantaa internal bus lines
    5:  '#193695' # Regional bus lines
    6:  '#fb6500' # Metro
    7:  '#00aee7' # Ferry
    8:  '#193695' # U-lines
    12: '#ce1141' # Commuter trains
    21: '#193695' # Helsinki service lines
    22: '#193695' # Helsinki night buses
    23: '#193695' # Espoo service lines
    24: '#193695' # Vantaa service lines
    25: '#193695' # Region night buses
    36: '#193695' # Kirkkonummi internal bus lines
    38: '#193695' # Undocumented, assumed bus
    39: '#193695' # Kerava internal bus lines

googleColors = 
    null: transportColors.walk
    0: transportColors[2]
    1: transportColors[6]
    2: transportColors[12]
    3: transportColors[5]
    4: transportColors[7]
    109: transportColors[12]

format_code = (code) ->
    if code.substring(0,3) == "300" # local train
        return code.charAt(4)
    else if code.substring(0,4) == "1300" # metro
        return "Metro"
    else if code.substring(0,3) == "110" # helsinki night bus
        return code.substring(2,5)
    else if code.substring(0,4) == "1019" # suomenlinna ferry
        return "Suomenlinna ferry"
    return code.substring(1,5).replace(/^(0| )+| +$/, "")

format_time = (time) ->
    return time.replace(/(....)(..)(..)(..)(..)/,"$1-$2-$3 $4:$5")

onSourceDragEnd = (event) ->
    if sourceMarker != null and targetMarker != null
        find_route(sourceMarker.getLatLng(), targetMarker.getLatLng())

# translated from https://github.com/ahocevar/openlayers/blob/master/lib/OpenLayers/Format/EncodedPolyline.js
decode_polyline = (encoded, dims) -> 
    # Start from origo
    point = (0 for i in [0...dims])

    # Loop over the encoded input string
    i = 0
    points = while i < encoded.length
        for dim in [0...dims]
            result = 0
            shift = 0
            loop
                b = encoded.charCodeAt(i++) - 63
                result |= (b & 0x1f) << shift
                shift += 5
                break unless b >= 0x20

            point[dim] += if result & 1 then ~(result >> 1) else result >> 1

        # Keep a copy in the result list
        point.slice(0)

    return points

find_route = (source, target, callback) ->
    $.getJSON "http://dev.hsl.fi/opentripplanner-api-webapp/ws/plan?toPlace=#{target.lat},#{target.lng}&fromPlace=#{source.lat},#{source.lng}&callback=?", (data) ->

        if data.error?.msg
            $('#error-popup p').text(data.error.msg)
            $('#error-popup').popup('open')
            return

        window.route_dbg = data

        if routeLayer != null
            map.removeLayer(routeLayer)
            routeLayer = null
        else
            map.removeLayer(osm)
            map.addLayer(cloudmade)

        route = L.featureGroup().addTo(map)
        routeLayer = route

        legs = data.plan.itineraries[0].legs

        for leg in legs
          do () ->
            points = (new L.LatLng(point[0]*1e-5, point[1]*1e-5) for point in decode_polyline(leg.legGeometry.points, 2))
            color = googleColors[leg.routeType]
            polyline = new L.Polyline(points, {color: color})
                .on 'click', (e) ->
                    map.fitBounds(e.target.getBounds())
                    if marker?
                        marker.openPopup()
            polyline.addTo(route)
            if leg.routeType != null
                stop = leg.from
                last_stop = leg.to
                point = {y: stop.lat, x: stop.lon}
                marker = L.marker(new L.LatLng(point.y, point.x)).addTo(route)
                    .bindPopup("At time #{moment(leg.startTime).format("YYYY-MM-DD HH:mm")}, take the line #{format_code(leg.routeId)} from stop #{stop.name} to stop #{last_stop.name}")

        if callback
            callback(route)

find_route_reittiopas = (source, target, callback) ->
    $.getJSON "http://tuukka.kapsi.fi/tmp/reittiopas.cgi?request=route&detail=full&epsg_in=wgs84&epsg_out=wgs84&from=#{source.lng},#{source.lat}&to=#{target.lng},#{target.lat}&callback=?", (data) ->
        window.route_dbg = data

        if routeLayer != null
            map.removeLayer(routeLayer)
            routeLayer = null
        else
            map.removeLayer(osm)
            map.addLayer(cloudmade)

        route = L.featureGroup().addTo(map)
        routeLayer = route

        legs = data[0][0].legs
        for leg in legs
          do () ->
            points = (new L.LatLng(point.y, point.x) for point in leg.shape)
            color = transportColors[leg.type]
            polyline = new L.Polyline(points, {color: color})
                .on 'click', (e) ->
                    map.fitBounds(e.target.getBounds())
                    if marker?
                        marker.openPopup()
            polyline.addTo(route)
            if leg.type != 'walk'
                stop = leg.locs[0]
                last_stop = leg.locs[leg.locs.length-1]
                point = leg.shape[0]
                marker = L.marker(new L.LatLng(point.y, point.x)).addTo(route)
                    .bindPopup("At time #{format_time(stop.depTime)}, take the line #{format_code(leg.code)} from stop #{stop.name} to stop #{last_stop.name}")

        if not map.getBounds().contains(route.getBounds())
            map.fitBounds(route.getBounds())

cloudmade = L.tileLayer('http://{s}.tile.cloudmade.com/{key}/{style}/256/{z}/{x}/{y}.png', 
    attribution: 'Map data &copy; 2011 OpenStreetMap contributors, Imagery &copy; 2012 CloudMade',
    key: 'BC9A493B41014CAABB98F0471D759707'
    style: 22677
)
osm = L.tileLayer('http://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png', 
    attribution: 'Map data &copy; 2011 OpenStreetMap contributors',
).addTo(map)
mapquest = L.tileLayer("http://otile{s}.mqcdn.com/tiles/1.0.0/map/{z}/{x}/{y}.jpg",
    subdomains: "1234"
    attribution: 'Map data &copy; 2013 OpenStreetMap contributors, Tiles Courtesy of <a href="http://www.mapquest.com/" target="_blank">MapQuest</a> <img src="http://developer.mapquest.com/content/osm/mq_logo.png">'
)
L.control.layers({
    "OpenStreetMap": osm
    "CloudMade": cloudmade
    "MapQuest": mapquest
},
).addTo(map)
L.control.scale().addTo(map)

BackControl = L.Control.extend
    options: {
        position: 'topleft'
    },

    onAdd: (map) ->
        $container = $("<div id='back-control'>")
        $container.append($("<a href='' data-role='button' data-rel='back' data-icon='arrow-l' data-mini='true'>Takaisin</a>"))
        return $container.get(0)

new BackControl().addTo(map)

L.control.zoom().addTo(map)


map.on 'locationerror', (e) ->
    alert(e.message)

map.on 'locationfound', (e) ->
#    radius = e.accuracy / 2
    radius = e.accuracy
    measure = if e.accuracy < 2000 then "#{Math.round(e.accuracy)} meters" else "#{Math.round(e.accuracy/1000)} km"
    point = e.latlng

    # save latest position info for later page change
    position_point = point
    position_bounds = e.bounds

    if positionMarker != null
        map.removeLayer(positionMarker)
        positionMarker = null
    else if sourceMarker == null
        zoom = Math.min(map.getBoundsZoom(e.bounds), 15)
        map.setView(point, zoom)

        sourceMarker = L.marker(point, {draggable: true}).addTo(map)
            .on('dragend', onSourceDragEnd)
            .bindPopup("The starting point for journey planner<br>(tap the red marker to update)<br>You are within #{measure} from this point").openPopup()
        sourceCircle = L.circle(point, radius, {color: 'gray'}).addTo(map)

    if radius > 2000
        return
    positionMarker = L.circle(point, radius, {color: 'red'}).addTo(map)
        .on 'click', (e) ->
            point = positionMarker.getLatLng()
            radius = positionMarker.getRadius()
            sourceMarker.setLatLng(point)
            if sourceCircle != null
                map.removeLayer(sourceCircle)
                sourceCircle = null
            sourceCircle = L.circle(point, radius, {color: 'gray'}).addTo(map)
            if targetMarker != null
                find_route(sourceMarker.getLatLng(), targetMarker.getLatLng())

map.on 'click', (e) ->
    # don't react to map clicks after both markers have been set
    if sourceMarker? and targetMarker?
        return

    # place the marker that's missing, giving priority to the source marker
    if sourceMarker == null
        source = e.latlng
        sourceMarker = L.marker(source, {draggable: true}).addTo(map)
            .on('dragend', onSourceDragEnd)
            .bindPopup("The starting point for journey<br>(drag the marker to change)").openPopup()
    else if targetMarker == null
        target = e.latlng
        targetMarker = L.marker(target, {draggable: true}).addTo(map)
            .on('dragend', onSourceDragEnd)
            .bindPopup("The end point for journey<br>(drag the marker to change)").openPopup()

    # when the second marker has been placed, find the route between them
    # and zoom out if necessary to fit the route on the screen
    if sourceMarker? and targetMarker?
        find_route sourceMarker.getLatLng(), targetMarker.getLatLng(), (route) ->
            if not map.getBounds().contains(route.getBounds())
                map.fitBounds(route.getBounds())
