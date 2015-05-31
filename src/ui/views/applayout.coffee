ipc = require 'ipc'
autosize = require 'autosize'
shell = require 'shell'


classify = (str) -> str.replace /[^a-zA-Z0-9_]/g, ''

# status

statusView = (model) ->
  div class:'self', ->
    self = model.identitiesById[model.self]
    if not self then return
    if self.photo_url
      img src: "http:" + self.photo_url
    div self.name
    span class:"status #{classify(model.connection)}", model.connection

# conversations

conversationsListItemView = (conversation) ->
  conversationName = conversation.name || 'Unknown'
  if conversationName.length > 55
    conversationName = conversationName.substr 0, 55
    conversationName += "..."
  unread = conversation.unreadCount
  if unread then conversationName += " (#{unread})"
  cls = 'conversation'
  if conversation.id == @model.conversationCurrent then cls += " selected"
  div class: cls, conversationName, onclick: (e) ->
    e.preventDefault()
    ipc.send 'conversation:select', conversation.id

conversationsListView = (conversations, model) ->
  div class:'conversations-scroll', ->
    div class:'conversations', ->
      (conversations || []).forEach (conversation) ->
        conversationsListItemView conversation, model

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
        cls = (k for k, v of segment.formatting when v).join ' '
        span class: cls, segment.text
      else if type == "LINK"
        onClick = (e) ->
          e.preventDefault()
          shell.openExternal segment.link_data.link_target
        a href: segment.link_data.link_target, onclick: onClick, ->
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


lastuser = null
messagesView = (model) ->
  messages = model.messagesByConversationId[model.conversationCurrent] || []
  messages.forEach (message) ->
    div class: 'message', ->
      chat_id = (message.sender_id || message.user_id).chat_id
      user = model.identitiesById[chat_id].name || 'Unknown'
      if user != lastuser
        div class: 'user', user
        lastuser = user

      div class: 'body', ->
        messageBodyView model, message
        div class: 'timestamp', ->
          today = new Date()
          date = new Date(message.timestamp / 1000)
          if today.toLocaleDateString() == date.toLocaleDateString()
            date = date.toLocaleTimeString()
          else
            date = date.toLocaleString()
          return date


messageInput = ->
  textarea rows:1,
  onkeypress: (e) ->
    if e.keyCode == 13
      e.preventDefault()
      val = e.target.value
      e.target.value = ""
      evt = document.createEvent 'Event'
      evt.initEvent 'autosize:update', true, false
      e.target.dispatchEvent evt
      ipc.send 'message:send', val
  , onDOMNodeInserted: (e) ->
    setTimeout (-> autosize e.target), 10


# main layout

module.exports = layout (model) ->
  window.model = model # for debug
  if not model then return div 'Loading'
  div class:'applayout', ->
    div class:'row', ->
      div class:'left span3', region('left'), ->
        div class:'span12', ->
            statusView model
            conversationsListView model.conversations, model
      focusTextAreaOnClick = onclick: (e) ->
        if window.getSelection().toString().length > 1
          return # let the user select
        document.body.querySelector('.message-xinput textarea').focus()
      div class:'main span9', focusTextAreaOnClick, region('main'), ->
        div class:'messages', ->
          div class:'message-list-scroll', ->
            div class:'message-list', ->
              messagesView model
          div class:'message-xinput', ->
            messageInput model
  setTimeout ->
    document.querySelector('.message-list-scroll')?.scrollTop = Number.MAX_VALUE
  , 10
