
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

[![Build Status](https://secure.travis-ci.org/datakurre/navigator-proto.png)](http://travis-ci.org/datakurre/navigator-proto)

## Getting started ##

Node.js with NPM 1.2 or newer is required to build the project. For
Ubuntu 12.04 LTS, this can be acquired with `sudo add-apt-repository
ppa:chris-lea/node.js` followed by `sudo apt-get install nodejs`.

Install dependencies with `npm install`.

Install build tool with `sudo npm install -g grunt-cli` and run with
`grunt server`.

Or, install build tool with `npm install grunt-cli` and run dev server with
`node_modules/.bin/grunt server`.

## Running tests (on a desktop browser) ##

Install testem with `sudo npm install -g testem coffee-script`.

Run tests with `grunt test`. (This may finish early if you have Firefox 
running already.)

To use Phantomjs instead of Firefox, you can install it with 
`sudo apt-get install phantomjs` and replace `firefox` with `phantomjs` 
in `Gruntfile.coffee`.

## Running tests (on a mobile browser) ##

Tests can be run on mobile browsers at SauceLabs. (Unfortunately, the current
SauceLabs integration for testem is mostly just a hack and that's why
the current experience is quite poor.)

Install saucelauncher from source with `sudo npm install -g
git://github.com/datakurre/saucelauncher.git`.
(Once https://github.com/airportyh/saucelauncher/pull/3 has been merged and
released, you may switch back to a released version of saucelauncher.)

Add `~/.saucelabs.json` in a format:

```json
{
    "username": "mysaucelabsuserid",
    "api_key": "mysecretsaucelabsapikey"
}
```

Run tests with `grunt test-mobile`.

## Writing tests ##

Run `grunt test` at least once before (to generate working `testem.json`).

Start watching test environment with `testem`.

Follow instructions on screen to register browser with testem.

Edit test below `./tests`. Tests are run when changes in test suites are
detected.
