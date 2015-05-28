ipc = require 'ipc'
# status

classify = (str) -> str.replace /[^a-zA-Z0-9_]/g, ''

statusView = (model) ->
  div class: 'self span2', ->
    div model.self.username
    span class:classify(model.connection), model.connection

# conversations

conversationsListItemView = (conversation) ->
  div class: 'conversation', conversation.name, onclick: (e) ->
    e.preventDefault()
    ipc.send 'conversation:select', conversation.id

conversationsListView = (conversations) ->
  div class: 'conversations', ->
    (conversations || []).forEach conversationsListItemView

# messages

messagesUtils =
  messageGetUsername: (model, event) =>
    chat_id = (event.sender_id || event.user_id).chat_id
    return model.identitiesById[chat_id].name

messageBodyView = (model, event) ->
  # Temporary doing this to get something to print
  # while narrowing the different cases
  text = []
  segments = event.chat_message.message_content.segment
  if segments
    segments.forEach (segment) ->
      type = segment.type.k or segment.type
      console.log type
      if type == "TEXT"
        span segment.text
      else if type == "LINK"
        console.log segment
        link = "<a href='#{segment.link_data.link_target}'>#{segment.text}</a>"
        a href: segment.link_data.link_target, ->
          segment.text
      else
        span "[#{JSON.stringify(segments)}]"
  if event.chat_message.message_content.attachment
    span "ATTACHMENT: need to figure out how to parse it"
    console.log JSON.stringify(event.chat_message.message_content.attachment, null, '  ')
    pre "[#{JSON.stringify(event.chat_message.message_content.attachment, null, '  ')}]"
  text = text.join " "
  return text


messagesView = (model) ->
  messages = model.messagesByConversationId[model.conversationCurrent] || []
  messages.forEach (message) ->
    div class: 'message', ->
      div class: 'user', messagesUtils.messageGetUsername(model, message)
      div class: 'body', ->
        messageBodyView model, message

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
