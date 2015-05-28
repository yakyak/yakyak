ipc = require 'ipc'
autosize = require 'autosize'

classify = (str) -> str.replace /[^a-zA-Z0-9_]/g, ''

# status

statusView = (model) ->
  div class:'self', ->
    div model.self.username
    span class:"status #{classify(model.connection)}", model.connection

# conversations

conversationsListItemView = (conversation) ->
  div class:'conversation', conversation.name, onclick: (e) ->
    e.preventDefault()
    ipc.send 'conversation:select', conversation.id

conversationsListView = (conversations) ->
  div class:'conversations-scroll', ->
    div class:'conversations', ->
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
      if type == "TEXT"
        span segment.text
      else if type == "LINK"
        link = "<a href='#{segment.link_data.link_target}'>#{segment.text}</a>"
        a href: segment.link_data.link_target, ->
          segment.text
      else if type == "LINE_BREAK"
        br()
      else
        pre "[#{JSON.stringify(segment)}]"
  if event.chat_message.message_content.attachment
    span "ATTACHMENT: need to figure out how to parse it"
    pre "#{JSON.stringify(event.chat_message.message_content.attachment, null, '  ')}"
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
  textarea rows:1,
  onkeypress: (e) ->
    if e.keyCode == 13
      e.preventDefault()
      val = e.target.value
      e.target.value = ""
      ipc.send 'message:send', val
  , onDOMNodeInserted: (e) ->
    setTimeout (-> autosize e.target), 10

ipc.on 'conversation:scroll', (value) ->
  document.body.querySelector('.message-list-scroll').scrollTop = value


# main layout
module.exports = layout (model) ->
  window.model = model # for debug
  if not model then return div 'Loading'
  div class:'applayout', ->
    div class:'row', ->
      div class:'left span3', region('left'), ->
        div class:'span12', ->
            statusView model
            conversationsListView model.conversations
      div class:'main span9', region('main'), ->
        div class:'messages', ->
          div class:'message-list-scroll', ->
            div class:'message-list', ->
              messagesView model
          div class:'message-xinput', ->
            messageInput model
