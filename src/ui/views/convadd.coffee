fix =
  style:
    fontSize: '18px'
  placeholder: ' ... ... '


{throttle} = require './vutil'
chilledaction = throttle 1500, action

module.exports = view (models) ->
  {convsettings} = models

  div class: 'convadd', ->
    h1 'Conversation'
    hr()

    p 'Search and add people to this conversation'

    div class: 'input', ->
        div ->
          input fix, '', onkeyup: (e) -> chilledaction 'searchentities', e.currentTarget.value, 3

    ul ->
      convsettings.selectedEntities.forEach (r) ->
        onclick = (e) -> action 'deselectentity', r
        li {onclick}, class: 'selected', ->
          if r.properties.photo_url
            img src: r.properties.photo_url
          p r.properties.display_name
          console.log JSON.stringify r.properties, null, '  '
      convsettings.searchedEntities.forEach (r) ->
        onclick = (e) -> action 'selectentity', r
        li {onclick}, ->
          if r.properties.photo_url
            img src: r.properties.photo_url
          p r.properties.display_name
          console.log JSON.stringify r.properties, null, '  '


    hr()
    
    div ->
      onclick = -> action 'createconversation'
      disabled = convsettings.selectedEntities.length <= 0
      button fix, {onclick}, disabled: disabled, 'create'
