entity = require './entity'
viewstate = require './viewstate'
{nameof, getProxiedName, later}  = require '../util'

merge   = (t, os...) -> t[k] = v for k,v of o when v not in [null, undefined] for o in os; t

lookup = {}

domerge = (id, props) -> lookup[id] = merge (lookup[id] ? {}), props

add = (conv) ->
    # rejig the structure since it's insane
    if conv?.conversation?.conversation_id?.id
        {conversation, event} = conv
        conv = conversation
        conv.event = event
    {id} = conv.conversation_id or conv.id
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
    {id} = msg.conversation_id ? {}
    return unless id
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
    unless cpos
        cpos = findByEventId conv, msg.event_id
    if cpos
        # replace event by position
        conv.event[cpos] = msg
    else
        # add last
        conv.event.push msg
    # update the sort timestamp to list conv first
    conv?.self_conversation_state?.sort_timestamp = msg.timestamp
    unreadTotal()
    updated 'conv'
    conv

findClientGenerated = (conv, client_generated_id) ->
    return unless client_generated_id
    for e, i in conv.event ? []
        return i if e.self_event_state?.client_generated_id == client_generated_id

findByEventId = (conv, event_id) ->
    return unless event_id
    for e, i in conv.event ? []
        return i if e.event_id == event_id


# this is used when sending new messages, we add a placeholder with
# the correct client_generated_id. this entry will be replaced in
# addChatMessage when the real message arrives from the server.
addChatMessagePlaceholder = (chat_id, {conv_id, client_generated_id, segsj, ts}) ->
    ts = ts * 1000 # goog form
    ev =
        chat_message:message_content:segment:segsj
        conversation_id:id:conv_id
        self_event_state:client_generated_id:client_generated_id
        sender_id:
            chat_id:chat_id
            gaia_id:chat_id
        timestamp:ts
        placeholder:true
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
        c++ if e.chat_message and e.timestamp > t
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
        newTotal = funcs.list(false).map(countunread).reduce(sum,0)
        if current != newTotal
            current = newTotal
            later -> action 'unreadtotal', newTotal, orMore

isQuiet = (c) -> c?.self_conversation_state?.notification_level == 'QUIET'

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
lastChanged = (c) -> (c?.event[c.event.length - 1]?.timestamp ? 0) / 1000

# the number of history events to request
HISTORY_AMOUNT = 20

funcs =
    count: ->
        c = 0; (c++ for k, v of lookup when typeof v == 'object'); c

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
    isPureHangout: isPureHangout
    lastChanged: lastChanged

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

    updateHistory: (state) ->
        conv_id = state?.conversation_id?.id
        return unless c = lookup[conv_id]
        c.requestinghistory = false
        event = state?.event
        c.event = (event ? []).concat (c.event ? [])
        c.nomorehistory = true if (event?.length ? 0) < HISTORY_AMOUNT

        # first signal is to give views a change to record the
        # current view position before injecting new DOM
        updated 'beforeHistory'
        # redraw
        updated 'conv'
        # last signal is to move view to be at same place
        # as when we injected DOM.
        updated 'afterHistory'

    updatePlaceholderImage: ({conv_id, client_generated_id, path}) ->
        return unless c = lookup[conv_id]
        cpos = findClientGenerated c, client_generated_id
        ev = c.event[cpos]
        seg = ev.chat_message.message_content.segment[0]
        seg.link_data = link_target:path
        updated 'conv'

    list: (sort = true) ->
        convs = (v for k, v of lookup when typeof v == 'object')
        if sort
            convs.sort (e1, e2) -> sortby(e2) - sortby(e1)
        convs



module.exports = merge lookup, funcs
