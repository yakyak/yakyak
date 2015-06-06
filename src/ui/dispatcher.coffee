Client = require 'hangupsjs'

ipc = require 'ipc'

{entity, conv, viewstate, userinput, connection, convsettings} = require './models'
{throttle} = require './util'

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
    unless conv[viewstate.selectedConv]
        viewstate.setSelectedConv conv.list()?[0]?.conversation_id

handle 'chat_message', (ev) ->
    conv.addChatMessage ev

handle 'watermark', (ev) ->
    conv.addWatermark ev

handle 'addconversation', ->
    viewstate.setState viewstate.STATE_ADD_CONVERSATION
    convsettings.reset()

handle 'convsettings', ->
    id = viewstate.selectedConv
    return unless conv[id]
    convsettings.reset()
    convsettings.loadConversation conv[id]
    viewstate.setState viewstate.STATE_ADD_CONVERSATION
    
handle 'activity', (time) ->
    viewstate.updateActivity time

handle 'atbottom', (atbottom) ->
    viewstate.updateAtBottom atbottom

handle 'selectConv', (conv) ->
    viewstate.setState viewstate.STATE_NORMAL
    viewstate.setSelectedConv conv
    ipc.send 'setfocus', viewstate.selectedConv

handle 'sendmessage', (txt) ->
    msg = userinput.buildChatMessage txt
    ipc.send 'sendchatmessage', msg
    conv.addChatMessagePlaceholder entity.self.id, msg


sendsetpresence = throttle 10000, -> ipc.send 'setpresence'
resendfocus = throttle 15000, -> ipc.send 'setfocus', viewstate.selectedConv

handle 'lastActivity', ->
    sendsetpresence()
    resendfocus() if document.hasFocus()


handle 'updatewatermark', do ->
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

handle 'onpasteimage', ->
    conv_id = viewstate.selectedConv
    return unless conv_id
    msg = userinput.buildChatMessage 'uploading image'
    {client_generated_id} = msg
    conv.addChatMessagePlaceholder entity.self.id, msg
    ipc.send 'uploadclipboardimage', {conv_id, client_generated_id}


handle 'leftresize', (size) -> viewstate.setLeftSize size
handle 'resize', (dim) -> viewstate.setSize dim
handle 'moved', (pos) -> viewstate.setPosition pos

# somewhat dirty, but img loading is done in the view
# messages.coffee and set directly in model
handle 'imgload', (conv_id) -> updated 'conv'

handle 'conversationname', (name) ->
  convsettings.setName name
handle 'searchentities', (query, max_results) ->
  convsettings.setSearchQuery query
  ipc.send 'searchentities', query, max_results
handle 'setsearchedentities', (r) ->
  convsettings.setSearchedEntities r
handle 'selectentity', (e) -> convsettings.addSelectedEntity e
handle 'deselectentity', (e) -> convsettings.removeSelectedEntity e

handle 'createconversation', ->
    ids = (e.id.chat_id for e in convsettings.selectedEntities)
    name = convsettings.name
    ipc.send 'createconversation', ids, name

handle 'createconversationdone', (c) ->
    convsettings.reset()
    conv.add c
    viewstate.setSelectedConv c.id.id

handle 'notification_level', (n) ->
    conv_id = n?[0]?[0]
    level = if n?[1] == 10 then 'QUIET' else 'RING'
    conv.setNotificationLevel conv_id, level if conv_id and level

handle 'togglenotif', ->
    {QUIET, RING} = Client.NotificationLevel
    conv_id = viewstate.selectedConv
    return unless c = conv[conv_id]
    q = conv.isQuiet(c)
    ipc.send 'setconversationnotificationlevel', conv_id, (if q then RING else QUIET)
    conv.setNotificationLevel conv_id, (if q then 'RING' else 'QUIET')

handle 'delete', (a) ->
    conv_id = a?[0]?[0]
    return unless c = conv[conv_id]
    conv.deleteConv conv_id

handle 'deleteconv', ->
    conv_id = viewstate.selectedConv
    if confirm 'Really delete conversation?'
        ipc.send 'deleteconversation', conv_id


handle 'lastkeydown', (time) -> viewstate.setLastKeyDown time
handle 'settyping', (v) ->
    conv_id = viewstate.selectedConv
    return unless conv_id and viewstate.state == viewstate.STATE_NORMAL
    ipc.send 'settyping', conv_id, v

handle 'typing', (t) ->
    # console.log t

handle 'syncallnewevents', throttle 10000, (time) ->
    return unless time
    ipc.send 'syncallnewevents', time
handle 'handlesyncedevents', (r) ->
    states = r?.conversation_state
    return unless states?.length
    for st in states
        for e in (st?.event ? [])
            conv.addChatMessage e
    null


handle 'syncrecentconversations', throttle 10000, ->
    ipc.send 'syncrecentconversations'
handle 'handlerecentconversations', (r) ->
    return unless st = r.conversation_state
    conv.replaceEventsFromStates st
