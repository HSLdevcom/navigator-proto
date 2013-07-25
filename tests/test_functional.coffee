# Test runner is Mocha: http://visionmedia.github.io/mocha/
# Assertion library is Chai: http://chaijs.com/

do chai.should

afterEach (done)->
    if $.mobile.activePage.attr("id") == "front-page"
        done()
        return
    jQuery.mobile.changePage '#front-page'
    jQuery('#front-page').bind 'pageshow', (event)->
        jQuery(this).unbind(event)
        done()
# FIXME try to reset all state


describe 'jQuery is loaded', ->
    it 'should be Function', ->
        jQuery.should.be.a 'Function'

describe 'App is loaded', ->
    it 'should have title', ->
        jQuery('h1.ui-title').filter(":visible").length.should.equal(1)
    it 'should have title "Navigator"', ->
        jQuery('h1.ui-title').filter(":visible").text().should.equal('Navigator')

describe 'Find nearest services.', ->
    describe 'Choose "Find nearest services" from the front page.', ->
        beforeEach (done)->
            jQuery('a[href="#service-directory?"]').click()
            jQuery('#service-directory').bind 'pageshow', (event)->
                $(this).unbind(event)
                done()
        it 'Should have title "Find nearest services".', ->
            jQuery('h1.ui-title').filter(":visible").text().should.equal('Find nearest services')
        it 'Should have back button.', ->
            jQuery('a[data-rel="back"]').filter(":visible").length.should.equal(1)
        it 'Back button should return to Front Page.', (done)->
            jQuery('a[data-rel="back"]').filter(":visible").click()
            jQuery('#front-page').bind 'pageshow', (event)->
                jQuery(this).unbind(event)
                done()
    describe 'Choose Restaurant category from the service directory.', ->
        beforeEach (done)->
            jQuery('a[href="#service-directory?"]').click()
            jQuery('#service-directory').bind 'pageshow', (event)->
                $(this).unbind(event)
                done()
###
        beforeEach (done)->
            jQuery('a[href="#service-list?category=0"]').click()
            jQuery('#service-list').bind 'pageshow', (event)->
                $(this).unbind(event)
                done()
        it 'Should have title "Nearest services".', ->
            jQuery('h1.ui-title').filter(":visible").text().should.equal('Nearest services')
        it 'Should have back button.', ->
            jQuery('a[data-rel="back"]').filter(":visible").length.should.equal(1)
        it 'Back button should return to "Find nearest services" Page.', (done)->
            jQuery('a[data-rel="back"]').filter(":visible").click()
            jQuery('#front-page').bind 'pageshow', (event)->
                jQuery(this).unbind(event)
                done()
###

describe 'Browse a map.', ->
    describe 'Choose "Browse map" from the front page.', ->
        beforeEach (done)->
            jQuery('a[href="#map-page"]').click()
            jQuery('#service-directory').bind 'pageshow', (event)->
                $(this).unbind(event)
                done()
        describe 'Tap a location to get directions', ->
            it 'Should show fastest route to the destination.'

describe 'Settings', ->
    beforeEach (done)->
        jQuery('a[href="#settings"]').click()
        jQuery('#settings').bind 'pageshow', (event)->
            $(this).unbind(event)
            done()
    it 'Should have title "Settings".', ->
        jQuery('h1.ui-title').filter(":visible").text().should.equal('Settings')
    it 'Should have back button.', ->
        jQuery('a[data-rel="back"]').filter(":visible").length.should.equal(1)
    it 'Back button should return to Front Page.', (done)->
        jQuery('a[data-rel="back"]').filter(":visible").click()
        jQuery('#front-page').bind 'pageshow', (event)->
            jQuery(this).unbind(event)
            done()

describe 'Feature: Get directions when typing address.', ->
    describe 'Typed in a destination address piccadilly.', ->
        it 'Should suggest Piccadilly as a destination.'
