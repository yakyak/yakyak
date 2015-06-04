ipc = require 'ipc'
{entity, conv, viewstate, userinput, connection} = require './models'

{throttle} = require './views/vutil'

'connecting connected connect_failed'.split(' ').forEach (n) ->
    handle n, -> connection.setState n

handle 'alive', (time) -> connection.setLastActive time

handle 'reqinit', ->
    ipc.send 'reqinit'
    connection.setState connection.CONNECTING
    viewstate.setState viewstate.STATE_STARTUP

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

handle 'drop', (files) ->
    # this may change during upload
    conv_id = viewstate.selectedConv
    # sense check that client is in good state
    return unless viewstate.state == viewstate.STATE_NORMAL and conv[conv_id]
    # ship it
    for file in files
        # message for a placeholder
        msg = userinput.buildChatMessage 'uploading image'
        {client_generated_id} = msg
        # add a placeholder for the image
        conv.addChatMessagePlaceholder entity.self.id, msg
        # and begin upload
        ipc.send 'uploadimage', {path:file.path, conv_id, client_generated_id}


handle 'leftresize', (size) -> viewstate.setLeftSize size
handle 'resize', (dim) -> viewstate.setSize dim
handle 'moved', (pos) -> viewstate.setPosition pos

# somewhat dirty, but img loading is done in the view
# messages.coffee and set directly in model
handle 'imgload', (conv_id) -> updated 'conv'
