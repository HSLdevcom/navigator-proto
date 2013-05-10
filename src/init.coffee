
$(document).bind "mobileinit", ->

    # Handle situations where there is no console or some console functions do not exist,
    # partly based on code at:
    # http://www.getallfix.com/2013/03/avoid-console-errors-in-browsers-that-lack-a-console-html5-boilerplate/
    if !window.console
      console =       
        log: -> 
        assert: -> 
      window.console = console
      methods = [  
        'clear', 'count', 'debug', 'dir', 'dirxml', 'error',  
        'exception', 'group', 'groupCollapsed', 'groupEnd', 'info',
        'markTimeline', 'profile', 'profileEnd', 'table', 'time', 'timeEnd',  
        'timeStamp', 'trace', 'warn']
      for method in methods
        do (method) ->
          console[method] = ->
      $.ajaxSetup({cache: true})
      $.getScript "http://jsconsole.com/remote.js?citynavi", (data, textStatus, jqxhr) ->
        for method in methods
          do (method) ->
          if !window.console[method]
            window.console[method] = ->
        if !window.console['assert']
          window.console['assert'] = (condition) ->
            if !condition
              window.console.log "Assertion failed"
              throw new Error
        window.console.log "mobileinit, using jsconsole.com"
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
