
$(document).bind "mobileinit", ->
    if !window.console
      console =
        log: ->
      window.console = console
      $.ajaxSetup({cache: true})
      $.getScript("http://jsconsole.com/remote.js?citynavi")
     else
       window.console.log "mobileinit"
    $.mobile.defaultPageTransition = "slide"
    $.mobile.defaultHomeScroll = 0

    # non-native inputs don't work in leaflet
    $.mobile.page.prototype.options.keepNative = "form input"



$(document).ajaxStart (e) ->
    $.mobile.loading('show')

$(document).ajaxStop (e) ->
    $.mobile.loading('hide')
