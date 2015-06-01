entity = require './entity'

merge   = (t, os...) -> t[k] = v for k,v of o when v not in [null, undefined] for o in os; t

lookup = {}

domerge = (id, props) -> lookup[id] = merge (lookup[id] ? {}), props

add = (conv) ->
    # rejig the structure since it's insane
    if conv?.conversation?.conversation_id?.id
        {conversation, event} = conv
        conv = conversation
        conv.event = event
    {id} = conv.conversation_id
    domerge id, conv
    # participant_data contains entity information
    # we want in the entity lookup
    entity.add p for p in conv?.participant_data ? []
    lookup[id]

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
        }
    conv.event = [] unless conv.event
    # we can add message placeholder that needs replacing when
    # the real event drops in. if we find the same event id.
    cpos = findClientGenerated conv, msg?.self_event_state?.client_generated_id
    if cpos
        # replace
        conv.event[cpos] = msg
    else
        # add last
        conv.event.push msg
    conv?.self_conversation_state?.sort_timestamp = msg.timestamp
    updated 'conv'
    conv

findClientGenerated = (conv, client_generated_id) ->
    return unless client_generated_id
    for e, i in conv.event ? []
        return i if e.self_event_state?.client_generated_id == client_generated_id

addChatMessagePlaceholder = (conv_id, chat_id, client_generated_id, segs) ->
    # e.self_event_state.client_generated_id
    ev =
        chat_message:message_content:segment:segs
        conversation_id:id:conv_id
        self_event_state:client_generated_id:client_generated_id
        sender_id:
            chat_id:chat_id
            gaia_id:chat_id
        timestamp:(Date.now() * 1000)
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
    sr = conv?.self_conversation_state?.self_read_state
    if entity.isSelf(participant_id.chat_id) and sr
        sr.latest_read_timestamp = latest_read_timestamp
    updated 'conv'

sortby = (conv) ->
    conv?.self_conversation_state?.sort_timestamp ? 0

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

    addChatMessage: addChatMessage
    addChatMessagePlaceholder: addChatMessagePlaceholder
    addWatermark: addWatermark

    list: ->
        convs = (v for k, v of lookup when typeof v == 'object')
        convs.sort (e1, e2) -> sortby(e2) - sortby(e1)
        convs



module.exports = merge lookup, funcs
