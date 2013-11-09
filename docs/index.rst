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
       Page should contain  Search done.
       Capture page screenshot  navigatorwindow-results.png

More...

.. figure:: navigatorwindow-result.png

.. code:: robotframework
   :class: hidden

   Show search result
       Click link  xpath=//a[contains(text(), 'Wellington Road')]
       Page should contain  Let's go
       Capture page screenshot  navigatorwindow-result.png
