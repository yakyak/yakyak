init   = require './init.json'
conv   = require '../src/ui/models/conv'
entity = require '../src/ui/models/entity'

describe 'conv', ->

    beforeEach ->
        conv._reset()
        entity._reset()

    describe 'initFromConvStates', ->

        it 'populates lookup', ->
            added = conv._initFromConvStates init.conv_states
            eql 3, added
            c = conv['UzNxjbBsPhAAAQ']
            assert.isNotNull c
            eql 'UzNxjbBsPhAAAQ', c.conversation_id.id

        it 'populates entities with found entities', ->
            conv._initFromConvStates init.conv_states
            eql 8, entity.count()
            eql entity['10964681753'], {
                fallback_name:'John Snow'
                id:'10964681753'
            }
