notifier = require 'node-notifier'
shell    = require('electron').shell
path     = require 'path'
remote   = require('electron').remote
i18n     = require 'i18n'

{nameof, getProxiedName, fixlink, notificationCenterSupportsSound} = require '../util'

# conv_id markers for call notifications
callNeedAnswer = {}

notifierSupportsSound = notificationCenterSupportsSound()

# Custom sound for new message notifications
audioFile = path.join YAKYAK_ROOT_DIR, '..', 'media',
'new_message.ogg'
audioEl = new Audio(audioFile)
audioEl.volume = .4


module.exports = (models) ->
    {conv, notify, entity, viewstate} = models
    tonot = notify.popToNotify()

    quietIf = (c, chat_id) -> document?.hasFocus() or conv.isQuiet(c) or entity.isSelf(chat_id)

    tonot.forEach (msg) ->
        conv_id = msg?.conversation_id?.id
        c = conv[conv_id]
        chat_id = msg?.sender_id?.chat_id

        proxied = getProxiedName(msg)
        cid = if proxied then proxied else msg?.sender_id?.chat_id
        sender = nameof entity[cid]
        text = null

        if msg.chat_message?
            return unless msg.chat_message?.message_content?
            text = textMessage msg.chat_message.message_content, proxied
        else if msg.hangout_event?.event_type == 'START_HANGOUT'
            text = i18n.__ "call.incoming:Incoming call"
            callNeedAnswer[conv_id] = true
            notr
                html: "#{i18n.__('call.incoming_from:Incoming call from %s', sender)}. " +
                "<a href=\"#\" class=\"accept\">#{i18n.__ 'call.accept:Accept'}</a> / " +
                "<a href=\"#\" class=\"reject\">#{i18n.__ 'call.reject:Reject'}</a>"
                stay: 0
                id: "hang#{conv_id}"
                onclick: (e) ->
                    delete callNeedAnswer[conv_id]
                    if e?.target?.className == 'accept'
                        notr({html:i18n.__('calls.accepted:Accepted'), stay:1000, id:"hang#{conv_id}"})
                        openHangout conv_id
                    else
                        notr({html: i18n.__('calls.rejected:Rejected'), stay:1000, id:"hang#{conv_id}"})
        else if msg.hangout_event?.event_type == 'END_HANGOUT'
            if callNeedAnswer[conv_id]
                delete callNeedAnswer[conv_id]
                notr
                    html: "#{i18n.__('calls.missed:Missed call from %s', sender)}. " +
                        "<a href=\"#\">#{i18n.__('actions.ok: Ok')}</a>"
                    id: "hang#{conv_id}"
                    stay: 0
        else
            return

        # maybe trigger OS notification
        return if !text or quietIf(c, chat_id)

        if viewstate.showPopUpNotifications
            isNotificationCenter = notifier.constructor.name == 'NotificationCenter'
            #
            icon = path.join __dirname, '..', '..', 'icons', 'icon@8.png'
            # Only for NotificationCenter (darwin)
            if isNotificationCenter && viewstate.showIconNotification
                contentImage = fixlink entity[cid]?.photo_url
            else
                contentImage = undefined
            #
            notifier.notify
                title: if viewstate.showUsernameInNotification
                           if !isNotificationCenter && !viewstate.showIconNotification
                               "#{sender} (YakYak)"
                           else
                               sender
                       else
                           'YakYak'
                message: if viewstate.showMessageInNotification
                          text
                      else
                          i18n.__('conversation.new_message:New Message')
                wait: true
                hint: "int:transient:1"
                category: 'im.received'
                sender: 'com.github.yakyak'
                sound: !viewstate.muteSoundNotification && (notifierSupportsSound && !viewstate.forceCustomSound)
                icon: icon if !isNotificationCenter && viewstate.showIconNotification
                contentImage: contentImage
            , (err, res) ->
              if res?.trim().match(/Activate/i)
                action 'appfocus'
                action 'selectConv', c

            # only play if it is not playing already
            #  and notifier does not support sound or force custom sound is set
            #  and mute option is not set
            if (!notifierSupportsSound || viewstate.forceCustomSound) && !viewstate.muteSoundNotification && audioEl.paused
                audioEl.play()
        # And we hope we don't get another 'currentWindow' ;)
        mainWindow = remote.getCurrentWindow()
        mainWindow.flashFrame(true)

textMessage = (cont, proxied) ->
    segs = for seg, i in cont?.segment ? []
        continue if proxied and i < 2
        continue unless seg.text
        seg.text
    segs.join('')


openHangout = (conv_id) ->
    shell.openExternal "https://plus.google.com/hangouts/_/CONVERSATION/#{conv_id}"
