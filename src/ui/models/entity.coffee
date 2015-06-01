
merge   = (t, os...) -> t[k] = v for k,v of o when v not in [null, undefined] for o in os; t
shallowif = (o, f) -> r = {}; r[k] = v for k, v of o when f(k,v); r

lookup = {}

domerge = (id, props) -> lookup[id] = merge (lookup[id] ? {}), props

add = (entity, opts = silent:false) ->
    {gaia_id, chat_id} = entity?.id ? {}
    return null unless gaia_id or chat_id

    # dereference .properties to be on main obj
    if entity.properties
        domerge gaia_id, entity.properties

    # merge rest of props
    clone = shallowif entity, (k) -> k not in ['id', 'properties']
    domerge gaia_id, clone

    lookup[gaia_id].id = gaia_id

    # handle different chat_id to gaia_id
    lookup[chat_id] = lookup[gaia_id] if chat_id != gaia_id

    updated 'entity' unless opts.silent

    # return the result
    lookup[chat_id]

funcs =
    count: ->
        c = 0; (c++ for k, v of lookup when typeof v == 'object'); c

    isSelf: (chat_id) -> return lookup[chat_id] == lookup.self

    _reset: ->
        delete lookup[k] for k, v of lookup when typeof v == 'object'
        updated 'entity'
        null

    _initFromSelfEntity: (self) ->
        updated 'entity'
        lookup.self = add self

    _initFromEntities:   (entities) ->
        c = 0
        countIf = (a) -> c++ if a
        countIf add entity for entity in entities
        updated 'entity'
        c

    add: add

module.exports = merge lookup, funcs
