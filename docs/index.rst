City Navigator
==============

.. include:: robot.rst

.. toctree::
   :hidden:

   robot

This is how City Navigator looks like when started:

.. figure:: navigatorwindow.png

.. code:: robotframework
   :class: hidden

   *** Test cases ***

   Show navigator window
       Go to  ${START_URL}

       Execute Javascript
       ...    return (function(){
       ...        map_dbg.fire('locationfound', {
       ...            'accuracy': 100,
       ...            'latlng': L.latLng(citynavi.config.center),
       ...            'bounds': L.latLngBounds(citynavi.config.bbox_sw,
       ...                                     citynavi.config.bbox_ne)
       ...        });
       ...    })();

       Capture page screenshot  navigatorwindow.png

Once City Navigator has located you, just type, where are you planning to go:

.. figure:: navigatorwindow-annotated.png

.. code:: robotframework
   :class: hidden

   Annotate navigator window
       Assign id to element
       ...  xpath=//input[@placeholder='Where do you want to go?']
       ...  search
       ${note} =  Add note  search
       ...  Just type here, where do you want to go, and wait a second for the results.
       ...  position=bottom  width=300
       Input text  search  market
       Capture page screenshot  navigatorwindow-annotated.png
       Remove elements  ${note}

And pick the right result form the list:

.. figure:: navigatorwindow-results.png

.. code:: robotframework
   :class: hidden

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

   Show search result
       Click link  market-link
       Sleep  10 s
       Capture page screenshot  navigatorwindow-final.png
