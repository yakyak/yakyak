
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
          placeholder = 'Type here to search people and add to conversation'
          input '', {placeholder}, onkeyup: (e) -> chilledaction 'searchentities', e.currentTarget.value, 7

    ul ->
      convsettings.selectedEntities.forEach (r) ->
        onclick = (e) -> action 'deselectentity', r
        li {onclick}, class: 'selected', ->
          if r.properties.photo_url
            img src: r.properties.photo_url
          p r.properties.display_name

      selected_ids = (unique(c) for c in convsettings.selectedEntities)

      convsettings.searchedEntities.forEach (r) ->
        if unique(r) in selected_ids then return
        onclick = (e) -> action 'selectentity', r
        li {onclick}, ->
          if r.properties.photo_url
            img src: r.properties.photo_url # TODO: put a default image if none
          p r.properties.display_name

    hr()
    
    div ->
      onclick = -> action 'createconversation'
      disabled = null
      if convsettings.selectedEntities.length <= 0 then disabled = disabled: 'disabled'
      button {onclick}, disabled, 'Create'
