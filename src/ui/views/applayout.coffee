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
  conversationName = conversation.name || 'Unknown'
  unread = conversation.unreadCount
  if unread then conversationName += " #{unread}"
  div class:'conversation', conversationName, onclick: (e) ->
    e.preventDefault()
    ipc.send 'conversation:select', conversation.id

conversationsListView = (conversations) ->
  div class:'conversations-scroll', ->
    div class:'conversations', ->
      (conversations || []).forEach conversationsListItemView

# messages

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
      div class: 'user', ->
        chat_id = (message.sender_id || message.user_id).chat_id
        user = model.identitiesById[chat_id].name || 'Unknown'
      div class: 'timestamp', ->
        today = new Date()
        date = new Date(message.timestamp / 1000)
        if today.toLocaleDateString() == date.toLocaleDateString()
          date = date.toLocaleTimeString()
        else
          date = date.toLocaleString()
        return date
        
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

ipc.on 'message-list:scroll', (value) ->
  # we should scroll to bottom only if we were already at bottom before
  document.body.querySelector('.message-list-scroll').scrollTop = value

messageListScrollOnScroll = (e) ->
  messageListScroll = document.querySelector '.message-list-scroll'
  content = messageListScroll.children[0]
  heightCurrent = messageListScroll.offsetHeight + messageListScroll.scrollTop
  threshold = 10
  bottom = (content.offsetHeight - heightCurrent) < threshold # we are at bottom
  ipc.send 'message-list:scroll', messageListScroll.scrollTop, bottom

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
      focusTextAreaOnClick = onclick: (e) ->
        if window.getSelection().toString().length > 1
          return # let the user select
        document.body.querySelector('.message-xinput textarea').focus()
      div class:'main span9', focusTextAreaOnClick, region('main'), ->
        div class:'messages', ->
          opts = onscroll: messageListScrollOnScroll
          div class:'message-list-scroll', opts, ->
            div class:'message-list', ->
              messagesView model
          div class:'message-xinput', ->
            messageInput model
