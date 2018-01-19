Client = require 'hangupsjs'
remote = require('electron').remote
ipc    = require('electron').ipcRenderer


fs = require('fs')
mime = require('mime-types')

clipboard = require('electron').clipboard

{entity, conv, viewstate, userinput, connection, convsettings, notify} = require './models'
{insertTextAtCursor, throttle, later, isImg, nameof} = require './util'

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
    viewstate.setLoggedin true

    viewstate.setColorScheme viewstate.colorScheme
    viewstate.setFontSize viewstate.fontSize

    # update model from init object
    entity._initFromSelfEntity init.self_entity
    entity._initFromEntities init.entities if init.entities
    conv._initFromConvStates init.conv_states
    # ensure there's a selected conv
    unless conv[viewstate.selectedConv]
        viewstate.setSelectedConv conv.list()?[0]?.conversation_id

    ipc.send 'initpresence', entity.list()

    require('./version').check()

    # small delay for better experience
    later -> action 'set_viewstate_normal'

handle 'set_viewstate_normal', ->
    viewstate.setContacts true
    viewstate.setState viewstate.STATE_NORMAL

handle 'chat_message', (ev) ->
    # TODO entity is not fetched in usable time for first notification
    # if does not have user on cache
    entity.needEntity ev.sender_id.chat_id unless entity[ev.sender_id.chat_id]?
    # add chat to conversation
    conv.addChatMessage ev
    # these messages are to go through notifications
    notify.addToNotify ev

handle 'watermark', (ev) ->
    conv.addWatermark ev

handle 'presence', (ev) ->
    entity.setPresence ev[0][0][0][0], if ev[0][0][1][1] == 1 then true else false

# handle 'self_presence', (ev) ->
#     console.log 'self_presence', ev

handle 'querypresence', (id) ->
    ipc.send 'querypresence', id

handle 'setpresence', (r) ->
    if not r?.presence?.available?
        console.log "setpresence: User '#{nameof entity[r?.user_id?.chat_id]}' does not show his/hers/it status", r
    else
        entity.setPresence r.user_id.chat_id, r?.presence?.available

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

handle 'attop', (attop) ->
    viewstate.updateAtTop attop
    conv.updateAtTop attop

handle 'history', (conv_id, timestamp) ->
    ipc.send 'getconversation', conv_id, timestamp, 20

handle 'handleconversationmetadata', (r) ->
    return unless r.conversation_state
    # removing events so they don't get merged
    r.conversation_state.event = null
    conv.updateMetadata r.conversation_state

handle 'handlehistory', (r) ->
    return unless r.conversation_state
    conv.updateHistory r.conversation_state

handle 'selectConv', (conv) ->
    viewstate.setState viewstate.STATE_NORMAL
    viewstate.setSelectedConv conv
    ipc.send 'setfocus', viewstate.selectedConv

handle 'selectNextConv', (offset = 1) ->
    if viewstate.state != viewstate.STATE_NORMAL then return
    viewstate.selectNextConv offset
    ipc.send 'setfocus', viewstate.selectedConv

handle 'selectConvIndex', (index = 0) ->
    if viewstate.state != viewstate.STATE_NORMAL then return
    viewstate.selectConvIndex index
    ipc.send 'setfocus', viewstate.selectedConv

handle 'sendmessage', (txt = '') ->
    if !txt.trim() then return
    msg = userinput.buildChatMessage entity.self, txt
    ipc.send 'sendchatmessage', msg
    conv.addChatMessagePlaceholder entity.self.id, msg

handle 'toggleshowtray', ->
    viewstate.setShowTray(not viewstate.showtray)

handle 'forcecustomsound', (value) ->
    viewstate.setForceCustomSound(value)

handle 'showiconnotification', (value) ->
    viewstate.setShowIconNotification(value)

handle 'mutesoundnotification', ->
    viewstate.setMuteSoundNotification(not viewstate.muteSoundNotification)

handle 'togglemenu', ->
    remote.Menu.getApplicationMenu().popup()

handle 'setescapeclearsinput', (value) ->
    viewstate.setEscapeClearsInput(value)

handle 'togglehidedockicon', ->
    viewstate.setHideDockIcon(not viewstate.hidedockicon)

handle 'show-about', ->
    viewstate.setState viewstate.STATE_ABOUT
    updated 'viewstate'

handle 'hideWindow', ->
    mainWindow = remote.getCurrentWindow() # And we hope we don't get another ;)
    mainWindow.hide()

handle 'togglewindow', ->
    mainWindow = remote.getCurrentWindow() # And we hope we don't get another ;)
    if mainWindow.isVisible() then mainWindow.hide() else mainWindow.show()

handle 'togglestartminimizedtotray', ->
    viewstate.setStartMinimizedToTray(not viewstate.startminimizedtotray)

handle 'toggleclosetotray', ->
    viewstate.setCloseToTray(not viewstate.closetotray)

handle 'showwindow', ->
    mainWindow = remote.getCurrentWindow() # And we hope we don't get another ;)
    mainWindow.show()

sendsetpresence = throttle 10000, ->
    ipc.send 'setpresence'
    ipc.send 'setactiveclient', true, 15
resendfocus = throttle 15000, -> ipc.send 'setfocus', viewstate.selectedConv

# on every keep alive signal from hangouts
#  we inform the server that the user is still
#  available
handle 'noop', ->
    sendsetpresence()

handle 'lastActivity', ->
    sendsetpresence()
    resendfocus() if document.hasFocus()

handle 'appfocus', ->
    ipc.send 'appfocus'

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

handle 'getentity', (ids) ->
    do fn = ->
        ipc.send 'getentity', ids[..4]
        ids = ids[5..]
        setTimeout(fn, 500) if ids.length > 0

handle 'addentities', (es, conv_id) ->
    entity.add e for e in es ? []
    if conv_id # auto-add these ppl to a conv
        (es ? []).forEach (p) -> conv.addParticipant conv_id, p
        viewstate.setState viewstate.STATE_NORMAL

    # flag to show that contacts are loaded
    viewstate.setContacts true

handle 'uploadimage', (files) ->
    # this may change during upload
    conv_id = viewstate.selectedConv
    # sense check that client is in good state
    unless viewstate.state == viewstate.STATE_NORMAL and conv[conv_id]
        # clear value for upload image input
        document.getElementById('attachFile').value = ''
        return
    # if only one file is selected, then it shows as preview before sending
    #  otherwise, it will upload all of them immediatly
    if files.length == 1
        file = files[0] # get first and only file
        element = document.getElementById 'preview-img'
        # show error message and return if is not an image
        if isImg file.path
            # store image in preview-container and open it
            #  I think it is better to embed than reference path as user should
            #   see exactly what he is sending. (using the path would require
            #   polling)
            fs.readFile file.path, (err, original_data) ->
                binaryImage = new Buffer(original_data, 'binary')
                base64Image = binaryImage.toString('base64')
                mimeType = mime.lookup file.path
                element.src = 'data:' + mimeType + ';base64,' + base64Image
                document.querySelector('#preview-container').classList.add('open')
        else
            [_, ext] = file.path.match(/.*(\.\w+)$/) ? []
            notr "Ignoring file of type #{ext}"
    else
        for file in files
            # only images please
            unless isImg file.path
                [_, ext] = file.path.match(/.*(\.\w+)$/) ? []
                notr "Ignoring file of type #{ext}"
                continue
            # message for a placeholder
            msg = userinput.buildChatMessage entity.self, 'uploading image…'
            msg.uploadimage = true
            {client_generated_id} = msg
            # add a placeholder for the image
            conv.addChatMessagePlaceholder entity.self.id, msg
            # and begin upload
            ipc.send 'uploadimage', {path:file.path, conv_id, client_generated_id}
    # clear value for upload image input
    document.getElementById('attachFile').value = ''

handle 'onpasteimage', ->
    element = document.getElementById 'preview-img'
    element.src = clipboard.readImage().toDataURL()
    element.src = element.src.replace /image\/png/, 'image/gif'
    document.querySelector('#preview-container').classList.add('open')

handle 'uploadpreviewimage', ->
    conv_id = viewstate.selectedConv
    return unless conv_id
    msg = userinput.buildChatMessage entity.self, 'uploading image…'
    msg.uploadimage = true
    {client_generated_id} = msg
    conv.addChatMessagePlaceholder entity.self.id, msg
    # find preview element
    element = document.getElementById 'preview-img'
    # build image from what is on preview
    pngData = element.src.replace /data:image\/(png|jpe?g|gif|svg);base64,/, ''
    pngData = new Buffer(pngData, 'base64')
    document.querySelector('#preview-container').classList.remove('open')
    document.querySelector('#emoji-container').classList.remove('open')
    element.src = ''
    #
    ipc.send 'uploadclipboardimage', {pngData, conv_id, client_generated_id}

handle 'uploadingimage', (spec) ->
    # XXX this doesn't look very good because the image
    # shows, then flickers away before the real is loaded
    # from the upload.
    #conv.updatePlaceholderImage spec

handle 'leftresize', (size) -> viewstate.setLeftSize size
handle 'resize', (dim) -> viewstate.setSize dim
handle 'move', (pos) -> viewstate.setPosition pos

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
handle 'togglegroup', (e) -> convsettings.setGroup(!convsettings.group)

handle 'saveconversation', ->
    viewstate.setState viewstate.STATE_NORMAL
    conv_id = convsettings.id
    c = conv[conv_id]
    one_to_one = c?.type?.indexOf('ONE_TO_ONE') >= 0
    selected = (e.id.chat_id for e in convsettings.selectedEntities)
    recreate = conv_id and one_to_one and convsettings.group
    needsRename = convsettings.group and convsettings.name and convsettings.name != c?.name
    # remember: we don't rename one_to_ones, google web client does not do it
    if not conv_id or recreate
        name = (convsettings.name if convsettings.group) or ""
        ipc.send 'createconversation', selected, name, convsettings.group
        return
    p = c.participant_data
    current = (c.id.chat_id for c in p when not entity.isSelf c.id.chat_id)
    toadd = (id for id in selected when id not in current)
    ipc.send 'adduser', conv_id, toadd if toadd.length
    ipc.send 'renameconversation', conv_id, convsettings.name if needsRename

handle 'conversation_rename', (c) ->
    conv.rename c, c.conversation_rename.new_name
    conv.addChatMessage c

handle 'membership_change', (e) ->
    conv_id = e.conversation_id.id
    ids = (id.chat_id or id.gaia_id for id in e.membership_change.participant_ids)
    if e.membership_change.type == 'LEAVE'
        if entity.self.id in ids
            return conv.deleteConv conv_id
        return conv.removeParticipants conv_id, ids
    conv.addChatMessage e
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

handle 'togglestar', ->
    conv_id = viewstate.selectedConv
    return unless c = conv[conv_id]
    conv.toggleStar(c)

handle 'delete', (a) ->
    conv_id = a?[0]?[0]
    return unless c = conv[conv_id]
    conv.deleteConv conv_id

#
#
# Change language in YakYak
#
handle 'changelanguage', (language) ->
    if i18n.getLocales().includes viewstate.language
        ipc.send 'seti18n', null, language
        viewstate.setLanguage(language)

handle 'deleteconv', (confirmed) ->
    conv_id = viewstate.selectedConv
    unless confirmed
        later -> if confirm i18n.__('conversation.delete_confirm:Really delete conversation?')
            action 'deleteconv', true
    else
        ipc.send 'deleteconversation', conv_id
        viewstate.selectConvIndex(0)
        viewstate.setState(viewstate.STATE_NORMAL)

handle 'leaveconv', (confirmed) ->
    conv_id = viewstate.selectedConv
    unless confirmed
        later -> if confirm i18n.__('conversation.leave_confirm:Really leave conversation?')
            action 'leaveconv', true
    else
        ipc.send 'removeuser', conv_id
        viewstate.selectConvIndex(0)
        viewstate.setState(viewstate.STATE_NORMAL)

handle 'lastkeydown', (time) -> viewstate.setLastKeyDown time
handle 'settyping', (v) ->
    conv_id = viewstate.selectedConv
    return unless conv_id and viewstate.state == viewstate.STATE_NORMAL
    ipc.send 'settyping', conv_id, v
    viewstate.setState(viewstate.STATE_NORMAL)

handle 'typing', (t) ->
    conv.addTyping t
handle 'pruneTyping', (conv_id) ->
    conv.pruneTyping conv_id

handle 'syncallnewevents', throttle 10000, (time) ->
    return unless time
    ipc.send 'syncallnewevents', time

handle 'handlesyncedevents', (r) ->
    states = r?.conversation_state
    return unless states?.length
    for st in states
        for e in (st?.event ? [])
            conv.addChatMessage e
    connection.setEventState connection.IN_SYNC

handle 'syncrecentconversations', throttle 10000, ->
    ipc.send 'syncrecentconversations'

handle 'handlerecentconversations', (r) ->
    return unless st = r.conversation_state
    conv.replaceFromStates st
    connection.setEventState connection.IN_SYNC

handle 'client_conversation', (c) ->
    # Conversation must be added, even if already exists
    #  why? because when a new chat message for a new conversation appears
    #  a skeleton is made of a conversation
    conv.add c unless conv[c?.conversation_id?.id]?.participant_data?

handle 'hangout_event', (e) ->
    return unless e?.hangout_event?.event_type in ['START_HANGOUT', 'END_HANGOUT']
    # trigger notifications for this
    notify.addToNotify e

'reply_to_invite settings conversation_notification invitation_watermark'.split(' ').forEach (n) ->
    handle n, (as...) -> console.log n, as...

handle 'unreadtotal', (total, orMore) ->
    value = ""
    if total > 0 then value = total + (if orMore then "+" else "")
    updated 'conv_count'
    ipc.send 'updatebadge', value

handle 'showconvmin', (doshow) ->
    viewstate.setShowConvMin doshow

handle 'setusesystemdateformat', (val) ->

    viewstate.setUseSystemDateFormat(val)

handle 'showconvthumbs', (doshow) ->
    viewstate.setShowConvThumbs doshow

handle 'showanimatedthumbs', (doshow) ->
    viewstate.setShowAnimatedThumbs doshow

handle 'showconvtime', (doshow) ->
    viewstate.setShowConvTime doshow

handle 'showconvlast', (doshow) ->
    viewstate.setShowConvLast doshow

handle 'showpopupnotifications', (doshow) ->
    viewstate.setShowPopUpNotifications doshow

handle 'showmessageinnotification', (doshow) ->
    viewstate.setShowMessageInNotification doshow

handle 'showusernameinnotification', (doshow) ->
    viewstate.setShowUsernameInNotification doshow

handle 'convertemoji', (doshow) ->
    viewstate.setConvertEmoji doshow

handle 'suggestemoji', (doshow) ->
    viewstate.setSuggestEmoji doshow

handle 'changetheme', (colorscheme) ->
    viewstate.setColorScheme colorscheme

handle 'changefontsize', (fontsize) ->
    viewstate.setFontSize fontsize

handle 'devtools', ->
    remote.getCurrentWindow().openDevTools detach:true

handle 'quit', ->
    ipc.send 'quit'

handle 'togglefullscreen', ->
    ipc.send 'togglefullscreen'

handle 'zoom', (step) ->
    if step?
        return viewstate.setZoom (parseFloat(document.body.style.zoom.replace(',', '.')) or 1.0) + step
    viewstate.setZoom 1

handle 'logout', ->
    ipc.send 'logout'

handle 'wonline', (wonline) ->
    connection.setWindowOnline wonline
    if wonline
        ipc.send 'hangupsConnect'
    else
        ipc.send 'hangupsDisconnect'

handle 'openonsystemstartup', (open) ->
    viewstate.setOpenOnSystemStartup open

handle 'initopenonsystemstartup', (isEnabled) ->
    viewstate.initOpenOnSystemStartup isEnabled

handle 'minimize', ->
    mainWindow = remote.getCurrentWindow()
    mainWindow.minimize()

handle 'resizewindow', ->
    mainWindow = remote.getCurrentWindow()
    if mainWindow.isMaximized() then mainWindow.unmaximize() else mainWindow.maximize()

handle 'close', ->
    mainWindow = remote.getCurrentWindow()
    mainWindow.close()
