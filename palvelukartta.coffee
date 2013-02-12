pk_base_url = 'http://www.hel.fi/palvelukarttaws/rest/v2/'
cat_tree = null

localStorage.clear()

render_categories = (options) ->
    console.log "render cats"
    console.log cat_tree.length
    page = $("#find-nearest")
    content = page.children(":jqmData(role=content)")
    content.empty()
    list_el = $("<ul data-role='listview'></ul>")
    for cat in cat_tree
        item_el = $("<li>#{ cat.name_fi }</li>")
        child_list = $("<ul></ul>")
        item_el.append(child_list)
        for child in cat.children
            child_list.append($("<li>#{ child.name_fi }</li>"))
        list_el.append(item_el)
    content.append(list_el)
    page.page()
    list_el.listview()
    $.mobile.changePage(page, options)

show_categories = (options) ->
    cat_tree = null
    if localStorage
        if localStorage.cat_tree
            cat_tree = JSON.parse(localStorage.cat_tree)
    if cat_tree
        render_categories(options)
    else
        fetch_categories(options)

fetch_categories = (options) ->
    $.mobile.showPageLoadingMsg()
    $.getJSON(pk_base_url + 'servicetree/?callback=?', (data) ->
        $.mobile.hidePageLoadingMsg()
        cat_tree = data
        localStorage.cat_tree = JSON.stringify(cat_tree)
        render_categories(options)
    )

$(document).bind("pagebeforechange", (e, data) ->
    console.log "here"
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

find_route = (latlng) ->
    window.latlng = latlng
    $.getJSON("http://tuukka.kapsi.fi/tmp/reittiopas.cgi?request=route&detail=full&epsg_in=wgs84&epsg_out=wgs84&from="+latlng.lng+","+latlng.lat+"&to=24.97192,60.19308&callback=?", (data) ->
        window.data = data

        legs = data[0][0].legs
        for leg in legs
            points = (new L.LatLng(point.y, point.x) for point in leg.shape)
            color = transportColors[leg.type]
            polyline = new L.Polyline(points, {color: color})
            polyline.addTo(map)
            if leg == legs[0]
                map.fitBounds(polyline.getBounds())
    )

L.tileLayer('http://{s}.tile.cloudmade.com/{key}/22677/256/{z}/{x}/{y}.png', {
    attribution: 'Map data &copy; 2011 OpenStreetMap contributors, Imagery &copy; 2012 CloudMade',
    key: 'BC9A493B41014CAABB98F0471D759707'
}).addTo(map);
map.locate({setView: true, maxZoom: 16});
onLocationFound = (e) ->
    radius = e.accuracy / 2;
    L.marker(e.latlng).addTo(map)
        .bindPopup("You are within " + radius + " meters from this point").openPopup();
    L.circle(e.latlng, radius).addTo(map);
    find_route(e.latlng);
map.on('locationfound', onLocationFound);
