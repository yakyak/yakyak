{nameof, getProxiedName} = require '../util'

module.exports = (models) ->
    {conv, entity} = models
    tonot = conv.popToNotify()
    tonot.forEach (msg) ->
        conv_id = msg?.conversation_id?.id
        c = conv[conv_id]
        return if !msg.chat_message?.message_content? or document?.hasFocus() or conv.isQuiet(c) or entity.isSelf(msg?.sender_id?.chat_id)
        proxied = getProxiedName(msg)
        cid = if proxied then proxied else msg?.sender_id?.chat_id
        sender = nameof entity[cid]
        text = textMessage msg.chat_message.message_content, proxied
        nt = new Notification sender, {body: text}
        nt.onclick = (ev) -> action 'selectConv', c


textMessage = (cont, proxied) ->
    segs = for seg, i in cont?.segment ? []
        continue if proxied and i < 2
        continue unless seg.text
        seg.text
    segs.join('')
