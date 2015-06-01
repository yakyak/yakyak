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


handle 'chat_message', (ev) ->
    conv.addChatMessage ev


handle 'watermark', (ev) ->
    conv.addWatermark ev


handle 'selectConv', (conv) -> viewstate.setSelectedConv conv


# XXX too much logic here. refactor to make
# an input parser that builds an object with all
# params passed to server.
randomid = -> Math.round Math.random() * Math.pow(2,32)
handle 'sendmessage', (txt) ->
    conv_id = viewstate.selectedConv
    mb = new MessageBuilder()
    txt = txt.split '\n'
    last = txt.length - 1
    for index, line of txt
      mb.text(line)
      mb.linebreak() unless index is last
    segs = mb.toSegments()
    client_generated_id = randomid() + ''
    ipc.send 'sendchatmessage', conv_id, segs, client_generated_id
    conv.addChatMessagePlaceholder conv_id, entity.self.id,
        client_generated_id, mb.toSegsjson()
