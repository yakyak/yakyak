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

    describe 'list', ->

        it 'sorts by self_conversation_state.sort_timestamp', ->
            conv._reset()
            conv.add {
                conversation_id:id:'1'
                self_conversation_state:sort_timestamp:'1'
            }
            conv.add {
                conversation_id:id:'2'
                self_conversation_state:sort_timestamp:'2'
            }
            conv.add {
                conversation_id:id:'3'
                self_conversation_state:sort_timestamp:'3'
            }
            eql conv.list(), [
                {
                    conversation_id:id:'3'
                    self_conversation_state:sort_timestamp:'3'
                }
                {
                    conversation_id:id:'2'
                    self_conversation_state:sort_timestamp:'2'
                }
                {
                    conversation_id:id:'1'
                    self_conversation_state:sort_timestamp:'1'
                }
            ]
