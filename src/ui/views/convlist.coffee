moment = require 'moment'
{nameof, initialsof, nameofconv, fixlink} = require '../util'

module.exports = view (models) ->
    {conv, entity, viewstate} = models
    clz = ['convlist']
    clz.push 'showconvthumbs' if viewstate.showConvThumbs
    clz.push 'showanimatedthumbs' if viewstate.showAnimatedThumbs
    div class:clz.join(' '), ->
        convs = conv.list()
        renderConv = (c) ->
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
                name = nameofconv c
                if viewstate.showConvThumbs or viewstate.showConvMin
                    div class: 'thumbs thumbs-'+(if ents.length>4 then '4' else ents.length), ->
                        for p, index in ents
                            break if index >= 4
                            image = p.photo_url
                            if image and !viewstate.showAnimatedThumbs
                                image += "?sz=50"
                            if image
                                img src:fixlink(image), onerror: ->
                                    this.src = fixlink("images/photo.jpg")
                            else
                                entity.needEntity(p.id)
                                initials = initialsof entity[p.id]
                                div class:'initials', initials

                        if ents.length>4
                            div class:'moreuser', ents.length
                        if ur > 0 and not conv.isQuiet(c)
                            lbl = if ur >= conv.MAX_UNREAD then "#{conv.MAX_UNREAD}+" else ur + ''
                            span class:'unreadcount', lbl
                        if ents.length == 1
                            div class:'presence '+ents[0].presence
                else
                    if ur > 0 and not conv.isQuiet(c)
                        lbl = if ur >= conv.MAX_UNREAD then "#{conv.MAX_UNREAD}+" else ur + ''
                        span class:'unreadcount', lbl
                    if ents.length == 1
                        div class:'presence '+ents[0].presence
                unless viewstate.showConvMin
                    div class:'convinfos', ->
                        if viewstate.showConvTime
                            span class:'lasttime', moment(conv.lastChanged(c)).calendar()
                        span class:'convname', name
                        if viewstate.showConvLast
                            div class:'lastmessage', ->
                                drawMessage(c?.event?.slice(-1)[0], entity)
                            , onDOMSubtreeModified: (e) ->
                                window.twemoji?.parse e.target if process.platform == 'win32'
                div class:'divider'
            , onclick: (ev) ->
                ev.preventDefault()
                action 'selectConv', c

        starred = (c for c in convs when conv.isStarred(c))
        others = (c for c in convs when not conv.isStarred(c))
        div class: 'starred', ->
            div class: 'label', 'Favorites' if starred.length > 0
            starred.forEach renderConv
        div class: 'others', ->
            div class: 'label', 'Recent' if starred.length > 0
            others.forEach renderConv

# possible classes of messages
MESSAGE_CLASSES = ['placeholder', 'chat_message',
'conversation_rename', 'membership_change']

drawMessage = (e, entity) ->
    mclz = ['message']
    mclz.push c for c in MESSAGE_CLASSES when e[c]?
    title = if e.timestamp then moment(e.timestamp / 1000).calendar() else null
    div id:e.event_id, key:e.event_id, class:mclz.join(' '), title:title, ->
        if e.chat_message
            content = e.chat_message?.message_content
            format content
        else if e.conversation_rename
            pass "renamed conversation to #{e.conversation_rename.new_name}"
            # {new_name: "labbot" old_name: ""}
        else if e.membership_change
            t = e.membership_change.type
            ents = e.membership_change.participant_ids.map (p) -> entity[p.chat_id]
            names = ents.map(nameof).join(', ')
            if t == 'JOIN'
                pass "invited #{names}"
            else if t == 'LEAVE'
                pass "#{names} left the conversation"

ifpass = (t, f) -> if t then f else pass

format = (cont) ->
    for seg, i in cont?.segment ? []
        continue if cont.proxied and i < 1
        f = seg.formatting ? {}
        # these are links to images that we try loading
         # as images and show inline. (not attachments)
        ifpass(f.bold, b) ->
            ifpass(f.italics, i) ->
                ifpass(f.underline, u) ->
                    ifpass(f.strikethrough, s) ->
                        # preload returns whether the image
                        # has been loaded. redraw when it
                        # loads.
                        pass if cont.proxied
                            stripProxiedColon seg.text
                        else
                            seg.text
    null
