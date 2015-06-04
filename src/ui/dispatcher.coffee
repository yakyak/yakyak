ipc = require 'ipc'
{entity, conv, viewstate, userinput, connection} = require './models'

{throttle} = require './views/vutil'

'connecting connected connect_failed'.split(' ').forEach (n) ->
    handle n, -> connection.setState n

handle 'alive', (time) -> connection.setLastActive time

handle 'reqinit', ->
    ipc.send 'reqinit'
    connection.setState connection.CONNECTING

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

handle 'focus', ->
    viewstate.setFocus true

handle 'blur', ->
    viewstate.setFocus false

handle 'activity', (time) ->
    viewstate.updateActivity time

handle 'atbottom', (atbottom) ->
    viewstate.updateAtBottom atbottom

handle 'selectConv', (conv) -> viewstate.setSelectedConv conv


handle 'sendmessage', (txt) ->
    msg = userinput.buildChatMessage txt
    ipc.send 'sendchatmessage', msg
    conv.addChatMessagePlaceholder entity.self.id, msg


handle 'update:lastActivity', do ->
    sendSetPresence = throttle 10000, -> ipc.send 'setpresence'
    -> sendSetPresence()


handle 'update:watermark', do ->
    throttleWaterByConv = {}
    ->
        conv_id = viewstate.selectedConv
        c = conv[conv_id]
        return unless c
        sendWater = throttleWaterByConv[conv_id]
        unless sendWater
            do (conv_id) ->
                sendWater = throttle 1000, -> ipc.send 'updatewatermark', conv_id, Date.now()
                throttleWaterByConv[conv_id] = sendWater
        sendWater()


handle 'getentity', (ids) -> ipc.send 'getentity', ids
handle 'addentities', (es) -> entity.add e for e in es ? []
