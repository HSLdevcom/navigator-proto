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
       Add pointy note  search
       ...  Just type here, where do you want to go, and press enter.
       ...  position=bottom  width=300
       Capture page screenshot  navigatorwindow-annotated.png

.. robotframework::
   :creates: navigatorwindow.png
