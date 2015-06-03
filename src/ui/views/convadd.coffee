fix =
  style:
    fontSize: '18px'
  placeholder: ' ... ... '


module.exports = view (models) ->
  {viewstate} = models

  div ->
    h1 'add new conversation'
    br()
    br()

    p 'find ppl'
    input fix, '', onkeyup: (e) ->
      action 'searchentities', e.currentTarget.value, 3
    br()
    br()

    p 'search results'
    ul ->
      viewstate.searchedEntities.forEach (r) ->
        onclick = (e) -> action 'selectentity', r
        li {onclick}, JSON.stringify r.properties
    br()
    br()
    
    p 'selected ppl'
    ul ->
      viewstate.selectedEntities.forEach (r) ->
        onclick = (e) -> action 'deselectentity', r
        li {onclick}, JSON.stringify r.properties
    br()
    br()
    
    div ->
      onclick = -> action 'createconversation'
      button fix, {onclick}, 'create'
