moment = require 'moment'
shell = require 'shell'

{nameof, linkto, later, forceredraw, throttle,
getProxiedName, fixlink}  = require '../util'

isImg = (url) -> url?.match /\.(png|jpg|gif|svg)$/i

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
  shell.openExternal fixlink(address)

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

firstRender       = true
lastConv          = null # to detect conv switching

module.exports = view (models) ->
    {viewstate, conv, entity} = models

    # mutation events kicks in after first render
    later onMutate(viewstate) if firstRender
    firstRender = false

    conv_id = viewstate?.selectedConv
    c = conv[conv_id]
    div class:'messages', observe:onMutate(viewstate), ->
        return unless c?.event
        grouped = groupEvents c.event, entity
        div class:'historyinfo', ->
            if c.requestinghistory
                pass 'Requesting history…', -> span class:'icon-spin1 animate-spin'
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
                                img src:fixlink(purl)
                            else
                                entity.needEntity u.cid
                            span sender
                        div class:'umessages', ->
                            for e in u.event
                                mclz = ['message']
                                mclz.push 'placeholder' if e.placeholder
                                div id:e.event_id, key:e.event_id, class:mclz.join(' '), ->
                                    format e.chat_message?.message_content
    if lastConv != conv_id
        lastConv = conv_id
        later atTopIfSmall


atTopIfSmall = ->
    screl = document.querySelector('.main')
    msgel = document.querySelector('.messages')
    action 'attop', msgel.offsetHeight < screl.offsetHeight


# when there's mutation, we scroll to bottom in case we already are at bottom
onMutate = (viewstate) -> throttle 10, ->
    # jump to bottom to follow conv
    scrollToBottom() if viewstate.atbottom


scrollToBottom = module.exports.scrollToBottom = ->
    # ensure we're scrolled to bottom
    el = document.querySelector('.main')
    # to bottom
    el.scrollTop = Number.MAX_SAFE_INTEGER


ifpass = (t, f) -> if t then f else pass

format = (cont) ->
    if cont?.attachment?.length
        try
          formatAttachment cont.attachment
        catch e
          console.error e
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
    unless att?.imgel
        if att?[0]?.embed_item?.type_
            {href, thumb} = extractProtobufStyle(att)
        else if att?[0]?.embed_item?.type
            {href, thumb} = extractObjectStyle(att)
        else
            return console.warn 'ignoring attribute', att
        return unless href
        preload att, href

    # only insert loaded images
    if att?.imgel?.loaded
        href = att.imgel.src
        div class:'attach', ->
            a {href, onclick}, -> img src:href


preload = (att, href) ->
    att.imgel = document.createElement 'img'
    att.imgel.onload = ->
        # spot whether it is finished
        return unless typeof att.imgel.naturalWidth == 'number'
        # signal to ui it's done
        att.imgel.loaded = true
        # and draw it in an orderly manner
        later -> action 'loadedimg'
    att.imgel.src = href

handle 'loadedimg', ->
    # allow controller to record current position
    updated 'beforeImg'
    # will do the redraw inserting the image
    updated 'conv'
    # fix the position after redraw
    updated 'afterImg'


extractProtobufStyle = (att) ->
    eitem = att?[0]?.embed_item
    {data, type_} = eitem ? {}
    t = type_?[0]
    return console.warn 'ignoring (old) attachment type', att unless t == 249
    k = Object.keys(data)?[0]
    return unless k
    href = data?[k]?[5]
    thumb = data?[k]?[9]
    {href, thumb}

extractObjectStyle = (att) ->
    eitem = att?[0]?.embed_item
    {type} = eitem ? {}
    if type?[0] == "PLUS_PHOTO"
        it = eitem["embeds.PlusPhoto.plus_photo"]
        href = it?.url
        thumb = it?.thumbnail?.url
        return {href, thumb}
    else
        console.warn 'ignoring (new) type', type


isImg = (url) -> url?.match /\.(png|jpg|gif|svg)$/i

loadImages = (conv_id, cont) ->
    for seg, i in cont?.segment ? []
        href = seg?.link_data?.link_target
        if isImg(href) and !seg.link_data.img
            seg.link_data.img = imgel = document.createElement 'img'
            imgel.src = href
            imgel.onload = (ev) ->
                return unless typeof img.naturalWidth == 'number'
                action 'imgload', conv_id
