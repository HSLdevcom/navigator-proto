
# mobileinit event is triggered by jQuery Mobile when it starts
$(document).bind "mobileinit", ->
    console.log "mobileinit"
    $.mobile.defaultPageTransition = "slide"
    # Prevent automatic scrolling to the top of the page when navigating to a new page 
    $.mobile.defaultHomeScroll = 0

    # non-native inputs don't work in leaflet
    $.mobile.page.prototype.options.keepNative = "form input"

# Show page loading message for user when making AJAX call and hide the message after (all)
# AJAX requests have completed
$(document).ajaxStart (e) ->
    $.mobile.loading('show')

$(document).ajaxStop (e) ->
    $.mobile.loading('hide')

