ipc = require 'ipc'
{entity, conv, viewstate} = require './models'
{MessageBuilder} = require 'hangupsjs'

module.exports =
    init: ({init, recorded}) ->
        action 'init', init
        action n, e for [n, e] in recorded


handle 'init', (init) ->
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


handle 'selectConv', (conv) -> viewstate.setSelectedConv conv

randomid = -> Math.round Math.random() * Math.pow(2,32)

handle 'sendmessage', (txt) ->
    conv_id = viewstate.selectedConv
    mb = new MessageBuilder()
    segs = mb.text(txt).toSegments()
    client_generated_id = randomid() + ''
    ipc.send 'sendchatmessage', conv_id, segs, client_generated_id
    conv.addChatMessagePlaceholder conv_id, entity.self.id,
        client_generated_id, mb.toSegsjson()
