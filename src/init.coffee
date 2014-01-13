if !window.console
    console = {}
    window.console = console
    methods = [
        'assert', 'clear', 'count', 'debug', 'dir', 'dirxml', 'error',
        'exception', 'group', 'groupCollapsed', 'groupEnd', 'info', 'log',
        'markTimeline', 'profile', 'profileEnd', 'table', 'time', 'timeEnd',
        'timeStamp', 'trace', 'warn']
    for method in methods
        do (method) ->
            console[method] = ->

# mobileinit event is triggered by jQuery Mobile when it starts
$(document).bind "mobileinit", ->
    window.console.log "mobileinit"
    $.mobile.defaultPageTransition = "slide"
    # Prevent automatic scrolling to the top of the page when navigating to a new page
    $.mobile.defaultHomeScroll = 0

    # init offline routing module if available
    window.citynavi.reach = reach?.Api.init()

    # non-native inputs don't work in leaflet
    $.mobile.page.prototype.options.keepNative = "form input"

# Show page loading message for user when making AJAX call and hide the message after (all)
# AJAX requests have completed
$(document).ajaxStart (e) ->
    $.mobile.loading('show')

$(document).ajaxStop (e) ->
    $.mobile.loading('hide')

class CityNavigator
    constructor: (opts) ->
        @source_location = null
        @simulation_time = null
        @itinerary = null
        _.extend @, opts # Use underscore.js to exten the CityNavigator with the opts
    get_source_location: ->
        return @source_location
    get_source_location_or_area_center: ->
        return @source_location or @config.center
    set_source_location: (loc) ->
        @source_location = loc
    set_simulation_time: (time) ->
        @simulation_time = time
    time: ->
        return @simulation_time or moment()
    get_itinerary: ->
        return @itinerary
    set_itinerary: (itinerary) ->
        @itinerary = itinerary

# The area for which the city-navigator is configured to.
window.citynavi = new CityNavigator()
