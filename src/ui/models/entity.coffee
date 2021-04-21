
merge   = (t, os...) -> t[k] = v for k,v of o when v not in [null, undefined] for o in os; t
shallowif = (o, f) -> r = {}; r[k] = v for k, v of o when f(k,v); r

lookup = {}

domerge = (id, props) -> lookup[id] = merge (lookup[id] ? {}), props

add = (entity, opts = silent:false) ->
    {gaia_id, chat_id} = entity?.id ? {}
    return null unless gaia_id or chat_id

    # ensure there is at least something
    lookup[chat_id] = {} unless lookup[chat_id]

    # dereference .properties to be on main obj
    if entity.properties
        domerge chat_id, entity.properties

    # merge rest of props
    clone = shallowif entity, (k) -> k not in ['id', 'properties']
    domerge chat_id, clone

    lookup[chat_id].id = chat_id

    # handle different chat_id to gaia_id
    lookup[gaia_id] = lookup[chat_id] if chat_id != gaia_id

    updated 'entity' unless opts.silent

    # return the result
    lookup[chat_id]


needEntity = do ->
    tim = null
    gather = []
    fetch = ->
        tim = null
        action 'getentity', gather
        gather = []
    (id, wait=1000) ->
        return if lookup[id]?.fetching
        if lookup[id]
            lookup[id].fetching = true
        else
            lookup[id] = {
                id: id
                fetching: true
            }
        clearTimeout tim if tim
        tim = setTimeout fetch, wait
        gather.push id

list = ->
    v for k, v of lookup when typeof v == 'object'



funcs =
    count: ->
        c = 0; (c++ for k, v of lookup when typeof v == 'object'); c

    list: list

    setPresence: (id, p) ->
        console.error('setPresence', id, p)
        return needEntity(id) if not lookup[id]
        lookup[id].presence = p
        updated 'entity'

    setLastSeen: (id, lastseen) ->
        return if @isSelf id
        console.error('setLastSeen', id, lastseen)
        return needEntity(id) if not lookup[id]
        console.error('lastseen', id, lookup[id], lastseen)
        lookup[id].lastseen = lastseen
        lookup[id].presence = true
        updated 'entity'

    isSelf: (chat_id) -> return !!lookup.self and lookup[chat_id] == lookup.self

    updatePresence: ->
        if lookup.self?.lastseen?
            changed = false
            cutoff = lookup.self.lastseen - (60 * 15)
            for k, v of lookup when v.presence
                if !v.lastseen?
                    v.lastseen = lookup.self.lastseen

                if v.lastseen <= cutoff
                    v.presence = false
                    changed = true

            updated 'entity' if changed

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
    needEntity: needEntity

module.exports = merge lookup, funcs
