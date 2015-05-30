moment = require 'moment'

{nameof, linkto}  = require './vutil'

module.exports = view (models) ->
    {viewstate, conv, entity} = models
    div class:'messages', ->
        return unless viewstate.selectedConv
        c = conv[viewstate.selectedConv]
        return unless c?.event
        for e in c.event
            continue unless e.chat_message
            cid = e?.sender_id?.chat_id
            sender = nameof entity[cid]
            clz = ['message']
            clz.push 'self' if entity.isSelf(cid)
            div class:clz.join(' '), ->
                a href:linkto(cid), class:'sender', sender
                span class:'timestamp', moment(e.timestamp / 1000).format('YYYY-MM-DD HH:mm:ss')
                format e.chat_message?.message_content


pass = (v) -> if typeof v == 'function' then (v(); undefined) else v
ifpass = (t, f) -> if t then f else pass

format = (cont) ->
    if cont?.attachment?.length
        console.log cont
    for seg in cont?.segment ? []
        f = seg.formatting
        href = seg?.link_data?.link_target
        ifpass(href, ((f) -> a {href}, f)) ->
            ifpass(f.bold, b) ->
                ifpass(f.italics, i) ->
                    ifpass(f.underline, u) ->
                        ifpass(f.strikethrough, strike) ->
                            span seg.text
    null
