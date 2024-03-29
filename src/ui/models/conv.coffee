entity = require './entity'     #
viewstate = require './viewstate'
{nameof, nameofconv, getProxiedName, later, uniqfn, tryparse}  = require '../util'

merge   = (t, os...) -> t[k] = v for k,v of o when v not in [null, undefined] for o in os; t

lookup = {}

domerge = (id, props) -> lookup[id] = merge (lookup[id] ? {}), props

preprocessMessage = (msg) ->
    cont = msg?.chat_message?.message_content
    embed = cont?.attachment?[0]?.embed_item

    # Workaround for attachments sent through google chat not appearing correctly
    if cont? and embed?.type_?[0] is 456
        index = -1
        url = null
        for seg, i in cont.segment ? []
            if seg.type is "LINK" and seg.link_data?.link_target?
                u = new URL(seg.link_data.link_target)
                if u.hostname.includes 'chat.google.com'
                    url = u
                    index = i
                    break

        if url?
            # Try to extract the name of the attachment from the message
            name = url.href
            if index - 2 >= 0
                name = cont.segment[index - 2]?.text
                names = cont.segment[index - 2]?.text.match(/‘(.+?)’/)
                if names?[1]?
                    name = names[1]

            params = url.searchParams
            type = params.get('url_type')

            isPhoto = type is 'FIFE_URL' and (params.get('width')? or params.get('height')?)
            isVideo = type is 'STREAMING_URL'
            if isPhoto or isVideo
                # Remove the 'I shared ...' message, newline and link
                if index - 2 >= 0
                    cont.segment.splice(index - 2, 3)

                thumburl = new URL(url.toString())
                thumburl.searchParams.set 'url_type', 'FIFE_URL'
                thumburl.searchParams.set 'sz', 's512'

                embed.type_[0] = 249
                embed.data = "and0"
                embed.plus_photo = {}
                embed.plus_photo.data = {}
                embed.plus_photo.data.thumbnail = {}
                embed.plus_photo.data.thumbnail.name = name
                embed.plus_photo.data.thumbnail.image_url = url.toString()
                embed.plus_photo.data.thumbnail.thumb_url = thumburl.toString()
                embed.plus_photo.data.original_content_url = null
                embed.plus_photo.data.media_type = if isPhoto then 'MEDIA_TYPE_PHOTO' else 'MEDIA_TYPE_VIDEO'

                if isVideo
                    embed.plus_photo.videoinformation = {}
                    embed.plus_photo.videoinformation.thumb = thumburl.toString()
                    embed.plus_photo.videoinformation.url = url.toString()
                    embed.plus_photo.videoinformation.public = false
            else
                cont.segment[index].text = name
                cont.segment.splice(index - 2, 2)

    # If we still have a 456 attachment here, unset it as it causes issues with later processing
    if embed?.type_?[0] is 456
        delete cont?.attachment

    msg

add = (conv) ->
    # rejig the structure since it's insane
    if conv?.conversation?.conversation_id?.id
        {conversation, event = []} = conv
        conv = conversation
        # remove observed events
        conv.event = (preprocessMessage(e) for e in event when !e.event_id.match(/observed_/))

    {id} = conv.conversation_id or conv.id
    if lookup[id] and conv?.self_conversation_state?.self_read_state?.latest_read_timestamp == 0
        # don't change latest_read_timestamp if it's 0
        conv?.self_conversation_state?.self_read_state?.latest_read_timestamp = lookup[id].self_conversation_state?.self_read_state?.latest_read_timestamp
    domerge id, conv
    # we mark conversations with few events to know that they definitely
    # got no more history.
    conv.nomorehistory = true if conv.event < 20
    # participant_data contains entity information
    # we want in the entity lookup
    entity.add p for p in conv?.participant_data ? []
    lookup[id]

rename = (conv, newname) ->
    {id} = conv.conversation_id
    lookup[id].name = newname
    updated 'conv'

addChatMessage = (msg) ->
    msg = preprocessMessage msg
    {id} = msg.conversation_id ? {}
    return unless id
    # ignore observed events
    return if msg.event_id?.match(/observed_/)
    conv = lookup[id]
    unless conv
        # a chat message that belongs to no conversation. curious.
        # make something skeletal just to hold the new message
        conv = lookup[id] = {
            conversation_id: {id}
            event: []
            self_conversation_state:sort_timestamp:0
        }
    conv.event = [] unless conv.event
    # we can add message placeholder that needs replacing when
    # the real event drops in. if we find the same event id.
    cpos = findClientGenerated conv, msg?.self_event_state?.client_generated_id
    if not cpos?
        cpos = findByEventId conv, msg.event_id
    if cpos?
        # replace event by position
        conv.event[cpos] = msg
    else
        # add last
        conv.event.push msg
    # update the sort timestamp to list conv first
    conv?.self_conversation_state?.sort_timestamp = msg.timestamp ? (Date.now() * 1000)
    unreadTotal()
    updated 'conv'
    conv
    return msg

findClientGenerated = (conv, client_generated_id) ->
    return unless client_generated_id
    for e, i in conv.event ? []
        return i if e.self_event_state?.client_generated_id == client_generated_id

findByEventId = (conv, event_id) ->
    return unless event_id
    for e, i in conv.event ? []
        return i if e.event_id == event_id

findLastReadEventsByUser = (conv) ->
    last_seen_events_by_user = {}
    for contact in conv.read_state ? []
        chat_id = contact.participant_id.chat_id
        last_read = contact.last_read_timestamp ? contact.latest_read_timestamp
        for e in conv.event ? [] when e.timestamp <= last_read
            last_seen_events_by_user[chat_id] = e
    last_seen_events_by_user


# this is used when sending new messages, we add a placeholder with
# the correct client_generated_id. this entry will be replaced in
# addChatMessage when the real message arrives from the server.
addChatMessagePlaceholder = (chat_id, {conv_id, client_generated_id, segsj, ts, uploadimage, message_action_type}) ->
    ts = ts * 1000 # goog form
    ev =
        chat_message:
            annotation:message_action_type
            message_content:segment:segsj
        conversation_id:id:conv_id
        self_event_state:client_generated_id:client_generated_id
        sender_id:
            chat_id:chat_id
            gaia_id:chat_id
        timestamp:ts
        placeholder:true
        uploadimage:uploadimage
    # lets say this is also read to avoid any badges
    sr = lookup[conv_id]?.self_conversation_state?.self_read_state
    islater = ts > sr?.latest_read_timestamp
    sr.latest_read_timestamp = ts if sr and islater
    # this triggers the model update
    addChatMessage ev

addWatermark = (ev) ->
    conv_id = ev?.conversation_id?.id
    return unless conv_id and conv = lookup[conv_id]
    conv.read_state = [] unless conv.read_state
    {participant_id, latest_read_timestamp} = ev
    conv.read_state.push {
        participant_id
        latest_read_timestamp
    }
    # pack the read_state by keeping the last of each participant_id
    if conv.read_state.length > 200
        rev = conv.read_state.reverse()
        uniq = uniqfn rev, (e) -> e.participant_id.chat_id
        conv.read_state = uniq.reverse()
    sr = conv?.self_conversation_state?.self_read_state
    islater = latest_read_timestamp > sr?.latest_read_timestamp
    if entity.isSelf(participant_id.chat_id) and sr and islater
        sr.latest_read_timestamp = latest_read_timestamp
    unreadTotal()
    updated 'conv'

updateVideoInformation = (conv_id, event_id, photo_id, result) ->
    thumb = result.videoItem?.thumbnail?.url
    url = null
    res = 0
    for stream in result.videoItem?.videoStream ? []
        continue if stream.width * stream.height < res
        res = stream.width * stream.height
        url = stream.playUrl

    conv = lookup[conv_id]
    if conv? and conv.event?
        cpos = findByEventId conv, event_id
        if cpos
            for e in conv.event[cpos].chat_message.message_content.attachment ? []
                plus_photo = e.embed_item.plus_photo
                if plus_photo.data.photo_id is photo_id
                    plus_photo.videoinformation = {
                        thumb: thumb,
                        url: url
                    }

    updated 'conv'

uniqfn = (as, fn) -> bs = as.map fn; as.filter (e, i) -> bs.indexOf(bs[i]) == i

sortby = (conv) -> conv?.self_conversation_state?.sort_timestamp ? 0

# this number correlates to number of max events we get from
# hangouts on client startup.
MAX_UNREAD = 20

unread = (conv) ->
    t = conv?.self_conversation_state?.self_read_state?.latest_read_timestamp
    return 0 unless typeof t == 'number'
    c = 0
    for e in conv?.event ? []
        c++ if e.chat_message and e.timestamp > t and not entity.isSelf e.sender_id.chat_id
        return MAX_UNREAD if c >= MAX_UNREAD
    c

unreadTotal = do ->
    current = 0
    orMore = false
    ->
        sum = (a, b) -> return a + b
        orMore = false
        countunread = (c) ->
            if isQuiet(c) then return 0
            count = funcs.unread c
            if count == MAX_UNREAD then orMore = true
            return count
        newTotal = funcs.list(false).map(countunread).reduce(sum, 0)
        if current != newTotal
            current = newTotal
            later -> action 'unreadtotal', newTotal, orMore
        return newTotal

isQuiet = (c) -> c?.self_conversation_state?.notification_level == 'QUIET'

starredconvs = tryparse(localStorage.starredconvs) || []

isStarred = (c) -> return c?.conversation_id?.id in starredconvs

toggleStar = (c) ->
    {id} = c?.conversation_id
    if id not in starredconvs
        starredconvs.push(id)
    else
        starredconvs = (i for i in starredconvs when i != id)
    localStorage.starredconvs = JSON.stringify(starredconvs);
    updated 'conv'

isEventType = (type) -> (ev) -> !!ev[type]

# a "hangout" is in google terms strictly an audio/video event
# many conversations in the conversation list are just such an
# event with no further chat messages or activity. this function
# tells whether a hangout only contains video/audio.
isPureHangout = do ->
    nots = ['chat_message', 'conversation_rename'].map(isEventType)
    isNotHangout = (e) -> nots.some (f) -> f(e)
    (c) ->
        not (c?.event ? []).some isNotHangout

# the time of the last added event
lastChanged = (c) ->
    time = (c?.event?[(c?.event?.length ? 0) - 1]?.timestamp ? 0)
    if time is 0
        time = (c?.self_conversation_state?.self_read_state?.latest_read_timestamp ? 0)

    time / 1000

lastActiveSec = (c) ->
    part = c?.current_participant ? []
    ents = for p in part when not entity.isSelf p.chat_id
        entity[p.chat_id]

    if ents.length == 1
        return ents?[0]?.lastseen ? 0

    return 0

shouldShow = (c) ->
    pureHang = @isPureHangout(c)
    lastChanged = @lastChanged(c)
    # don't list pure hangouts that are older than 24h
    return false if pureHang and (Date.now() - lastChanged) > 24 * 60 * 60 * 1000
    return true

# the number of history events to request
HISTORY_AMOUNT = 20

# add a typing entry
addTyping = (typing) ->
    conv_id = typing?.conversation_id?.id
    # no typing entries for self
    return if entity.isSelf typing.user_id.chat_id
    # and no entries in non-existing convs
    return unless c = lookup[conv_id]
    c.typing = [] unless c.typing
    # length at start
    len = c.typing.length
    # add new state to start of array
    c.typing.unshift typing
    # ensure there's only one entry in array per user
    c.typing = uniqfn c.typing, (t) -> t.user_id.chat_id
    # and sort it in a stable way
    c.typing.sort (t1, t2) -> t1.user_id.chat_id - t2.user_id.chat_id
    # schedule a pruning
    later -> action 'pruneTyping', conv_id
    # and mark as updated
    updated 'conv'
    # indiciate we just started having typing entries
    updated 'startTyping' if len == 0

# prune old typing entries
pruneTyping = do ->

    findNext = (arr) ->
        expiry = arr.map (t) -> t.timestamp + keepFor(t)
        next = i for t, i in expiry when !next or expiry[i] < expiry[next]
        next

    KEEP_STOPPED = 1500  # time to keep STOPPED typing entries
    KEEP_OTHERS  = 10000 # time to keep other typing entries before pruning

    keepFor = (t) -> if t?.status == 'STOPPED' then KEEP_STOPPED else KEEP_OTHERS

    prune = (t) -> (Date.now() - t?.timestamp / 1000) < keepFor(t)

    (conv_id) ->
        return unless c = lookup[conv_id]
        # stop existing timer
        c.typingtimer = clearTimeout c.typingtimer if c.typingtimer
        # the length before prune
        lengthBefore = c.typing.length
        # filter out old stuff
        c.typing = c.typing.filter(prune)
        # maybe we changed something?
        updated 'conv' if c.typing.length != lengthBefore
        # when is next expiring?
        return unless (nextidx = findNext c.typing) >= 0
        # the next entry to expire
        next = c.typing[nextidx]
        # how long we wait until doing another prune
        waitUntil = (keepFor(next) + next.timestamp / 1000) - Date.now()
        return console.error 'typing prune error', waitUntil if waitUntil < 0
        # schedule next prune
        c.typingtimer = setTimeout (-> action 'pruneTyping', conv_id), waitUntil

funcs =
    count: (showOnly = false) ->
        c = 0; (c++ for k, v of lookup when typeof v == 'object' and (not showOnly or @shouldShow(v))); c

    countShow: ->
        @count true

    _reset: ->
        delete lookup[k] for k, v of lookup when typeof v == 'object'
        updated 'conv'
        null

    _initFromConvStates: (convs) ->
        c = 0
        countIf = (a) -> c++ if a
        countIf add conv for conv in convs
        updated 'conv'
        c

    add:add
    rename: rename
    addChatMessage: addChatMessage
    addChatMessagePlaceholder: addChatMessagePlaceholder
    addWatermark: addWatermark
    MAX_UNREAD: MAX_UNREAD
    unread: unread
    isQuiet: isQuiet
    isStarred: isStarred
    toggleStar: toggleStar
    isPureHangout: isPureHangout
    lastChanged: lastChanged
    lastActiveSec: lastActiveSec
    shouldShow: shouldShow
    addTyping: addTyping
    pruneTyping: pruneTyping
    unreadTotal: unreadTotal
    findLastReadEventsByUser: findLastReadEventsByUser
    updateVideoInformation: updateVideoInformation

    setNotificationLevel: (conv_id, level) ->
        return unless c = lookup[conv_id]
        c.self_conversation_state?.notification_level = level
        updated 'conv'

    deleteConv: (conv_id) ->
        return unless c = lookup[conv_id]
        delete lookup[conv_id]
        viewstate.setSelectedConv null
        updated 'conv'

    removeParticipants: (conv_id, ids) ->
        return unless c = lookup[conv_id]
        getId = (p) -> return p.id.chat_id or p.id.gaia_id
        c.participant_data = (p for p in c.participant_data when getId(p) not in ids)

    addParticipant: (conv_id, participant) ->
        return unless c = lookup[conv_id]
        c.participant_data.push participant

    replaceFromStates: (states) ->
        add st for st in states
        updated 'conv'

    updateAtTop: (attop) ->
        return unless viewstate.state == viewstate.STATE_NORMAL
        conv_id = viewstate?.selectedConv
        if attop and (c = lookup[conv_id]) and !c?.nomorehistory and !c?.requestinghistory
            timestamp = (c.event?[0]?.timestamp ? 0) / 1000
            return unless timestamp
            c.requestinghistory = true
            later -> action 'history', conv_id, timestamp, HISTORY_AMOUNT
            updated 'conv'

    updateMetadata: (state, redraw = true) ->
        conv_id = state?.conversation_id?.id
        return unless c = lookup[conv_id]

        c.read_state = state.conversation?.read_state ? c.read_state

        @redraw_conversation() if redraw

    redraw_conversation: () ->
        # first signal is to give views a change to record the
        # current view position before injecting new DOM
        updated 'beforeHistory'
        # redraw
        updated 'conv'
        # last signal is to move view to be at same place
        # as when we injected DOM.
        updated 'afterHistory'

    updateHistory: (state) ->
        conv_id = state?.conversation_id?.id
        return unless c = lookup[conv_id]
        c.requestinghistory = false
        event = (preprocessMessage(e) for e in state?.event)

        @updateMetadata(state, false)

        c.event = (event ? []).concat (c.event ? [])
        c.nomorehistory = true if event?.length == 0

        @redraw_conversation()

    updatePlaceholderImage: ({conv_id, client_generated_id, path}) ->
        return unless c = lookup[conv_id]
        cpos = findClientGenerated c, client_generated_id
        ev = c.event[cpos]
        seg = ev.chat_message.message_content.segment[0]
        seg.link_data = link_target:path
        updated 'conv'

    list: (sort = true, showOnly = false) ->
        convs = (v for k, v of lookup when typeof v == 'object' and (not showOnly or @shouldShow(v)))
        if sort
            starred = (c for c in convs when isStarred(c))
            convs = (c for c in convs when not isStarred(c))
            starred.sort (e1, e2) -> nameofconv(e1).localeCompare(nameofconv(e2))
            convs.sort (e1, e2) -> sortby(e2) - sortby(e1)
            return starred.concat convs
        convs

    listShow: (sort = true) ->
        @list sort, true



module.exports = merge lookup, funcs
