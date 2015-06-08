{nameof, getProxiedName} = require '../util'

module.exports = (models) ->
    {conv, entity} = models
    tonot = conv.popToNotify()
    for msg in tonot
        if msg.chat_message?.message_content?
            # deal with notification.
            unless document?.hasFocus() or conv.isQuiet(conv) or entity.isSelf(msg?.sender_id?.chat_id)
                proxied = getProxiedName(msg)
                cid = if proxied then proxied else msg?.sender_id?.chat_id
                sender = nameof entity[cid]
                text = textMessage msg.chat_message.message_content, proxied
                new Notification sender, {body: text}

textMessage = (cont, proxied) ->
    segs = for seg, i in cont?.segment ? []
        continue if proxied and i < 2
        continue unless seg.text
        seg.text
    segs.join('')
