class Realtime
    constructor: ->
        # Create Faye client that connects to the navigator-server
        @client = new Faye.Client citynavi.config.faye_url
        @subs = {}
    # Called from routing.coffee render_route_layer function when a new route
    # suggestion is given to the user that includes also legs other than walking
    # FIXME seems that routes are never unsubscribed unless the subscribe_route
    # id is called again with the route_id that has been subscribed earlier.
    subscribe_route: (route_id, callback, callback_args) ->
        if @subs[route_id]
            @unsubscribe_route route_id
        # Replace all spaces with "_" and all ":" with "-".
        route_path = route_id.replace(/\ /g, "_").replace(/:/g, "-")
        # The path/channel that returns any vehicles for the route_id.
        path = "/location/#{citynavi.config.id}/#{route_path}/**"
        # Subscribe messages from the path/channel and call callback
        # function defined in render_route_layer in routing.coffee
        # when there is a message.
        sub = @client.subscribe path, (message) ->
            callback message, callback_args
        @subs[route_id] = sub
    unsubscribe_route: (route_id) ->
        if not @subs[route_id]
            return
        @subs[route_id].cancel()
        delete @subs[route_id]

citynavi.realtime = new Realtime

#citynavi.realtime.subscribe_route "1004", (msg) ->
#    console.log "route 1004"
#    console.log msg
