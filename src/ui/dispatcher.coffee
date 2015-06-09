Client = require 'hangupsjs'
shell = require 'shell'

ipc = require 'ipc'

{entity, conv, viewstate, userinput, connection, convsettings} = require './models'
{throttle, later} = require './util'

'connecting connected connect_failed'.split(' ').forEach (n) ->
    handle n, -> connection.setState n

handle 'alive', (time) -> connection.setLastActive time

handle 'reqinit', ->
    ipc.send 'reqinit'
    connection.setState connection.CONNECTING
    viewstate.setState viewstate.STATE_STARTUP

module.exports =
    init: ({init}) -> action 'init', init


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
    # these messages are to go through notifications
    conv.addToNotify ev

handle 'watermark', (ev) ->
    conv.addWatermark ev

handle 'update:unreadcount', ->
    console.log 'update'

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
handle 'addentities', (es, conv_id) ->
    entity.add e for e in es ? []
    if conv_id # auto-add these ppl to a conv
        r.entities.forEach (p) -> conv.addParticipant conv_id, p
        viewstate.setState viewstate.STATE_NORMAL

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
handle 'conversationquery', (query) ->
    convsettings.setSearchQuery query
handle 'searchentities', (query, max_results) ->
    ipc.send 'searchentities', query, max_results
handle 'setsearchedentities', (r) ->
    convsettings.setSearchedEntities r
handle 'selectentity', (e) -> convsettings.addSelectedEntity e
handle 'deselectentity', (e) -> convsettings.removeSelectedEntity e

handle 'saveconversation', ->
    viewstate.setState viewstate.STATE_NORMAL
    conv_id = convsettings.id
    c = conv[conv_id]
    one_to_one = c?.type?.indexOf('ONE_TO_ONE') >= 0
    selected = (e.id.chat_id for e in convsettings.selectedEntities)
    needsRename = convsettings.name and convsettings.name != c?.name
    recreate = conv_id and one_to_one and convsettings.selectedEntities.length > 1
    if not conv_id or recreate
        ipc.send 'createconversation', selected, convsettings.name
        return
    if conv_id and one_to_one and convsettings.selectedEntities.length == 1 # can only rename
        ipc.send 'renameconversation', conv_id, convsettings.name if needsRename
        return
    p = c.participant_data
    current = (c.id.chat_id for c in p when not entity.isSelf c.id.chat_id)
    toadd = (id for id in selected when id not in current)
    ipc.send 'adduser', conv_id, toadd if toadd.length
    ipc.send 'renameconversation', conv_id, convsettings.name if needsRename

handle 'conversation_rename', (c) ->
    conv.rename c, c.conversation_rename.new_name

handle 'membership_change', (e) ->
    conv_id = e.conversation_id.id
    ids = (id.chat_id or id.gaia_id for id in e.membership_change.participant_ids)
    if e.membership_change.type == 'LEAVE'
        if entity.self.id in ids
            return conv.deleteConv conv_id
        return conv.removeParticipants conv_id, ids
    ipc.send 'getentity', ids, {add_to_conv: conv_id}

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

handle 'deleteconv', (confirmed) ->
    conv_id = viewstate.selectedConv
    unless confirmed
        later -> if confirm 'Really delete conversation?'
            action 'deleteconv', true
    else
        ipc.send 'deleteconversation', conv_id

handle 'leaveconv', (confirmed) ->
    conv_id = viewstate.selectedConv
    unless confirmed
        later -> if confirm 'Really leave conversation?'
            action 'leaveconv', true
    else
        ipc.send 'removeuser', conv_id

handle 'lastkeydown', (time) -> viewstate.setLastKeyDown time
handle 'settyping', (v) ->
    conv_id = viewstate.selectedConv
    return unless conv_id and viewstate.state == viewstate.STATE_NORMAL
    ipc.send 'settyping', conv_id, v

handle 'typing', (t) ->
    # console.log t


handle 'syncallnewevents', throttle 10000, (time) ->
    return unless time
    connection.setDisableLastActive true
    ipc.send 'syncallnewevents', time
handle 'handlesyncedevents', (r) ->
    try
        states = r?.conversation_state
        return unless states?.length
        for st in states
            for e in (st?.event ? [])
                conv.addChatMessage e
    finally
        connection.setLastActive Date.now(), true
        connection.setDisableLastActive false


handle 'syncrecentconversations', throttle 10000, ->
    connection.setDisableLastActive true
    ipc.send 'syncrecentconversations'
handle 'handlerecentconversations', (r) ->
    try
        return unless st = r.conversation_state
        conv.replaceEventsFromStates st
    finally
        connection.setLastActive Date.now(), true
        connection.setDisableLastActive false

handle 'client_conversation', (c) ->
    conv.add c unless conv[c?.conversation_id?.id]

handle 'hangout_event', (e) ->
    return unless e?.hangout_event?.event_type == 'START_HANGOUT'
    return unless conv_id = e?.conversation_id?.id
    #https://plus.google.com/hangouts/_/CONVERSATION/UgxspFf2-AM1dZ4d9lJ4AaABAQ?hl=en-GB&hscid=1433709105253579475&hpe=13g457g2acd23v&hpn=Davide%20Bertola&hisdn=Davide&hnc=0&hs=35
    shell.openExternal "https://plus.google.com/hangouts/_/CONVERSATION/#{conv_id}"

'presence reply_to_invite settings conversation_notification'.split(' ').forEach (n) ->
    handle n, (as...) -> console.log n, as...

handle 'unreadtotal', (total, orMore) ->
    value = ""
    if total > 0 then value = total + (if orMore then "+" else "")
    ipc.send 'updatebadge', value
