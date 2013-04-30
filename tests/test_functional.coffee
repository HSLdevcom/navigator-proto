# Test runner is Mocha: http://visionmedia.github.io/mocha/
# Assertion library is Chai: http://chaijs.com/

do chai.should


describe 'jQuery is loaded', ->
  it 'should be Function', ->
    jQuery.should.be.a 'Function'

describe 'App is loaded', ->
  it 'should have title', ->
    jQuery('h1.ui-title').filter(":visible").length.should.equal(1)
  it 'should have title "City Navigator"', ->
    jQuery('h1.ui-title').filter(":visible").text().should.equal('City Navigator')

describe 'Find nearest services', ->
  before (done)->
    jQuery('a[href="#service-directory?"]').click()
    jQuery('#service-directory').bind 'pageshow', (event)->
      $(this).unbind(event)
      done()
  it 'should have title "Find nearest services"', ->
    jQuery('h1.ui-title').filter(":visible").text().should.equal('Find nearest services')

afterEach (done)-> 
  if $.mobile.activePage.attr("id") == "front-page"
    done()
    return
  jQuery.mobile.changePage '#front-page'
  jQuery('#front-page').bind 'pageshow', (event)->
    jQuery(this).unbind(event)
    done()
# FIXME try to reset all state

