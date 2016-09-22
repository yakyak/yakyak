init   = require './init.json'
conv   = require '../src/ui/models/conv'
entity = require '../src/ui/models/entity'

describe 'conv', ->

    beforeEach ->
        conv._reset()
        entity._reset()

    describe 'count', ->

        it 'counts total', ->
            conv._initFromConvStates init.conv_states
            eql 3, conv.count()

    describe 'unread', ->

        it 'counts number of unread messages', ->
            conv._initFromConvStates init.conv_states
            ur = conv.unread conv['UxCZCVrfhlAAAQ']
            eql 20, ur

    describe 'list', ->

        it 'sorts by self_conversation_state.sort_timestamp', ->
            conv.add {
                conversation_id:id:'1'
                self_conversation_state:sort_timestamp:1
            }
            conv.add {
                conversation_id:id:'2'
                self_conversation_state:sort_timestamp:2
            }
            conv.add {
                conversation_id:id:'3'
                self_conversation_state:sort_timestamp:3
            }
            eql conv.list(), [
                {
                    conversation_id:id:'3'
                    self_conversation_state:sort_timestamp:3
                }
                {
                    conversation_id:id:'2'
                    self_conversation_state:sort_timestamp:2
                }
                {
                    conversation_id:id:'1'
                    self_conversation_state:sort_timestamp:1
                }
            ]

    describe 'addChatMessage', ->


        it 'adds the message to conv.event and updates sort_timestamp', ->
            conv.add {
                conversation_id:id:'1'
                self_conversation_state:sort_timestamp:1
                event:[{another:'event'}]
            }
            conv.addChatMessage {
                conversation_id:id:'1'
                timestamp:2
                event_id:'e1'
                chat_message:message_content:{}
            }
            eql conv['1'], {
                conversation_id:id:'1'
                event:[
                    {another:'event'}
                    {
                        conversation_id:id:'1'
                        timestamp:2
                        event_id:'e1'
                        chat_message:message_content:{}
                    }
                ]
                self_conversation_state:sort_timestamp:2
            }

        it 'creates a skeletal conv if none exists', ->
            conv.addChatMessage {
                conversation_id:id:'1'
                timestamp:2
                event_id:'e1'
                chat_message:message_content:{}
            }
            eql conv['1'], {
                conversation_id:id:'1'
                event:[
                    {
                        conversation_id:id:'1'
                        timestamp:2
                        event_id:'e1'
                        chat_message:message_content:{}
                    }
                ]
                self_conversation_state:sort_timestamp:2
            }

        it 'replaces entries based on client_generated_id', ->
            conv.add {
                conversation_id:id:'1'
                self_conversation_state:sort_timestamp:1
                event:[
                    {keep:'me'}
                    {
                        replace:'me'
                        self_event_state:client_generated_id:'123'
                    }
                ]
            }
            conv.addChatMessage {
                conversation_id:id:'1'
                timestamp:2
                event_id:'e1'
                self_event_state:client_generated_id:'123'
            }
            eql conv['1'], {
                conversation_id:id:'1'
                event:[
                    {keep:'me'}
                    {
                        conversation_id:id:'1'
                        timestamp:2
                        event_id:'e1'
                        self_event_state:client_generated_id:'123'
                    }
                ]
                self_conversation_state:sort_timestamp:2
            }

    describe 'addWatermark', ->

        it 'adds a watermark for any participant', ->
            conv.add {
                conversation_id:id:'1'
                self_conversation_state:self_read_state:latest_read_timestamp:1
            }
            conv.addWatermark {
                conversation_id:id:'1'
                participant_id:
                    chat_id:'b'
                    gaia_id:'b'
                latest_read_timestamp:2
            }
            eql conv['1'], {
                conversation_id:id:'1'
                read_state:[
                    {
                        participant_id:
                            chat_id:'b'
                            gaia_id:'b'
                        latest_read_timestamp:2
                    }
                ]
                self_conversation_state:self_read_state:latest_read_timestamp:1
            }

        it 'updates self_conversation_state.self_read_state.latest_read_timestamp if self', ->
            entity._initFromSelfEntity {
                id:
                    gaia_id: "a"
                    chat_id: "a"
                properties:display_name:"Martin Algesten"
            }
            conv.add {
                conversation_id:id:'1'
                self_conversation_state:self_read_state:latest_read_timestamp:1
            }
            conv.addWatermark {
                conversation_id:id:'1'
                participant_id:
                    chat_id:'a'
                    gaia_id:'a'
                latest_read_timestamp:2
            }
            eql conv['1'], {
                conversation_id:id:'1'
                read_state:[
                    {
                        participant_id:
                            chat_id:'a'
                            gaia_id:'a'
                        latest_read_timestamp:2
                    }
                ]
                self_conversation_state:self_read_state:latest_read_timestamp:2
            }

        it 'packs the conv.read_state if length > 200', ->
            conv.add {
                conversation_id:id:'1'
                self_conversation_state:self_read_state:latest_read_timestamp:1
            }
            for i in [0...50]
                for u in ['a','b','c','d']
                    conv.addWatermark {
                        conversation_id:id:'1'
                        participant_id:
                            chat_id:u
                            gaia_id:u
                        latest_read_timestamp:i
                    }
            eql conv['1']?.read_state?.length, 200
            conv.addWatermark {
                conversation_id:id:'1'
                participant_id:
                    chat_id:'a'
                    gaia_id:'a'
                latest_read_timestamp:200
            }
            eql conv['1']?.read_state?.length, 4
            eql conv['1'].read_state, [
                {
                    participant_id:
                        chat_id:'b'
                        gaia_id:'b'
                    latest_read_timestamp: 49
                }
                {
                    participant_id:
                        chat_id:'c'
                        gaia_id:'c'
                    latest_read_timestamp: 49
                }
                {
                    participant_id:
                        chat_id:'d'
                        gaia_id:'d'
                    latest_read_timestamp: 49
                }
                {
                    participant_id:
                        chat_id:'a'
                        gaia_id:'a'
                    latest_read_timestamp: 200
                }
            ]

    describe 'isQuiet', ->

        it 'checks if the given conv is quiet', ->
            conv._initFromConvStates init.conv_states
            eql conv.isQuiet(conv['UzNxjbBsPhAAAQ']), true
            eql conv.isQuiet(conv['UxCZCVrfhlAAAQ']), false

    describe 'addChatMessagePlaceholder', ->

        it 'uses the output from userinput.buildChatMessage to make a placeholder', ->
            conv.add {
                conversation_id:id:'1'
                self_conversation_state:self_read_state:latest_read_timestamp:1
            }
            conv.addChatMessagePlaceholder 'e1', {
                conv_id:'1'
                ts: 12345
                segsj: [{text:'foo',type:'TEXT'}]
                client_generated_id: '42'
                message_action_type: [[4, ""]]
            }
            eql conv['1'], {
                "conversation_id": {
                    "id": "1"
                },
                "self_conversation_state": {
                    "self_read_state": {
                        "latest_read_timestamp": 12345000
                    },
                    "sort_timestamp": 12345000
                },
                "event": [
                    {
                        "chat_message": {
                            "annotation": [
                                [4, ""]
                            ],
                            "message_content": {
                                segment:[{text:'foo',type:'TEXT'}]
                            }
                        },
                        "conversation_id": {
                            "id": "1"
                        },
                        "self_event_state": {client_generated_id:'42'},
                        "sender_id": {
                            "chat_id": "e1",
                            "gaia_id": "e1"
                        },
                        "timestamp": 12345000,
                        "placeholder": true
                        "uploadimage": undefined
                    }
                ]
            }

        it 'updates the timestamp if newer', ->
            conv.add {
                conversation_id:id:'1'
                self_conversation_state:self_read_state:latest_read_timestamp:5000
            }
            conv.addChatMessagePlaceholder 'e1', {
                conv_id:'1'
                ts: 6
                segsj: [{text:'foo',type:'TEXT'}]
                client_generated_id: '42'
            }
            eql conv['1'].self_conversation_state.self_read_state.latest_read_timestamp, 6000


        it 'does not update read timestamp if older', ->
            conv.add {
                conversation_id:id:'1'
                self_conversation_state:self_read_state:latest_read_timestamp:5000
            }
            conv.addChatMessagePlaceholder 'e1', {
                conv_id:'1'
                ts: 4
                segsj: [{text:'foo',type:'TEXT'}]
                client_generated_id: '42'
            }
            eql conv['1'].self_conversation_state.self_read_state.latest_read_timestamp, 5000
