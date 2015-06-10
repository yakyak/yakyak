{nameof} = require '../util'

module.exports = view (models) ->
    {conv, entity, viewstate} = models
    div class:'convlist', ->
        conv.list().forEach (c) ->
            pureHang = conv.isPureHangout(c)
            lastChanged = conv.lastChanged(c)
            # don't list pure hangouts that are older than 24h
            return if pureHang and (Date.now() - lastChanged) > 24 * 60 * 60 * 1000
            cid = c?.conversation_id?.id
            ur = conv.unread c
            clz = ['conv']
            clz.push "type_#{c.type}"
            clz.push "selected" if models.viewstate.selectedConv == cid
            clz.push "unread" if ur
            clz.push "purehang" if pureHang
            div key:cid, class:clz.join(' '), ->
                name = if c.name?
                    c.name
                else
                    # all entities in conversation that is not self
                    part = c?.current_participant ? []
                    ents = for p in part when not entity.isSelf p.chat_id
                        entity[p.chat_id]
                    # the names of those entities
                    names = ents.map nameof
                    # joined together in a compelling manner
                    names.join ', '
                span class:'convname', name
                if ur > 0 and not conv.isQuiet(c)
                    lbl = if ur >= conv.MAX_UNREAD then "#{conv.MAX_UNREAD}+" else ur + ''
                    span class:'unreadcount', lbl
            , onclick: (ev) ->
                ev.preventDefault()
                action 'selectConv', c
