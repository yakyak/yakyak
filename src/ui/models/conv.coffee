entity = require './entity'

merge   = (t, os...) -> t[k] = v for k,v of o when v not in [null, undefined] for o in os; t

lookup = {}

domerge = (id, props) -> lookup[id] = merge (lookup[id] ? {}), props

add = (conv) ->
    conv = conv.conversation if conv?.conversation?.conversation_id?.id
    {id} = conv.conversation_id
    domerge id, conv
    # participant_data contains entity information
    # we want in the entity lookup
    entity.add p for p in conv?.participant_data ? []
    lookup[id]

funcs =
    count: ->
        c = 0; (c++ for k, v of lookup when typeof v == 'object'); c

    _reset: ->
        delete lookup[k] for k, v of lookup when typeof v == 'object'

    _initFromConvStates: (convs) ->
        c = 0
        countIf = (a) -> c++ if a
        countIf add conv for conv in convs
        c

module.exports = merge lookup, funcs
