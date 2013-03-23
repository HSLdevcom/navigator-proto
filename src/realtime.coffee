class Realtime
    constructor: ->
        @client = new Faye.Client 'http://dev.hsl.fi:9002/faye'
        @subs = {}
    subscribe_route: (route_id, callback, callback_args) ->
        if @subs[route_id]
            @.unsubscribe_route route_id
        route_path = route_id.replace(/\ /g, "_").replace(/:/g, "-")
        path = "/location/#{citynavi.config.area.id}/#{route_path}/**"
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
