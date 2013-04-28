# Test runner is Mocha: http://visionmedia.github.io/mocha/
# Assertion library is Chai: http://chaijs.com/

do chai.should

describe 'jQuery is loaded', ->
  it 'should be Function', ->
    jQuery.should.be.a 'Function'

describe 'App is loaded', ->
  it 'should have title', ->
    jQuery('h1.ui-title').length.should.equal(1)
  it 'should have title "City Navigator"', ->
    jQuery('h1.ui-title').text().should.equal('City Navigator')
