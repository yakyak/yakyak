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
    conv.event.push msg
    updated 'conv'
    conv

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

    list: ->
        convs = (v for k, v of lookup when typeof v == 'object')
        convs.sort (e1, e2) -> sortby(e2) - sortby(e1)
        convs



module.exports = merge lookup, funcs
