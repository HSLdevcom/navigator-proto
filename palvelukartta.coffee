pk_base_url = 'http://www.hel.fi/palvelukarttaws/rest/v2/'

#get_pk_object = (url, callback) ->
#    $.getJSON(pk_base_url + url + '?callback=?', callback)

class Service extends Backbone.Model
    initialize: ->
        @ls_key = "pk_service_" + @id
    load_from_cache: ->
        attrs = localStorage[@ls_key]
        if not attrs
            return false
        return JSON.parse attrs
    get_children: ->
        child_list = []
        for id in @.get 'child_ids'
            child = @collection.get id
            child_list.push child
        return child_list
    save: ->
        if not localStorage
            return
        attrs = @.toJSON()
        #delete attrs['unit_ids']
        str = JSON.stringify attrs
        localStorage[@ls_key] = str

class ServiceList extends Backbone.Collection
    model: Service
    url: pk_base_url + 'service/'
    initialize: ->
        @.on "reset", @.handle_reset

    handle_reset: ->
        @.find_parents()
        @.root_list = srv_list.filter (srv) ->
            return not srv.get('parent')

    find_parents: ->
        @.forEach (srv) =>
            if not srv.get('child_ids')
                return
            for child_id in srv.get('child_ids')
                child = @.get(child_id)
                if not child
                    console.log "child #{ child_id } missing"
                else
                    child.set('parent', srv.id)
    save_to_cache: ->
        root_ids = @.root_list.map (srv) ->
            return srv.id
        if localStorage
            localStorage["pk_service_root"] = JSON.stringify(root_ids)
        @.forEach (srv) ->
            srv.save()
    load_from_cache: ->
        console.log "load cache"
        if not localStorage
            return false
        srv_root = localStorage["pk_service_root"]
        if not srv_root
            return false
        root_ids = JSON.parse(srv_root)
        srv_list = []
        for id in root_ids
            srv = new Service {id: id}
            srv_attrs = srv.load_from_cache()
            if not srv_attrs
                return false
            console.log srv_attrs
            srv_list.push srv_attrs
        console.log srv_list
        @.reset srv_list
        return true

    sync: (method, collections, options) ->
        options.dataType = 'jsonp'
        super

class ServiceListView extends Backbone.View
    tagName: 'ul'
    attributes:
        'data-role': 'listview'
    initialize: (opts) ->
        @parent_id = opts.parent_id
        @.listenTo @collection, "reset", @.render
    render: ->
        console.log "serviceview render"
        if not @parent_id
            srv_list = @collection.filter (srv) ->
                if not srv.parent
                    return true
        else
            srv_list = @collection.filter (srv) ->
                if srv.parent == @parent_id
                    return true
        @$el.empty()
        srv_list.forEach (srv) =>
            srv_name = srv.get 'name_fi'
            srv_el = $("<li>#{ srv_name }</li>")
            @$el.append srv_el

        page = $("#find-nearest")
        content = page.children(":jqmData(role=content)")
        content.empty()
        content.append(@$el)
        page.page()
        @$el.listview()
        $.mobile.changePage(page)

root_list = null
srv_list = new ServiceList
srv_list_view = new ServiceListView {collection: srv_list}

show_categories = (options) ->
    if not srv_list.load_from_cache()
        srv_list.fetch
            success: ->
                srv_list.save_to_cache()

$(document).bind("pagebeforechange", (e, data) ->
    if typeof data.toPage != "string"
        return
    u = $.mobile.path.parseUrl(data.toPage)
    if u.hash != '#find-nearest'
        return
    e.preventDefault()
    show_categories()
)

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

    map.locate
        setView: false
        maxZoom: 15
        watch: true
        timeout: Infinity
        enableHighAccuracy: true

window.map = map = L.map('map', {minZoom: 10, zoomControl: false})
    .setView([60.29532, 24.93073], 10)

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

routeLayer = null

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
        window.data = data

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
        window.data = data

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

positionMarker = sourceMarker = targetMarker = null
sourceCircle = null

map.on 'locationfound', (e) ->
#    radius = e.accuracy / 2
    radius = e.accuracy
    measure = if e.accuracy < 2000 then "#{Math.round(e.accuracy)} meters" else "#{Math.round(e.accuracy/1000)} km"
    point = e.latlng

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
        find_route sourceMarker.getLatLng(), target, (route) ->
            if not map.getBounds().contains(route.getBounds())
                map.fitBounds(route.getBounds())
