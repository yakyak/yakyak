
class Status
  constructor: ->
    @connection = 'offline'
    @self = undefined
    @identitiesById = {}
    @conversations = []
    @conversationsById = {}
    @conversationCurrent = null
    @messagesByConversationId = {}
  # managing fns
  identityAdd: (id, name, photo_url) ->
    identity = @identitiesById[id] or {}
    identity.id = identity.id or id
    identity.name = name or identity.name
    identity.photo_url = photo_url or identity.photo_url
    @identitiesById[id] = identity
  conversationsSort: () ->
    me = @identitiesById[@self].id
    timestampDesc = (a, b) ->
      (parseInt a.read_states[me]) > (parseInt b.read_states[me])
    @conversations = (@conversations.sort timestampDesc).reverse()
  conversationAdd: (id, name, participants, read_states) ->
    object =
      id: id
      name: name
      participants: participants
      read_states: read_states
      unreadCount: 0
    @conversations.push object
    @conversationsById[id] = object
    @conversationsSort()
  messageAdd: (event) =>
    id = event.conversation_id.id
    ts = event.timestamp
    if not @conversationCurrent then @conversationCurrent = id
    @messagesByConversationId[id] = @messagesByConversationId[id] || []
    @messagesByConversationId[id].push event
    conversation = @conversationsById[id]
    self = @identitiesById[@self]
    if id != @conversationCurrent
      if (parseInt conversation.read_states[self.id]) < (parseInt ts)
        conversation.unreadCount += 1
    else
      conversation.read_states[self.id] = ts
      @conversationsSort()

  # utils
  loadRecentConversations: (data) ->
    # extract conversations and partecipants
    data.conversation_state.forEach (conversation) =>
      conversation = conversation.conversation
      id = conversation.id.id
      read_states = {}
      conversation.read_state.forEach (state) ->
        read_states[state.participant_id.chat_id] = state.latest_read_timestamp
      participants = []
      names = []
      conversation.participant_data.forEach (participant) =>
        self = @identitiesById[@self]
        if participant.id.chat_id != self.id
          @identityAdd participant.id.chat_id, participant.fallback_name
          participants.push participant.id.chat_id
          names.push participant.fallback_name
      name = conversation.name ? names.join(", ")
      @conversationAdd id, name, participants, read_states
    # extract messages
    data.conversation_state.forEach (conversation) =>
      events = conversation.event
      for event in events
        if event.event_type == 'REGULAR_CHAT_MESSAGE'
          @messageAdd event
        else
          console.log 'unhandled message type'
          console.log JSON.stringify event, null, '  '


status = new Status()

module.exports = status

if not module.parent
  onFile = (err, data) ->
    data = data.toString()
    data = JSON.parse data
    status.loadRecentConversations data
  fs = require 'fs'
  fs.readFile 'syncrecentconversations_response.json', onFile
