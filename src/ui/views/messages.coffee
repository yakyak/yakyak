moment = require 'moment'
shell = require 'shell'

{nameof, linkto, later, forceredraw, throttle,
getProxiedName, fixlink, isImg, getImageUrl}  = require '../util'

CUTOFF = 5 * 60 * 1000 * 1000 # 5 mins

# this helps fixing houts proxied with things like hangupsbot
# the format of proxied messages are
# and here we put entities in the entity db for
# users found only in proxied messages.
fixProxied = (e, proxied, entity) ->
    return unless e?.chat_message?.message_content?
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
        e.group_index = user.event.length
        user.event.push e
        group.end = e.timestamp
    groups

# possible classes of messages
MESSAGE_CLASSES = ['placeholder', 'chat_message',
'conversation_rename', 'membership_change']

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
                    if entity.isSelf(u.cid)
                        clz.push 'self'
                    else
                        clz.push 'notself'
                    div class:clz.join(' '), ->
                        a href:linkto(u.cid), {onclick}, class:'sender', ->
                            purl = entity[u.cid]?.photo_url
                            unless purl
                                purl = "images/photo.jpg"
                                entity.needEntity u.cid
                            img src:fixlink(purl)
                            span sender if not entity.isSelf(u.cid)
                        div class:'umessages', ->
                            drawMessage(e, entity, u.event.length) for e in u.event

    if lastConv != conv_id
        lastConv = conv_id
        later atTopIfSmall


drawMessage = (e, entity, group_length) ->
    mclz = ['message']
    mclz.push c for c in MESSAGE_CLASSES when e[c]?
    if (group_length > 1) and (e.group_index == 0)
        mclz.push 'message-top'
    else if (group_length > 1) and (e.group_index == (group_length - 1))
        mclz.push 'message-bot'
    else if (group_length > 1)
        mclz.push 'message-mid'
    title = if e.timestamp then moment(e.timestamp / 1000).calendar() else null
    div id:e.event_id, key:e.event_id, class:mclz.join(' '), title:title, ->
        if e.chat_message
            content = e.chat_message?.message_content
            format content
            # loadInlineImages content
            if e.placeholder and e.uploadimage
                span class:'icon-spin1 animate-spin'
        else if e.conversation_rename
            pass "renamed conversation to #{e.conversation_rename.new_name}"
            # {new_name: "labbot" old_name: ""}
        else if e.membership_change
            t = e.membership_change.type
            ents = e.membership_change.participant_ids.map (p) -> entity[p.chat_id]
            names = ents.map(nameof).join(', ')
            if t == 'JOIN'
                pass "invited #{names}"
            else if t == 'LEAVE'
                pass "#{names} left the conversation"


atTopIfSmall = ->
    screl = document.querySelector('.main')
    msgel = document.querySelector('.messages')
    action 'attop', msgel?.offsetHeight < screl?.offsetHeight


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
    if cont?.attachment?
        try
          formatAttachment cont.attachment
        catch e
          console.error e
    for seg, i in cont?.segment ? []
        continue if cont.proxied and i < 1
        f = seg.formatting ? {}
        # these are links to images that we try loading
         # as images and show inline. (not attachments)
        href = seg?.link_data?.link_target
        imageUrl = getImageUrl href # false if can't find one
        ifpass(imageUrl, div) ->
            ifpass(href, ((f) -> a {href, onclick}, f)) ->
                ifpass(f.bold, b) ->
                    ifpass(f.italics, i) ->
                        ifpass(f.underline, u) ->
                            ifpass(f.strikethrough, s) ->
                                ifpass(imageUrl, div) ->
                                    # preload returns whether the image
                                    # has been loaded. redraw when it
                                    # loads.
                                    if (imageUrl) and (preload imageUrl)
                                        img src: imageUrl
                                    else
                                        pass if cont.proxied
                                            stripProxiedColon seg.text
                                        else
                                            seg.text
    null


stripProxiedColon = (txt) ->
    if txt?.indexOf(": ") == 0
        txt.substring(2)
    else
        txt

preload_cache = {}


preload = (href) ->
    cache = preload_cache[href]
    if not cache
        el = document.createElement 'img'
        el.onload = ->
            return unless typeof el.naturalWidth == 'number'
            el.loaded = true
            later -> action 'loadedimg'
        el.onerror = -> console.log 'error loading image', href
        el.src = href
        preload_cache[href] = el
    return cache?.loaded


formatAttachment = (att) ->
    if att?[0]?.embed_item?.type_
        {href, thumb} = extractProtobufStyle(att)
    else if att?[0]?.embed_item?.type
        {href, thumb} = extractObjectStyle(att)
    else
        console.warn 'ignoring attachment', att unless att?.length == 0
        return
    return unless href

    # here we assume attachments are only images
    if preload href
      div class:'attach', ->
          a {href, onclick}, -> img src:href


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
