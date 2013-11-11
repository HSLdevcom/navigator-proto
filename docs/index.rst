City Navigator
==============

.. include:: robot.rst

.. toctree::
   :hidden:

   robot

This is how City Navigator looks like in Manchester when started:

.. figure:: navigatorwindow.png

.. code:: robotframework
   :class: hidden

   *** Test cases ***

   Show navigator window
       Go to  ${START_URL}

       # Override local_config area to manchester
       # and wait for map tiles to finish loading
       Execute Javascript
       ...    citynavi.set_config("manchester");
       ...    map_dbg.setView(citynavi.config.center, 10);
       Sleep  10 s

       Capture page screenshot  navigatorwindow.png

It automatically determines the location of the device and zooms there:

.. figure:: navigatorwindow-located.png

.. code:: robotframework
   :class: hidden

   *** Test cases ***

   Zoom to current location
       Execute Javascript
       ...    return (function(){
       ...        var lat = citynavi.config.center[0],
       ...            lng = citynavi.config.center[1],
       ...            accuracy = 100,
       ...            latAccuracy = 180 * accuracy / 40075017,
       ...            lngAccuracy = latAccuracy / Math.cos(L.LatLng.DEG_TO_RAD * lat),
       ...            bounds = L.latLngBounds(
       ...                [lat - latAccuracy, lng - lngAccuracy],
       ...                [lat + latAccuracy, lng + lngAccuracy]);
       ...        map_dbg.fire('locationfound', {
       ...            'accuracy': accuracy,
       ...            'latlng': L.latLng(lat, lng),
       ...            'bounds': bounds
       ...        });
       ...    })();
       # Wait until the zoom animation finishes
       Sleep  10 s
       Capture page screenshot  navigatorwindow-located.png

Once City Navigator has located you, just type, where you are planning to go:

.. figure:: navigatorwindow-annotated.png

.. code:: robotframework
   :class: hidden

   *** Test cases ***

   Annotate navigator window
       Assign id to element
       ...  xpath=//input[@placeholder='Where do you want to go?']
       ...  search
       ${note} =  Add note  search
       ...  Just type here, where you want to go, and wait a second for the results.
       ...  position=bottom  width=300
       Input text  search  market
       Capture page screenshot  navigatorwindow-annotated.png
       Remove elements  ${note}

And pick the right result from the list:

.. figure:: navigatorwindow-results.png

.. code:: robotframework
   :class: hidden

   *** Test cases ***

   Show search results
       Wait until element is visible
       ...  xpath=//a[contains(text(), 'Wellington Road')]
       Assign id to element
       ...  xpath=//a[contains(text(), 'Wellington Road')]
       ...  market-link
       ${note} =  Add note  market-link
       ...  Click the result to see the available routes.
       ...  position=bottom  width=300
       Capture page screenshot  navigatorwindow-results.png
       Remove elements  ${note}

That's all! Now you are ready to navigate and have fun!

.. figure:: navigatorwindow-final.png

.. code:: robotframework
   :class: hidden

   *** Test cases ***

   Show search result
       Click link  market-link
       Sleep  10 s
       Capture page screenshot  navigatorwindow-final.png
