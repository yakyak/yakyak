{nameof} = require './vutil'

MAX_UNREAD = 20

unread = (conv) ->
    t = conv?.self_conversation_state?.self_read_state?.latest_read_timestamp
    return 0 unless t
    c = 0
    for e in conv?.event ? []
        c++ if e.chat_message and e.timestamp > t
        return MAX_UNREAD if c >= MAX_UNREAD
    c

module.exports = view (models) ->
    {conv, entity} = models
    div class:'convlist', ->
        conv.list().forEach (conv) ->
            cid = conv?.conversation_id?.id
            ur = unread conv
            clz = ['conv']
            clz.push "type_#{conv.type}"
            clz.push "selected" if models.viewstate.selectedConv == cid
            clz.push "unread" if ur
            div key:cid, class:clz.join(' '), ->
                if conv.name?
                    span class:'convname', conv.name
                else
                    # all entities in conversation that is not self
                    part = conv?.current_participant ? []
                    ents = for p in part when not entity.isSelf p.chat_id
                        entity[p.chat_id]
                    # the names of those entities
                    names = ents.map nameof
                    # joined together in a compelling manner
                    span class:'convname', names.join ', '
                if ur > 0
                    lbl = if ur >= MAX_UNREAD then "#{MAX_UNREAD}+" else ur + ''
                    span class:'unreadcount', lbl
            , onclick: (ev) ->
                ev.preventDefault()
                ev.stopPropagation()
                action 'selectConv', conv
