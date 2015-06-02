# just so that fnuc loads before we redefine eql
require 'hangupsjs'

global.chai   = require 'chai'

chai.use require 'sinon-chai'
sinon  = require 'sinon'

global.stub   = sinon.stub
global.spy    = sinon.spy
global.assert = chai.assert
global.eql    = chai.assert.deepEqual

# trifl globals
global.updated = ->
global.action = ->

# dummy localStorage
global.localStorage = {}
