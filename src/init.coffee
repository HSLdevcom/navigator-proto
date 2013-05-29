
$(document).bind "mobileinit", ->

    # Handle situations where there is no console, partly based on code at:
    # http://www.getallfix.com/2013/03/avoid-console-errors-in-browsers-that-lack-a-console-html5-boilerplate/ and utilizing stacktrace.js: https://github.com/eriwen/javascript-stacktrace
    # If the client web browser does not have a console then use jsconsole.com
    if !window.console
      # Define console methods as empty functions. console.assert is defined as empty separately
      # because it is later defined as non empty if it has not been defined by jsconsole.com
      console =       
        assert: -> 
      window.console = console
      methods = [  
        'clear', 'count', 'debug', 'dir', 'dirxml', 'error',  
        'exception', 'group', 'groupCollapsed', 'groupEnd', 'info', 'log',
        'markTimeline', 'profile', 'profileEnd', 'table', 'time', 'timeEnd',  
        'timeStamp', 'trace', 'warn']
      for method in methods
        do (method) ->
          console[method] = ->
      $.ajaxSetup({cache: true})
      # Try to connect to http://jsconsole.com/remote.js?citynavi. For connection to be succesful,
      # at first go to http://jsconsole.com with your desktop web browser and write command
      # :listen citynavi
      $.getScript "http://jsconsole.com/remote.js?citynavi", (data, textStatus, jqxhr) ->
        # Undefined methods are defined as empty functions        
        for method in methods
          do (method) ->
          if !window.console[method]
            window.console[method] = ->
        # If assert is undefined, define it and utilize stacktrace.js library
        if !window.console['assert']
          window.console['assert'] = (condition) ->
            if !condition
              window.console.log "Assertion failed"
              try
                throw new Error
              catch e
                lastError = e;
                window.console.log printStackTrace({e: lastError});
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
