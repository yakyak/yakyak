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
            eql 35, added
            c = conv['UgyjzlZlPiaXi5r-rGd4AaABAQ']
            assert.isNotNull c
            eql 'UgyjzlZlPiaXi5r-rGd4AaABAQ', c.conversation_id.id

        it 'populates entities with found entities', ->
            conv._initFromConvStates init.conv_states
            eql 326, entity.count()
            eql entity['110994664963851875523'], {
                fallback_name:'Martin Algesten'
                id:'110994664963851875523'
            }
