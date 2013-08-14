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

[![Build Status](https://secure.travis-ci.org/codeforeurope/navigator-proto.png)](http://travis-ci.org/codeforeurope/navigator-proto)

## Getting started ##

Node.js with NPM 1.2 or newer is required to build the project. For
Ubuntu 12.04 LTS, this can be acquired with
`sudo add-apt-repository ppa:chris-lea/node.js` followed by `sudo apt-get install nodejs`.
If for some reason you want to build and install Node.js from sources see:
https://github.com/HSLdevcom/hsl-navigator/wiki/Building-node-from-sources

After installing Node.js go to the directory where you want to install the City Navigator.
There, run `git clone https://github.com/codeforeurope/navigator-proto.git`. 

In the navigator-proto directory install dependencies with `npm install`.

Install build tool with `sudo npm install -g grunt-cli`. Run
`grunt server` and if everything goes well open
http://localhost:9001/ with your web browser.

Or, install build tool with `npm install grunt-cli` and run dev server with
`node_modules/.bin/grunt server`.

If you encounter errors, you may want to run commands `sudo apt-get dist-upgrade` and
`sudo apt-get update` to make sure everything is up-to-date.

You may want to change some settings, for example the city where the navigating is
supposed to happen. To do so, run
`cp src/local_config.coffee.template src/local_config.coffee` and modify
`src/local_config.coffee` according to the comments within the file.

## Running tests ##

Install testem with `sudo npm install -g testem coffee-script`. Install
the headless browser Phantomjs with `sudo apt-get install phantomjs`.

Run tests with `grunt test`.

### Local desktop browsers ###

To test on Firefox and Chromium, run `grunt test-desktop`.

To test on a different set of browsers, you can edit the option
`testem.desktop.options.launch_in_ci` in `Gruntfile.coffee`.

### Mobile browsers at Saucelabs ###

Tests can be run on mobile browsers at SauceLabs. (Unfortunately, the current
SauceLabs integration for testem is mostly just a hack and that's why
the current experience is quite poor.)

Install saucelauncher from source with `sudo npm install -g saucelauncher`.

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

## Running Robot Framework tests ##

Run ``python bootstrap.py --version 2.1.1`` and ``bin/buildout``.

Run ``grunt test-robot-desktop``.
