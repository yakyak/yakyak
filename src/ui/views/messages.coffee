moment = require 'moment'
shell = require 'shell'

{nameof, linkto, later, forceredraw}  = require './vutil'

CUTOFF = 5 * 60 * 1000 * 1000 # 5 mins

isAboutLink = (s) -> (/https:\/\/plus.google.com\/u\/0\/([0-9]+)\/about/.exec(s) ? [])[1]

# this helps fixing houts proxied with things like hangupsbot
# the format of proxied messages are
getProxied = (e) ->
    s = e?.chat_message?.message_content?.segment[0]
    return unless s
    return s?.formatting?.bold == 1 and isAboutLink(s?.link_data?.link_target)

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
        proxied = getProxied(e)
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


module.exports = view (models) ->
    {viewstate, conv, entity} = models
    div class:'messages', ->
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
                                div key:e.event_id, class:'message', ->
                                    format e.chat_message?.message_content

    later ->
        # ensure we're scrolled to bottom
        el = document.querySelector('.main')
        # to bottom
        el.scrollTop = Number.MAX_SAFE_INTEGER


pass = (v) -> if typeof v == 'function' then (v(); undefined) else v
ifpass = (t, f) -> if t then f else pass

format = (cont) ->
    if cont?.attachment?.length
        console.log 'deal with attachment', cont
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
                            span seg.text
    null
