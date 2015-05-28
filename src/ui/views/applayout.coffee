ipc = require 'ipc'
# status

statusView = (model) ->
  div class: 'self span2', ->
    div 'You: ' + model.self.username
    span 'Status: ' + model.connection

# conversations

conversationsListItemView = (conversation) ->
  div class: 'conversation', conversation.name, onclick: (e) ->
    e.preventDefault()
    ipc.send 'conversation:select', conversation.id

conversationsListView = (conversations) ->
  margin =
    style:
      marginTop: '60px'
  div class: 'conversations', ->
    (conversations || []).forEach conversationsListItemView

# messages

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
        if segment.type == "TEXT" or segment.type.k == "TEXT"
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
    div class: 'message', ->
      div class: 'user', messagesUtils.messageGetUsername(model, message)
      div class: 'body', messagesUtils.messageGetText(model, message)

messageInput = ->
  input onkeypress: (e) ->
    if e.keyCode == 13
      val = e.target.value
      e.target.value = ""
      ipc.send 'message:send', val

# main layout

module.exports = layout (model) ->
  console.log 'model', model
  if not model then return div 'Loading'
  div class:'applayout', ->
    div class:'row', ->
      div class:'left span2', region('left'), ->
        statusView model
        conversationsListView model.conversations
      div class:'main span10', region('main'), ->
        div class: 'message-list', ->
          messagesView model
        div class: 'message-input', ->
          messageInput model
