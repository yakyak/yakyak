
{initialsof, throttle, nameof, fixlink, drawAvatar} = require '../util'
chilledaction = throttle 1500, action

unique = (obj) -> obj.id.chat_id or obj.id.gaia_id

mayRestoreInitialValues = (models) ->
    # If there is an initial value we set it an then invalidate it
    {convsettings} = models
    initialName = convsettings.getInitialName()
    if initialName != null
        setTimeout ->
            name = document.querySelector '.name-input'
            name.value = initialName if name
        , 1
    initialSearchQuery = convsettings.getInitialSearchQuery()
    if initialSearchQuery != null
        setTimeout ->
            search = document.querySelector '.search-input'
            search.value = initialSearchQuery if search
        , 1
    setTimeout ->
        group = document.querySelector '.group'
        group.checked = convsettings.group if group
    null

inputSetValue = (sel, val) ->
    setTimeout ->
        el = document.querySelector sel
        el.value = val if el != null
    , 1
    null

module.exports = view (models) ->
    {viewstate, convsettings, entity, conv} = models

    editing = convsettings.id != null
    conversation = conv[viewstate.selectedConv]

    div class: 'convadd', ->
        if editing
            h1 i18n.__ 'conversation.edit:Conversation edit'
        else
            h1 i18n.__ 'conversation.new:New conversation'

        style = {}
        if not convsettings.group
            style = display: 'none'

        div class: 'input', {style}, ->
            div ->
                input
                    class: 'name-input'
                    style: style
                    placeholder: i18n.__ 'conversation.name:Conversation name'
                    onkeyup: (e) ->
                        action 'conversationname', e.currentTarget.value

        div class: 'input', ->
            div ->
                input
                    class: 'search-input'
                    placeholder: i18n.__ 'conversation.search:Search people'
                    onkeyup: (e) ->
                        chilledaction 'searchentities', e.currentTarget.value, 7
                        action 'conversationquery', e.currentTarget.value, 7

        div class: 'input', ->
            div ->
                p ->
                    opts =
                        type: 'checkbox'
                        class: 'group'
                        style: { width: 'auto', 'margin-right': '5px' }
                        onchange: (e) -> action   'togglegroup'
                    if convsettings.selectedEntities.length != 1
                        opts.disabled = 'disabled'
                    input opts
                    i18n.__ 'conversation.multiuser:Create multiuser chat'


        ul ->
            convsettings.selectedEntities.forEach (r) ->
                cid = r?.id?.chat_id
                ctLocal = ''
                ctInfo = ''
                console.debug('meme', r.properties, entity[cid])
                if entity[cid]?.type == 0
                    ctLocal = 'ct-local'
                    ctInfo = 'Internal Contact' + "\r\n"
                if (r.properties?.emails?[0] ? entity[cid]?.emails?[0])
                    ctInfo += (r.properties?.emails?[0] ? entity[cid]?.emails?.join("\r\n")) + "\r\n"
                if r.properties?.organization
                    ctInfo += r.properties?.organization + "\r\n"
                if r.properties?.location
                    ctInfo += r.properties?.location + "\r\n"
                li title:ctInfo, class: ctLocal + ' selected', ->
                    drawAvatar cid, viewstate, entity
                    , (r.properties?.photo_url ? entity[cid]?.photo_url)
                    , ctInfo
                    , (if r.properties? then initialsof r.properties?)
                    p nameof r.properties
                , onclick:(e) -> if not editing then action 'deselectentity', r

            selected_ids = (unique(c) for c in convsettings.selectedEntities)

            convsettings.searchedEntities.forEach (r) ->
                cid = r?.id?.chat_id
                ctLocal = ''
                ctInfo = ''
                if entity[cid]?.type == 0
                    ctLocal = 'ct-local'
                    ctInfo = 'Internal Contact' + "\r\n"
                if (r.properties?.emails?[0] ? entity[cid]?.emails?[0])
                    ctInfo += (r.properties?.emails?[0] ? entity[cid]?.emails?.join("\r\n")) + "\r\n"
                if r.properties?.organization
                    ctInfo += r.properties?.organization + "\r\n"
                if r.properties?.location
                    ctInfo += r.properties?.location + "\r\n"
                if unique(r) in selected_ids then return
                li title:ctInfo, class:ctLocal, ->
                    drawAvatar cid, viewstate, entity
                    , (r.properties?.photo_url ? entity[cid]?.photo_url)
                    , ctInfo
                    , (if r.properties? then initialsof r.properties?)
                    p nameof r.properties
                , onclick:(e) -> action 'selectentity', r

        if editing
            div class:'leave', ->
                if conversation?.type?.indexOf('ONE_TO_ONE') > 0
                    div class:'button'
                    , title: i18n.__('conversation.delete:Delete conversation')
                    , onclick:onclickaction('deleteconv'), ->
                        span class:'material-icons', 'close'
                        span i18n.__('conversation.delete:Delete conversation')
                else
                    div class:'button'
                    , title: i18n.__('conversation.leave:Leave conversation')
                    , onclick:onclickaction('leaveconv'), ->
                        span class:'material-icons', 'close'
                        span i18n.__('conversation.leave:Leave conversation')

        div class:'validate', ->
            disabled = null
            if convsettings.selectedEntities.length <= 0
                disabled =  disabled: 'disabled'
            div disabled, class:'button'
            , onclick:onclickaction('saveconversation'), ->
                span class:'material-icons', 'done'
                span i18n.__ "actions.ok:OK"

        mayRestoreInitialValues models

onclickaction = (a) -> (ev) -> action a
