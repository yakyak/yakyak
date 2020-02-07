convSelector = require '../selectors/conversations'
entityModel = require '../models/entity'     #
viewstate = require '../models/viewstate'
{later, uniqfn}  = require '../util'

#
#
#
#
reducer = (state, action) ->
    try
        switch action.type
            when "ADD_CONVERSATION" then add(state, action.payload.conv)
            when "RENAME_CONVERSATION" then rename(state, action.payload)
            when "ADD_CHAT_MESSAGE" then addChatMessage(state, action.payload)
            when "ADD_CHAT_MESSAGE_PLACEHOLDER" then addChatMessagePlaceholder(state, action.payload)
            when "ADD_WATERMARK" then addWatermark(state, action.payload)
            when "TOGGLE_STAR" then toggleStar(state, action.payload)
            when "ADD_TYPING" then addTyping(state, action.payload)
            when "PRUNE_TYPING" then pruneTyping(state, action.payload)
            when "SET_NOTIFICATION_LEVEL" then setNotificationLevel(state, action.payload)
            when "DELETE_CONV" then deleteConv(state, action.payload)
            when "REMOVE_PARTICIPANTS" then removeParticipants(state, action.payload)
            when "ADD_PARTICIPANT" then addParticipant(state, action.payload)
            when "REPLACE_FROM_STATES" then replaceFromStates(state, action.payload)
            when "UPDATE_AT_TOP" then updateAtTop(state, action.payload)
            when "UPDATE_METADATA" then updateMetadata(state, action.payload)
            when "UPDATE_HISTORY" then updateHistory(state, action.payload)
            when "UPDATE_PLACEHOLDER_IMAGE" then updatePlaceholderImage(state, action.payload)
            when "INIT_FROM_CONV_STATES" then initFromConvStates(state, action.payload)
            when "RESET" then reset(state)
            else state
    catch error
        console.log 'Action', action, 'Error:', error
        throw error

module.exports = reducer

#
# Auxiliary functions
#

merge   = (t, os...) -> t[k] = v for k,v of o when v not in [null, undefined] for o in os; t

domerge = (state, id, props) -> state[id] = merge (state[id] ? {}), props

uniqfn = (as, fn) -> bs = as.map fn; as.filter (e, i) -> bs.indexOf(bs[i]) == i

findClientGenerated = (conv, client_generated_id) ->
    return unless client_generated_id
    for e, i in conv.event ? []
        return i if e.self_event_state?.client_generated_id == client_generated_id

findByEventId = (conv, event_id) ->
    return unless event_id
    for e, i in conv.event ? []
        return i if e.event_id == event_id

#
# </ Auxiliary functions
#

add = (state, {conv}) ->
    lookup = state.conversations
    entity = entityModel
    #
    # rejig the structure since it's insane
    if newConv?.conversation?.conversation_id?.id
        {conversation, event} = conv
        conv = conversation
        # remove observed events
        conv.event = (e for e in event when !e.event_id.match(/observed_/))

    {id} = conv.conversation_id or conv.id
    if lookup[id] and conv?.self_conversation_state?.self_read_state?.latest_read_timestamp == 0
        # don't change latest_read_timestamp if it's 0
        conv?.self_conversation_state?.self_read_state?.latest_read_timestamp = lookup[id].self_conversation_state?.self_read_state?.latest_read_timestamp
    domerge lookup, id, conv
    # we mark conversations with few events to know that they definitely
    # got no more history.
    conv.nomorehistory = true if conv.event < 20
    # participant_data contains entity information
    # we want in the entity lookup
    entity.add p for p in conv?.participant_data ? []

    { ...state, entity, conversations: lookup }

addChatMessage = (state, {msg}) ->
    lookup = state.conversations
    {id} = msg.conversation_id ? {}
    return state unless id
    # ignore observed events
    return state if msg.event_id?.match(/observed_/)
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
    conv?.self_conversation_state?.sort_timestamp = msg.timestamp ? (Date.now() * 1000)
    unreadTotal()
    updated 'conv'

    { ...state, conversations: lookup}

# this is used when sending new messages, we add a placeholder with
# the correct client_generated_id. this entry will be replaced in
# addChatMessage when the real message arrives from the server.
addChatMessagePlaceholder = (state, {chat_id, conv_id, client_generated_id, segsj, ts, uploadimage, message_action_type}) ->
    lookup = state.conversations
    #
    ts = ts * 1000 # goog form
    ev =
        chat_message:
            annotation: message_action_type
            message_content:segment: segsj
        conversation_id:id: conv_id
        self_event_state:client_generated_id: client_generated_id
        sender_id:
            chat_id: chat_id
            gaia_id: chat_id
        timestamp: ts
        placeholder: true
        uploadimage: uploadimage
    # lets say this is also read to avoid any badges
    sr = lookup[conv_id]?.self_conversation_state?.self_read_state
    islater = ts > sr?.latest_read_timestamp
    sr.latest_read_timestamp = ts if sr and islater
    # this triggers the model update
    addChatMessage { ...state, conversations: lookup }, {msg: ev}

addParticipant = (state, {conv_id, participant}) ->
    lookup = state.conversations
    #
    return state unless c = lookup[conv_id]
    c.participant_data.push participant
    { ...state, conversations: lookup }

addWatermark = (state, {ev}) ->
    lookup = state.conversations
    entity = entityModel
    #
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

    { ...state, conversations: lookup }

# add a typing entry
addTyping = (state, {typing}) ->
    lookup = state.conversations
    #
    conv_id = typing?.conversation_id?.id
    # no typing entries for self
    return state if entity.isSelf typing.user_id.chat_id
    # and no entries in non-existing convs
    return state unless c = lookup[conv_id]
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

    { ...state, conversations: lookup }

deleteConv = (state, {conv_id}) ->
    lookup = state.conversations
    #
    return state unless c = lookup[conv_id]
    delete lookup[conv_id]
    viewstate.setSelectedConv null
    updated 'conv'
    { ...state, conversations: lookup }

initFromConvStates = (state, {convs}) ->
    c = 0
    countIf = (a) -> c++ if a
    try
        countIf state = add(state, {conv}) for conv in convs
    catch error
        console.log 'initFromConvStates', convs, state, error
        throw error
    updated 'conv'
    state

# prune old typing entries
pruneTyping = (state, {conv_id}) ->
    lookup = state.conversations
    #
    findNext = (arr) ->
        expiry = arr.map (t) -> t.timestamp + keepFor(t)
        next = i for t, i in expiry when !next or expiry[i] < expiry[next]
        next

    KEEP_STOPPED = 1500  # time to keep STOPPED typing entries
    KEEP_OTHERS  = 10000 # time to keep other typing entries before pruning

    keepFor = (t) -> if t?.status == 'STOPPED' then KEEP_STOPPED else KEEP_OTHERS

    prune = (t) -> (Date.now() - t?.timestamp / 1000) < keepFor(t)

    return state unless c = lookup[conv_id]
    # stop existing timer
    c.typingtimer = clearTimeout c.typingtimer if c.typingtimer
    # the length before prune
    lengthBefore = c.typing.length
    # filter out old stuff
    c.typing = c.typing.filter(prune)
    # maybe we changed something?
    updated 'conv' if c.typing.length != lengthBefore
    # when is next expiring?
    return { ...state, conversations: lookup } unless (nextidx = findNext c.typing) >= 0
    # the next entry to expire
    next = c.typing[nextidx]
    # how long we wait until doing another prune
    waitUntil = (keepFor(next) + next.timestamp / 1000) - Date.now()
    if waitUntil < 0
        console.error 'typing prune error', waitUntil
        return { ...state, conversations: lookup }
    # schedule next prune
    c.typingtimer = setTimeout (-> action 'pruneTyping', conv_id), waitUntil

    { ...state, conversations: lookup }

reset = (state) ->
    lookup = state.conversations
    #
    delete lookup[k] for k, v of lookup when typeof v == 'object'
    updated 'conv'

    { ...state, conversations: lookup }

removeParticipants = (state, {conv_id, ids}) ->
    lookup = state.conversations
    #
    return state unless c = lookup[conv_id]
    getId = (p) -> return p.id.chat_id or p.id.gaia_id
    c.participant_data = (p for p in c.participant_data when getId(p) not in ids)
    { ...state, conversations: lookup }

rename = (state, {conv, newname}) ->
    lookup = state.conversations
    {id} = conv.conversation_id
    lookup[id].name = newname
    updated 'conv'

    { ...state, conversations: lookup }

replaceFromStates = (state, {states}) ->
    state = add(state, {conv: st}) for st in states
    updated 'conv'
    state

setNotificationLevel = (state, {conv_id, level}) ->
    lookup = state.conversations
    #
    return state unless c = lookup[conv_id]
    c.self_conversation_state?.notification_level = level
    updated 'conv'
    { ...state, conversations: lookup }

toggleStar = (state, {conv}) ->
    {id} = c?.conversation_id
    if id not in starredconvs
        starredconvs.push(id)
    else
        starredconvs = (i for i in starredconvs when i != id)
    localStorage.starredconvs = JSON.stringify(starredconvs);
    updated 'conv'

    # does nothing to state, stores change in localStorage
    state

updateAtTop = (state, {attop}) ->
    lookup = state.conversations
    #
    return state unless viewstate.state == viewstate.STATE_NORMAL
    conv_id = viewstate?.selectedConv
    if attop and (c = lookup[conv_id]) and !c?.nomorehistory and !c?.requestinghistory
        timestamp = (c.event?[0]?.timestamp ? 0) / 1000
        return state unless timestamp
        c.requestinghistory = true
        later -> action 'history', conv_id, timestamp, convSelector.HISTORY_AMOUNT
        updated 'conv'
    { ...state, conversations: lookup }

updateMetadata = (stateStore, {state, redraw}) ->
    lookup = stateStore.conversations
    #
    conv_id = state?.conversation_id?.id
    return stateStore unless c = lookup[conv_id]

    c.read_state = state.conversation?.read_state ? c.read_state

    convSelector.redraw_conversation() if redraw

    { ...stateStore, conversations: lookup }

updateHistory = (stateStore, {state}) ->
    lookup = stateStore.conversations
    #
    conv_id = state?.conversation_id?.id
    return stateStoer unless c = lookup[conv_id]
    c.requestinghistory = false
    event = state?.event

    stateStore = updateMetadata({ ...stateStore, conversations: lookup }, {state, redraw: false})
    lookup = stateStore.conversations
    #
    return stateStore unless c = lookup[conv_id]

    c.event = (event ? []).concat (c.event ? [])
    c.nomorehistory = true if event?.length == 0

    convSelector.redraw_conversation()
    { ...stateStore, conversations: lookup }

updatePlaceholderImage = (state, {conv_id, client_generated_id, path}) ->
    lookup = state.conversations
    #
    return state unless c = lookup[conv_id]
    cpos = findClientGenerated c, client_generated_id
    ev = c.event[cpos]
    seg = ev.chat_message.message_content.segment[0]
    seg.link_data = link_target:path
    updated 'conv'
    { ...stateStore, conversations: lookup }
