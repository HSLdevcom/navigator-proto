
## City Navigator proto ##

Like a car navigator but for taking public transport, based on Open Data.

Demo installation at http://dev.hsl.fi/navigator-proto

Use cases:
1. Type in a destination address and get directions from the current location.
2. Choose a public service by category and get directions to closest premises.
3. Browse a map and tap a location to get directions.

Features:
* Current location is queried from the device automatically.
* Destination addresses are completed as you type.
* Current location is updated on the map as the device moves.
* Directions can be updated by tapping the current location.

Open Data used:
* OpenStreetMap
* Public transport timetables by Helsinki Region Transport
* Service Map by City of Helsinki
* House address database by City of Helsinki

Technologies used: HTML5, Geolocation, Local storage

Libraries used: jQuery Mobile, Leaflet, Backbone.js, Moment.js

## Getting started ##

Node.js with NPM 1.2 or newer is required to build the project. For
Ubuntu 12.04 LTS, this can be acquired with `sudo add-apt-repository
ppa:chris-lea/node.js` followed by `sudo apt-get install npm`.

Install dependencies with `npm install`.

Install build tool with `sudo npm install -g grunt-cli` and run with
`grunt server`.

Or, install build tool with `npm install grunt-cli` and run dev server with
`node_modules/.bin/grunt server`.

## Running tests ##

Run tests with `grunt test'.

## Writing tests ##

Install testem cli with `sudo npm install -g testem`.

Run 'grunt test' at least once before (to generate `testem.json`).

Start watching test environment with `testem`.

Follow instructions on screen to register browser with testem.

Edit test below `./tests`. Tests are run when changes in test suites are
detected.
