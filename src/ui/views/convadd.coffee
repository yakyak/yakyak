
{throttle} = require '../util'
chilledaction = throttle 1500, action

unique = (obj) -> obj.id.chat_id or obj.id.gaia_id

photoUrlProtocolFix = (url) -> return "http:" + url if url.match /^.?\/\//; url

inputSetValue = (sel, val) ->
    setTimeout ->
        el = document.querySelector sel
        el.value = val if el != null
    , 1
    null

module.exports = view (models) ->
    {convsettings} = models
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
              inputSetValue '.name-input', convsettings.name
      
      div class: 'input', ->
          div ->
              input
                  class: 'search-input'
                  placeholder:'Search people'
                  onkeyup: (e) ->
                      chilledaction 'searchentities', e.currentTarget.value, 7
                      action 'conversationquery', e.currentTarget.value, 7
              inputSetValue '.search-input', convsettings.searchQuery

      ul ->
          convsettings.selectedEntities.forEach (r) ->
              li class: 'selected', ->
                  if r.properties.photo_url
                      img src: photoUrlProtocolFix r.properties.photo_url
                  else
                      img src: "images/photo.jpg"
                  p r.properties.display_name
              , onclick:(e) -> action 'deselectentity', r

          selected_ids = (unique(c) for c in convsettings.selectedEntities)

          convsettings.searchedEntities.forEach (r) ->
              if unique(r) in selected_ids then return
              li ->
                  if r.properties.photo_url
                      img src: r.properties.photo_url
                  else
                      img src: "images/photo.jpg"
                  p r.properties.display_name
              , onclick:(e) -> action 'selectentity', r

      div ->
          disabled = null
          if convsettings.selectedEntities.length <= 0 then disabled = disabled: 'disabled'
          button disabled, "Save", onclick:-> action 'saveconversation'


