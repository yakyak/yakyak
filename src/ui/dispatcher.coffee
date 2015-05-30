{entity, conv, viewstate} = require './models'


handle 'init', (init) ->
    console.log 'init'
    # set the initial view state
    viewstate.setState viewstate.STATE_NORMAL
    # update model from init object
    entity._initFromSelfEntity init.self_entity
    entity._initFromEntities init.entities
    conv._initFromConvStates init.conv_states
    # ensure there's a selected conv
    unless viewstate.selectedConv
        viewstate.setSelectedConv conv.list()?[0]?.conversation_id

handle 'chat_message', (msg) ->
    conv.addChatMessage msg
