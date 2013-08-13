# This file is not used anymore.

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
        for id in @get 'child_ids'
            child = @collection.get id
            child_list.push child
        return child_list
    save: ->
        if not localStorage
            return
        attrs = @toJSON()
        #delete attrs['unit_ids']
        str = JSON.stringify attrs
        localStorage[@ls_key] = str

class ServiceList extends Backbone.Collection
    model: Service
    url: citynavi.config.hel_servicemap_service_url
    initialize: ->
        @on "reset", @handle_reset

    handle_reset: ->
        @find_parents()
        @root_list = srv_list.filter (srv) ->
            return not srv.get('parent')

    find_parents: ->
        @forEach (srv) =>
            if not srv.get('child_ids')
                return
            for child_id in srv.get('child_ids')
                child = @get(child_id)
                if not child
                    # console.log "child #{ child_id } missing"
                else
                    child.set('parent', srv.id)
    save_to_cache: ->
        root_ids = @root_list.map (srv) ->
            return srv.id
        if localStorage
            localStorage["pk_service_root"] = JSON.stringify(root_ids)
        @forEach (srv) ->
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
            # console.log srv_attrs
            srv_list.push srv_attrs
        # console.log srv_list
        @reset srv_list
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
        @listenTo @collection, "reset", @render
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
            srv_name = srv.get 'name_en'
            srv_id = srv.get 'id'
            srv_el = $("<li><a href='#map-page?service=#{srv_id}'>#{ srv_name }</a></li>")
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

$(document).bind "pagebeforechange", (e, data) ->
    if typeof data.toPage != "string"
        return
    u = $.mobile.path.parseUrl(data.toPage)
    if u.hash == '#find-nearest'
        e.preventDefault()
        show_categories()
