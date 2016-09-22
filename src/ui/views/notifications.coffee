notifier = require 'node-notifier'
shell    = require('electron').shell
path     = require 'path'
remote   = require('electron').remote

{nameof, getProxiedName} = require '../util'

# conv_id markers for call notifications
callNeedAnswer = {}

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
            text = "Incoming call"
            callNeedAnswer[conv_id] = true
            notr
                html: "Incoming call from #{sender}. " +
                '<a href="#" class="accept">Accept</a> / ' +
                '<a href="#" class="reject">Reject</a>'
                stay: 0
                id: "hang#{conv_id}"
                onclick: (e) ->
                    delete callNeedAnswer[conv_id]
                    if e?.target?.className == 'accept'
                        notr({html:'Accepted', stay:1000, id:"hang#{conv_id}"})
                        openHangout conv_id
                    else
                        notr({html:'Rejected', stay:1000, id:"hang#{conv_id}"})
        else if msg.hangout_event?.event_type == 'END_HANGOUT'
            if callNeedAnswer[conv_id]
                delete callNeedAnswer[conv_id]
                notr
                    html: "Missed call from #{sender}. " + '<a href="#">OK</a>'
                    id: "hang#{conv_id}"
                    stay: 0
        else
            return

        # maybe trigger OS notification
        return if !text or quietIf(c, chat_id)

        if viewstate.showPopUpNotifications
            notifier.notify
                title: sender
                message: if viewstate.showMessageInNotification then text else ' '
                wait: true
                sender: 'com.github.yakyak'
                sound: true
            , (err, res) ->
              if res?.trim().match(/Activate/i)
                action 'appfocus'
                action 'selectConv', c

        mainWindow = remote.getCurrentWindow() # And we hope we don't get another ;)
        mainWindow.flashFrame(true)

textMessage = (cont, proxied) ->
    segs = for seg, i in cont?.segment ? []
        continue if proxied and i < 2
        continue unless seg.text
        seg.text
    segs.join('')


openHangout = (conv_id) ->
    shell.openExternal "https://plus.google.com/hangouts/_/CONVERSATION/#{conv_id}"
