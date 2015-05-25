leftItem = (fn) ->
  opts =
    style:
      padding: '.5em'
      borderBottom: '1px solid #aaa'
  div opts, fn

statusView = (model) ->
  leftItem ->
    div 'You: ' + model.self.username
    span 'Status: ' + model.connection


module.exports = layout (model) ->
    if not model then return div 'Loading'
    div class:'applayout', ->
        #div class:'top', region('top')
        div class:'row', ->
            div class:'left span2', region('left'), ->
                statusView model
            div class:'main span9', region('main')
