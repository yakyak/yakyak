
{throttle} = require './vutil'
chilledaction = throttle 1500, action

unique = (obj) ->
  # unfortunately entities resulting from a search do not have
  # an unique id associated therefore we use serialized obkect
  # to compare them
  JSON.stringify obj

module.exports = view (models) ->
  {convsettings} = models

  div class: 'convadd', ->
    h1 'New conversation'

    div class: 'input', ->
        div ->
          input '', placeholder:'Search people', onkeyup: (e) ->
              chilledaction 'searchentities', e.currentTarget.value, 7

    ul ->
      convsettings.selectedEntities.forEach (r) ->
        li class: 'selected', ->
          if r.properties.photo_url
            img src: r.properties.photo_url
          p r.properties.display_name
        , onclick:(e) -> action 'deselectentity', r

      selected_ids = (unique(c) for c in convsettings.selectedEntities)

      convsettings.searchedEntities.forEach (r) ->
        if unique(r) in selected_ids then return
        li ->
          if r.properties.photo_url
            img src: r.properties.photo_url # TODO: put a default image if none
          p r.properties.display_name
        , onclick:(e) -> action 'selectentity', r

    div ->
      disabled = null
      if convsettings.selectedEntities.length <= 0 then disabled = disabled: 'disabled'
      button disabled, 'Create', onclick:-> action 'createconversation'
