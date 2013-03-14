URL_BASE = "http://dev.hel.fi:8000/api/v1/address/?format=jsonp&limit=10"



$(document).on "listviewbeforefilter", "#navigate-to-input", (e, data) ->
    console.log "autocomplete"
    val = $(data.input).val()
    console.log val
    if (!val)
        return
    $ul = $(this)
    $ul.html "<li><div class='ui-loader'><span class='ui-icon ui-icon-loading'></span></div></li>"
    $ul.listview "refresh"
    $.getJSON URL_BASE + "&name=#{ val }&callback=?", (data) ->
        objs = data.objects
        html = ''
        for adr in objs
            coords = adr.location.coordinates
            link = "#map-page?destination=#{ coords[1]},#{ coords[0] }"
            html += "<li><a href=\"#{ link }\">" + adr.name + "</a></li>"
        $ul.html html
        $ul.listview "refresh"
        $ul.trigger "updatelayout"
