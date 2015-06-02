init   = require './init.json'
conv   = require '../src/ui/models/conv'
entity = require '../src/ui/models/entity'

describe 'conv', ->

    beforeEach ->
        conv._reset()
        entity._reset()
        conv._initFromConvStates init.conv_states

    describe 'count', ->

        it 'counts total', ->
            eql 35, conv.count()

    describe 'unread', ->

        it 'counts number of unread messages', ->
            ur = conv.unread conv['UgzqukQGmQRb3lSSTgR4AaABAQ']
            eql 19, ur
