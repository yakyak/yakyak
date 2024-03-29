moment    = require 'moment'
urlRegexp = require 'uber-url-regex'
url       = require 'url'
ipc       = require('electron').ipcRenderer

{nameof, initialsof, nameofconv, linkto, later, forceredraw, throttle,
getProxiedName, fixlink, getRedirectedUrl, drawAvatar}  = require '../util'

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

    if e.currentTarget.classList.contains 'public_url'
        ipc.send 'openlink', (fixlink(address))
        return

    patt = new RegExp("^(https?[:][/][/]www[.]google[.](com|[a-z][a-z])[/]url[?]q[=])([^&]+)(&.+)*")
    if patt.test(address)
        address = address.replace(patt, '$3')
        address = unescape(address)
        # this is a link outside google and can be opened directly
        #  as there is no need for authentication
        ipc.send 'openlink', (fixlink(address))
        return

    if urlRegexp({exact: true}).test(address)
        unless url.parse(address).host?
            address = "http://#{address}"

    finalUrl = fixlink(address)

    # Google apis give us an url that is only valid for the current logged user.
    # We can't open this url in the external browser because it may not be authenticated
    # or may be authenticated differently (another user or multiple users).
    # In this case we try to open the url ourselves until we get redirected to the final url
    # of the image/video.
    # The finalURL will be cdn-hosted, static and does not require authentication
    # so we can finally open it in the external browser :(

    getRedirectedUrl finalUrl
    .then (result) ->
        ipc.send 'openlink', result.url

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
    if c?.current_participant?
        for participant in c.current_participant
            entity.needEntity participant.chat_id
    div class:'messages', observe:onMutate(viewstate), ->
        return unless c?.event

        grouped = groupEvents c.event, entity
        div class:'historyinfo', ->
            if c.requestinghistory
                pass 'Requesting history…', -> span class:'material-icons spin', 'donut_large'

        if !viewstate.useSystemDateFormat
            moment.locale(i18n.getLocale())
        else
            moment.locale(window.navigator.language)

        last_seen = conv.findLastReadEventsByUser(c)
        last_seen_chat_ids_with_event = (last_seen, event) ->
            (chat_id for chat_id, e of last_seen when event is e)

        for g in grouped
            div class:'timestamp', moment(g.start / 1000).calendar()
            for u in g.byuser
                sender = nameof entity[u.cid]
                for events in groupEventsByMessageType u.event
                    if isMeMessage events[0]
                        # all items are /me messages if the first one is due to grouping above
                        div class:'ugroup me', ->
                            drawMessageAvatar u, sender, viewstate, entity
                            drawMeMessage e for e in events
                    else
                        clz = ['ugroup']
                        clz.push 'self' if entity.isSelf(u.cid)
                        div class:clz.join(' '), ->
                            drawMessageAvatar u, sender, viewstate, entity
                            div class:'umessages', ->
                                drawMessage(e, entity) for e in events

                            # at the end of the events group we draw who has read any of its events
                            div class: 'seen-list', () ->
                                for e in events
                                    for chat_id in last_seen_chat_ids_with_event(last_seen, e)
                                        skip = entity.isSelf(chat_id) or (chat_id == u.cid)
                                        drawSeenAvatar(
                                            entity[chat_id],
                                            e.event_id,
                                            viewstate,
                                            entity
                                        ) if not skip

    # Go through all the participants and only show his last seen status
    if c?.current_participant?
        for participant in c.current_participant
            # get all avatars
            all_seen = document
            .querySelectorAll(".seen[data-id='#{participant.chat_id}']")
            # select last one
            #  NOT WORKING
            #if all_seen.length > 0
            #    all_seen.forEach (el) ->
            #        el.classList.remove 'show'
            #    all_seen[all_seen.length - 1].classList.add 'show'
    if lastConv != conv_id
        lastConv = conv_id
        later atTopIfSmall

drawMessageAvatar = (u, sender, viewstate, entity) ->
    div class: 'sender-wrapper', ->
        a title: sender, class:'sender', ->
            drawAvatar(u.cid, viewstate, entity)
        span sender

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

drawSeenAvatar = (u, event_id, viewstate, entity) ->
    initials = initialsof u
    div class: "seen"
    , "data-id": u.id
    , "data-event-id": event_id
    , title: u.display_name
    , ->
        drawAvatar(u.id, viewstate, entity)

drawMeMessage = (e) ->
    div class:'message', ->
        e.chat_message?.message_content.segment[0].text

drawMessage = (e, entity) ->
    # console.log 'message', e.chat_message
    mclz = ['message']
    mclz.push c for c in MESSAGE_CLASSES when e[c]?
    title = if e.timestamp then moment(e.timestamp / 1000).calendar() else null
    div id:e.event_id, key:e.event_id, class:mclz.join(' '), title:title, dir: 'auto', ->
        if e.chat_message
            content = e.chat_message?.message_content
            format e, content
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
    el.scrollTop = 0


ifpass = (t, f) -> if t then f else pass

format = (event, cont) ->
    if cont?.attachment?
        try
            formatAttachment event, cont.attachment
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
                            else if seg.type == 'LINE_BREAK'
                                '\n'
                            else
                                seg.text
    # image formatter
    (seg) ->
        href = seg?.link_data?.link_target
        if href and preload href
            el = preload_cache[href]
            imageUrl = el.src
            div ->
                a class:'public_url', {href, onclick}, ->
                    if models.viewstate.showImagePreview
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
            if data.imageUrl and (preload data.imageUrl) and models.viewstate.showImagePreview
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
            if data.imageUrl and (preload data.imageUrl) and models.viewstate.showImagePreview
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
        preload_cache[href] = el

        getRedirectedUrl href
        .then (result) ->
            return unless result.contentType?
            return if result.contentType.indexOf('image') < 0

            el = preload_cache[href]
            el.onload = ->
                return unless typeof el.naturalWidth == 'number'
                el.loaded = true
                later -> action 'loadedimg'
            el.onerror = -> console.log 'error loading image', href, result.url
            el.src = result.url

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
            return if not container?
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

formatAttachment = (event, att) ->
    # console.log 'attachment', att if att.length > 0
    if att?[0]?.embed_item?.type_
        data = extractProtobufStyle(event, att)
        return if not data
        {href, thumb, original_content_url, public_url, video_icon, name} = data
    else if att?[0]?.embed_item?.type
        console.log('THIS SHOULD NOT HAPPEN WTF !!')
        data = extractProtobufStyle(event, att)
        return if not data
        {href, thumb, original_content_url, public_url, video_icon, name} = data
    else
        console.warn 'ignoring attachment', att unless att?.length == 0
        return

    # stickers do not have an href so we link to the original content instead
    href = original_content_url unless href

    name = name or href

    # here we assume attachments are only images
    cls = if public_url then 'public_url' else ''
    preload thumb
    div class:'attach', ->
        a class:cls, {href, onclick}, ->
            if models.viewstate.showImagePreview
                img src:thumb, title: name
                if video_icon
                    div class:'play_button'
            else
                i18n.__('conversation.no_preview_image_click_to_open:Image preview is disabled: click to open it in the browser')

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

extractProtobufStyle = (event, att) ->
    name = null
    href = null
    thumb = null
    public_url = false
    video_icon = false

    embed_item = att?[0]?.embed_item
    {plus_photo, data, type_} = embed_item ? {}
    if plus_photo?
        href  = plus_photo.data?.thumbnail?.image_url
        name = plus_photo.data?.thumbnail?.name
        isVideo = plus_photo.data?.media_type isnt 'MEDIA_TYPE_PHOTO'
        if plus_photo.data?.thumbnail?.thumb_url?
            thumb = plus_photo.data.thumbnail.thumb_url
            video_icon = isVideo
        else
            thumb = href.replace /googleusercontent.com\/(.+)\/s0\/(.+)$/, 'googleusercontent.com/$1/s512/$2'

        original_content_url = plus_photo.data?.original_content_url
        if isVideo
            if plus_photo.videoinformation?
                thumb = plus_photo.videoinformation.thumb
                href = plus_photo.videoinformation.url
                if plus_photo.videoinformation.public?
                    public_url = plus_photo.videoinformation.public
                else
                    public_url = true
            else
                action 'getvideoinformation', event.conversation_id?.id, event.event_id, plus_photo.data?.owner_obfuscated_id, plus_photo.data?.photo_id
        return {href, thumb, original_content_url, public_url, video_icon, name}

    t = type_?[0]
    return console.warn 'ignoring (old) attachment type', att unless t == 249
    k = Object.keys(data)?[0]
    return unless k
    href = data?[k]?[5]
    original_content_url = href

    thumburl = new URL(href)
    thumburl.searchParams.set('size', '512')
    thumb = thumburl.toString()

    {href, thumb, original_content_url, public_url, video_icon, name}

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
