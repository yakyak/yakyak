
{throttle, nameof, fixlink} = require '../util'
chilledaction = throttle 1500, action

unique = (obj) -> obj.id.chat_id or obj.id.gaia_id

photoUrlProtocolFix = (url) -> if url?.indexOf('//') == 0 then "https:#{url}" else url

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
    null

inputSetValue = (sel, val) ->
    setTimeout ->
        el = document.querySelector sel
        el.value = val if el != null
    , 1
    null

module.exports = view (models) ->
    {convsettings, entity} = models
    editing = convsettings.id != null

    div class: 'convadd', ->
      if editing then h1 'Conversation edit' else h1 'New conversation'

      div class: 'input', ->
          div ->
              input
                  class: 'name-input'
                  placeholder: 'Conversation name'
                  onkeyup: (e) ->
                      action 'conversationname', e.currentTarget.value

      div class: 'input', ->
          div ->
              input
                  class: 'search-input'
                  placeholder:'Search people'
                  onkeyup: (e) ->
                      chilledaction 'searchentities', e.currentTarget.value, 7
                      action 'conversationquery', e.currentTarget.value, 7

      ul ->
          convsettings.selectedEntities.forEach (r) ->
              cid = r?.id?.chat_id
              li class: 'selected', ->
                  if purl = r.properties?.photo_url ? entity[cid]?.photo_url
                      img src:fixlink(purl)
                  else
                      img src:"images/photo.jpg"
                      entity.needEntity cid
                  p nameof r.properties
              , onclick:(e) -> if not editing then action 'deselectentity', r

          selected_ids = (unique(c) for c in convsettings.selectedEntities)

          convsettings.searchedEntities.forEach (r) ->
              cid = r?.id?.chat_id
              if unique(r) in selected_ids then return
              li ->
                  if purl = r.properties?.photo_url ? entity[cid]?.photo_url
                      img src:fixlink(purl)
                  else
                      img src:"images/photo.jpg"
                      entity.needEntity cid
                  p r.properties.display_name
              , onclick:(e) -> action 'selectentity', r

      div ->
          disabled = null
          if convsettings.selectedEntities.length <= 0 then disabled = disabled: 'disabled'
          button disabled, "OK", onclick:-> action 'saveconversation'

      mayRestoreInitialValues models
