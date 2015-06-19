{nameof, fixlink} = require '../util'

module.exports = view (models) ->
    {conv, entity, viewstate} = models
    clz = ['convlist']
    clz.push 'showconvthumbs' if viewstate.showConvThumbs
    div class:clz.join(' '), ->
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
                part = c?.current_participant ? []
                ents = for p in part when not entity.isSelf p.chat_id
                    entity[p.chat_id]
                name = if c.name?
                    c.name
                else
                    # all entities in conversation that is not self
                    # the names of those entities
                    names = ents.map nameof
                    # joined together in a compelling manner
                    names.join ', '
                if viewstate.showConvThumbs
                    div class: 'thumbs', ->
                        for p, index in ents
                            break if index >= 2
                            image = p.photo_url
                            unless image
                                entity.needEntity(p.id)
                                image = "images/photo.jpg"
                            img src:fixlink(image)
                span class:'convname', name
                if ur > 0 and not conv.isQuiet(c)
                    lbl = if ur >= conv.MAX_UNREAD then "#{conv.MAX_UNREAD}+" else ur + ''
                    span class:'unreadcount', lbl
                div class:'divider'
                if c.typing?.length > 0
                    anyTyping = c.typing.filter((t) -> t?.status == 'TYPING').length
                    tclz = ['convtyping']
                    tclz.push 'animate-growshrink' if anyTyping
                    span class:tclz.join(' '), '⋮'
            , onclick: (ev) ->
                ev.preventDefault()
                action 'selectConv', c
