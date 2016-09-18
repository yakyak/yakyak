moment = require 'moment'
shell = require('electron').shell

{nameof, initialsof, nameofconv, linkto, later, forceredraw, throttle,
getProxiedName, fixlink, isImg, getImageUrl}  = require '../util'

CUTOFF = 5 * 60 * 1000 * 1000 # 5 mins

# chat_message:
#   {
#     annotation: [
#       [4, ""]
#     ]
#     message_content: {
#       attachement: []
#       segment: [{ ... }]
#     }
#   }
HANGOUT_ANNOTATION_TYPE = {
    me_message: 4
}

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
  patt = new RegExp("^(https?[:][/][/]www[.]google[.](com|[a-z][a-z])[/]url[?]q[=])([^&]+)(&.+)*")
  if patt.test(address)
    address = address.replace(patt, '$3')
    address = unescape(address)
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
    for participant in c.current_participant
      entity.needEntity participant.chat_id
    div class:'messages', observe:onMutate(viewstate), ->
        return unless c?.event
        grouped = groupEvents c.event, entity
        div class:'historyinfo', ->
            if c.requestinghistory
                pass 'Requesting history…', -> span class:'material-icons spin', 'donut_large'
        for g in grouped
            div class:'timestamp', moment(g.start / 1000).calendar()
            for u in g.byuser
                sender = nameof entity[u.cid]
                for events in groupEventsByMessageType u.event
                    if isMeMessage events[0]
                        # all items are /me messages if the first one is due to grouping above
                        div class:'ugroup me', ->
                            drawAvatar u, sender, viewstate, entity
                            drawMeMessage e for e in events
                    else
                        clz = ['ugroup']
                        clz.push 'self' if entity.isSelf(u.cid)
                        div class:clz.join(' '), ->
                            drawAvatar u, sender, viewstate, entity
                            div class:'umessages', ->
                                drawMessage(e, entity) for e in events
                            , onDOMSubtreeModified: (e) ->
                                window.twemoji?.parse e.target if process.platform == 'win32'

    if lastConv != conv_id
        lastConv = conv_id
        later atTopIfSmall


groupEventsByMessageType = (event) ->
    res = []
    index = 0
    prevWasMe = true
    for e in event
        if isMeMessage e
            index = res.push [e]
            prevWasMe = true
        else
            if prevWasMe
                index = res.push [e]
            else
                res[index - 1].push e
            prevWasMe = false
    return res

isMeMessage = (e) ->
    e?.chat_message?.annotation?[0]?[0] == HANGOUT_ANNOTATION_TYPE.me_message

drawAvatar = (u, sender, viewstate, entity) ->
    initials = initialsof entity[u.cid]
    a href:linkto(u.cid), title:sender, {onclick}, class:'sender', ->
        purl = entity[u.cid]?.photo_url
        if purl and !viewstate?.showAnimatedThumbs
            purl += "?sz=50"
        if purl
            img src:fixlink(purl)
        else
            div class:'initials', initials

drawMeMessage = (e) ->
    div class:'message', ->
        e.chat_message?.message_content.segment[0].text

drawMessage = (e, entity) ->
    mclz = ['message']
    mclz.push c for c in MESSAGE_CLASSES when e[c]?
    title = if e.timestamp then moment(e.timestamp / 1000).calendar() else null
    div id:e.event_id, key:e.event_id, class:mclz.join(' '), title:title, ->
        if e.chat_message
            content = e.chat_message?.message_content
            format content
            # loadInlineImages content
            if e.placeholder and e.uploadimage
                span class:'material-icons spin', 'donut_large'
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
        else if e.hangout_event
          hangout_event = e.hangout_event
          style = 'vertical-align': 'middle'
          if hangout_event.event_type is 'START_HANGOUT'
              span { class: 'material-icons', style }, 'call_made_small'
              pass ' Call started'
          else if hangout_event.event_type is 'END_HANGOUT'
              span { class:'material-icons small', style }, 'call_end'
              pass ' Call ended'
        else
          console.log 'unhandled event type', e, entity


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
        formatters.forEach (fn) ->
            fn seg, cont
    null


formatters = [
    # text formatter
    (seg, cont) ->
        f = seg.formatting ? {}
        href = seg?.link_data?.link_target
        ifpass(href, ((f) -> a {href, onclick}, f)) ->
            ifpass(f.bold, b) ->
                ifpass(f.italic, i) ->
                    ifpass(f.underline, u) ->
                        ifpass(f.strikethrough, s) ->
                            pass if cont.proxied
                                stripProxiedColon seg.text
                            else
                                seg.text
    # image formatter
    (seg) ->
        href = seg?.link_data?.link_target
        imageUrl = getImageUrl href # false if can't find one
        if imageUrl and preload imageUrl
            div ->
                img src: imageUrl
    # twitter preview
    (seg) ->
        href = seg?.text
        if !href
            return
        matches = href.match /^(https?:\/\/)(.+\.)?(twitter.com\/.+\/status\/.+)/
        if !matches
            return
        data = preloadTweet matches[1] + matches[3]
        if !data
            return
        div class:'tweet', ->
            if data.text
                p ->
                    data.text
            if data.imageUrl and preload data.imageUrl
                img src: data.imageUrl
    # instagram preview
    (seg) ->
        href = seg?.text
        if !href
            return
        matches = href.match /^(https?:\/\/)(.+\.)?(instagram.com\/p\/.+)/
        if !matches
            return
        data = preloadInstagramPhoto 'https://api.instagram.com/oembed/?url=' + href
        if !data
            return
        div class:'instagram', ->
            if data.text
                p ->
                    data.text
            if data.imageUrl and preload data.imageUrl
                img src: data.imageUrl
]

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

preloadTweet = (href) ->
    cache = preload_cache[href]
    if not cache
        preload_cache[href] = {}
        fetch href
        .then (response) ->
            response.text()
        .then (html) ->
            frag = document.createElement 'div'
            frag.innerHTML = html
            container = frag.querySelector '[data-associated-tweet-id]'
            textNode = container.querySelector ('.tweet-text')
            image = container.querySelector ('[data-image-url]')
            preload_cache[href].text = textNode.textContent
            preload_cache[href].imageUrl = image?.dataset.imageUrl
            later -> action 'loadedtweet'
    return cache

preloadInstagramPhoto = (href) ->
    cache = preload_cache[href]
    if not cache
        preload_cache[href] = {}
        fetch href
        .then (response) ->
            response.json()
        .then (json) ->
            preload_cache[href].text = json.title
            preload_cache[href].imageUrl = json.thumbnail_url
            later -> action 'loadedinstagramphoto'
    return cache

formatAttachment = (att) ->
    console.log 'attachment', att if att.length > 0
    if att?[0]?.embed_item?.type_
        data = extractProtobufStyle(att)
        return if not data
        {href, thumb} = data
    else if att?[0]?.embed_item?.type
        data = extractProtobufStyle(att)
        return if not data
        {href, thumb} = data
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

handle 'loadedtweet', ->
    updated 'conv'

handle 'loadedinstagramphoto', ->
    updated 'conv'

extractProtobufStyle = (att) ->
    eitem = att?[0]?.embed_item
    {data, type_} = eitem ? {}
    t = type_?[0]
    return console.warn 'ignoring (old) attachment type', att unless t == 249
    k = Object.keys(data)?[0]
    return unless k
    href = data?[k]?[5]
    thumb = data?[k]?[9]
    if not thumb
      href = data?[k]?[4]
      thumb = data?[k]?[5]

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
