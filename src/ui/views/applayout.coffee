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


conversationsListItemView = (conversation) ->
  leftItem ->
    div conversation.name
    div conversation.timestamp

conversationsListView = (conversations) ->
  (conversations || []).forEach conversationsListItemView


messagesUtils =
  messageGetUsername: (model, event) =>
    chat_id = (event.sender_id || event.user_id).chat_id
    return model.identitiesById[chat_id].name
  messageGetText: (model, event) ->
    # Temporary doing this to get something to print
    # while narrowing the different cases
    text = []
    segments = event.chat_message.message_content.segment
    if segments
      segments.forEach (segment) ->
        if segment.type == "TEXT"
          text.push segment.text
        else
          text.push "[#{JSON.stringify(segment)}]"
    if event.chat_message.message_content.attachment
      text.push "[ATTACHMENT]"
    text = text.join " "
    return text


messagesView = (model) ->
  messages = model.messagesByConversationId[model.conversationCurrent] || []
  messages.forEach (message) ->
    messageLine =
      style:
        display: 'block'
        margin: '0px'
        _backgroundColor: 'green'
    div messageLine, ->
      opts =
        style:
          display: 'inline-block'
          width: '20%'
          overflow: 'hidden'
          _backgroundColor: 'red'
          textOverflow: 'ellipsis'
      div opts, messagesUtils.messageGetUsername(model, message)
        
      opts =
        style:
          display: 'inline-block'
          width: '80%'
          overflow: 'hidden'
          _backgroundColor: '#eee'
          paddingLeft: '10px'
      div opts, messagesUtils.messageGetText(model, message)


module.exports = layout (model) ->
  console.log 'model', model
  if not model then return div 'Loading'
  div class:'applayout', ->
    div class:'row', ->
      div class:'left span2', region('left'), ->
        statusView model
        conversationsListView model.conversations
      div class:'main span10', region('main'), ->
        messagesView model
