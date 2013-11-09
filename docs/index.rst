City Navigator
==============

.. include:: robot.rst

.. toctree::
   :hidden:

   robot

This is how City Navigator looks like:

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

In detail:

.. figure:: navigatorwindow-annotated.png

.. code:: robotframework
   :class: hidden

   Annotate navigator window
       Assign id to element
       ...  xpath=//input[@placeholder='Where do you want to go?']
       ...  search
       ${note} =  Add pointy note  search
       ...  Just type here, where do you want to go, and press enter.
       ...  position=bottom  width=300
       Input text  search  market
       Capture page screenshot  navigatorwindow-annotated.png
       Remove elements  ${note}

And in action:

.. figure:: navigatorwindow-results.png

.. code:: robotframework
   :class: hidden

   Show search results
       Wait until element is visible
       ...  xpath=//a[contains(text(), 'Wellington Road')]
       Assign id to element
       ...  xpath=//a[contains(text(), 'Wellington Road')]
       ...  market-link
       Capture page screenshot  navigatorwindow-results.png

More...

.. figure:: navigatorwindow-final.png

.. code:: robotframework
   :class: hidden

   Show search result
       Click link  market-link
       Sleep  10 s
       Capture page screenshot  navigatorwindow-final.png
