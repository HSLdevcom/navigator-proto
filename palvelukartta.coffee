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

$(document).bind("mobileinit", ->
    $.mobile.defaultPageTransition = "slide"
    $.mobile.defaultHomeScroll = 0
)

$('#map-page').bind 'pageshow', (e, data) ->
    height = window.innerHeight-$('[data-role=header]').height()-
                                $('[data-role=footer]').height()-
                                $('[data-role=listview]').height()
    $('#map').height(height-11)

map = L.map('map'); # .setView([60.19308, 24.97192], 11);

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

find_route = (latlng) ->
    window.latlng = latlng
    $.getJSON("http://tuukka.kapsi.fi/tmp/reittiopas.cgi?request=route&detail=full&epsg_in=wgs84&epsg_out=wgs84&from="+latlng.lng+","+latlng.lat+"&to=24.97192,60.19308&callback=?", (data) ->
        window.data = data

        legs = data[0][0].legs
        for leg in legs
            points = (new L.LatLng(point.y, point.x) for point in leg.shape)
            color = transportColors[leg.type]
            polyline = new L.Polyline(points, {color: color})
                .on 'click', (e) ->
                    map.fitBounds(e.target.getBounds())
            polyline.addTo(map)
            if leg.type != 'walk'
                stop = leg.locs[0]
                last_stop = leg.locs[leg.locs.length-1]
                point = leg.shape[0]
                L.marker(new L.LatLng(point.y, point.x)).addTo(map)
                    .bindPopup("At time #{format_time(stop.depTime)}, take the line #{format_code(leg.code)} from stop #{stop.name} to stop #{last_stop.name}")
            if leg == legs[0]
                map.fitBounds(polyline.getBounds())
    )

L.tileLayer('http://{s}.tile.cloudmade.com/{key}/22677/256/{z}/{x}/{y}.png', {
    attribution: 'Map data &copy; 2011 OpenStreetMap contributors, Imagery &copy; 2012 CloudMade',
    key: 'BC9A493B41014CAABB98F0471D759707'
}).addTo(map);
L.control.scale().addTo(map);
map.locate({setView: true, maxZoom: 16});
onLocationFound = (e) ->
    radius = e.accuracy / 2;
    L.marker(e.latlng).addTo(map)
        .bindPopup("You are within " + radius + " meters from this point").openPopup();
    L.circle(e.latlng, radius).addTo(map);
    find_route(e.latlng);
map.on('locationfound', onLocationFound);
