moment = require 'moment'
shell = require 'shell'

{nameof, linkto, later, forceredraw, throttle, getProxiedName}  = require './vutil'

CUTOFF = 5 * 60 * 1000 * 1000 # 5 mins

# this helps fixing houts proxied with things like hangupsbot
# the format of proxied messages are
# and here we put entities in the entity db for
# users found only in proxied messages.
fixProxied = (e, proxied, entity) ->
    e.chat_message.message_content.proxied = true
    name = e?.chat_message?.message_content?.segment[0]?.text
    # update fallback_name for entity database
    if name != '>>'
        # synthetic add of fallback_name
        entity.add {
            id: {
                gaia_id: proxied
                chat_id: proxied
            }
            fallback_name: name
        }, silent:true

onclick = (e) ->
  e.preventDefault()
  address = e.currentTarget.getAttribute 'href'
  if address[0] == '/' then address = "http:" + address
  shell.openExternal address

# helper method to group events in time/user bunches
groupEvents = (es, entity) ->
    groups = []
    group = null
    user = null
    for e in es
        continue unless e.chat_message
        if e.timestamp - (group?.end ? 0) > CUTOFF
            group = {
                byuser: []
                start: e.timestamp
                end: e.timestamp
            }
            user = null
            groups.push group
        proxied = getProxiedName(e)
        if proxied
            fixProxied e, proxied, entity
        cid = if proxied then proxied else e?.sender_id?.chat_id
        if cid != user?.cid
            group.byuser.push user = {
                cid: cid
                event: []
            }
        user.event.push e
        group.end = e.timestamp
    groups


OBSERVE_OPTS =
    childList:true
    attributes:true
    attributeOldValue:true
    subtree:true

firstRender = true

module.exports = view (models) ->
    # mutation events kicks in after first render
    later scrollToBottom if firstRender
    firstRender = false
    {viewstate, conv, entity} = models
    div class:'messages', observe:onMutate(viewstate.atbottom), ->
        return unless viewstate.selectedConv
        c = conv[viewstate.selectedConv]
        return unless c?.event
        grouped = groupEvents c.event, models.entity
        for g in grouped
            div class:'tgroup', ->
                span class:'timestamp', moment(g.start / 1000).calendar()
                for u in g.byuser
                    sender = nameof entity[u.cid]
                    clz = ['ugroup']
                    clz.push 'self' if entity.isSelf(u.cid)
                    div class:clz.join(' '), ->
                        a href:linkto(u.cid), {onclick}, class:'sender', ->
                            purl = entity[u.cid].photo_url
                            if purl
                                purl = "https://#{purl}" if purl.indexOf('//') == 0
                                img src:purl if purl
                            else
                                entity.needEntity u.cid
                            span sender
                        div class:'umessages', ->
                            for e in u.event
                                mclz = ['message']
                                mclz.push 'placeholder' if e.placeholder
                                div key:e.event_id, class:mclz.join(' '), ->
                                    format e.chat_message?.message_content


# when there's mutation, we scroll to bottom in case we already are at bottom
onMutate = (atbottom) ->
    if atbottom
        throttle 100, (mutts) -> scrollToBottom()
    else
        ->

scrollToBottom = ->
    # ensure we're scrolled to bottom
    el = document.querySelector('.main')
    # to bottom
    el.scrollTop = Number.MAX_SAFE_INTEGER


ifpass = (t, f) -> if t then f else pass

format = (cont) ->
    if cont?.attachment?.length
        formatAttachment cont.attachment
    for seg, i in cont?.segment ? []
        continue if cont.proxied and i < 2
        continue unless seg.text
        f = seg.formatting ? {}
        href = seg?.link_data?.link_target
        ifpass(href, ((f) -> a {href, onclick}, f)) ->
            ifpass(f.bold, b) ->
                ifpass(f.italics, i) ->
                    ifpass(f.underline, u) ->
                        ifpass(f.strikethrough, s) ->
                            pass seg.text
    null

formatAttachment = (att) ->
    {data, type_} = att?[0]?.embed_item ? {}
    t = type_?[0]
    return console.warn 'ignoring attachment type', t unless t == 249
    k = Object.keys(data)?[0]
    return unless k
    href = data?[k]?[5]
    thumb = data?[k]?[9]
    return unless href
    div class:'attach', ->
        a {href, onclick}, -> img src:href, onload: (ev) ->
            # changing the class name triggers the MutationObserver to
            # adjust the scroll position.
            ev.target.className = 'loaded'
