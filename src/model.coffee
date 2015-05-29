
class Status
  constructor: ->
    @connection = 'offline'
    @self =
      username: 'Unknown'
    @identitiesById = {}
    @conversations = []
    @conversationsById = {}
    @conversationCurrent = null
    @messagesByConversationId = {}
    @conversationScrollPosition = {}

  # managing fns
  identityAdd: (id, name) ->
    object = id: id, name: name
    @identitiesById[id] = object
  conversationsSort: () ->
    timestampDesc = (a, b) -> (parseInt a.ts) > (parseInt b.ts)
    @conversations = (@conversations.sort timestampDesc).reverse()
  conversationAdd: (id, name, participants, ts) ->
    object = id: id, name: name, participants: participants, ts: ts / 1000
    @conversations.push object
    @conversationsSort()
    @conversationsById[id] = object
  conversationUpdateTs: (id, ts) =>
    @conversations.forEach (c) ->
      if c.id == id
        c.ts = ts / 1000
    @conversationsSort()
  messageAdd: (event) =>
    id = event.conversation_id.id
    ts = event.timestamp
    @conversationUpdateTs id, ts
    if not @conversationCurrent then @conversationCurrent = id
    @messagesByConversationId[id] = @messagesByConversationId[id] || []
    @messagesByConversationId[id].push event
  conversationScrollPositionSet: (conversationId, scrollTop, atBottom) =>
    @conversationScrollPosition[conversationId] =
      scrollTop: scrollTop
      atBottom: atBottom
  conversationScrollPositionGet: (conversationId) ->
    def = scrollTop: 0, atBottom: true
    return @conversationScrollPosition[conversationId] || def

  # utils
  loadRecentConversations: (data) ->
    # extract conversations and partecipants
    data.conversation_state.forEach (conversation) =>
      conversation = conversation.conversation
      id = conversation.id.id
      sort_timestamp = conversation.self_conversation_state.sort_timestamp
      participants = []
      names = []
      conversation.participant_data.forEach (participant) =>
        if participant.fallback_name != @self.username # TODO should be based on user id
          @identityAdd participant.id.chat_id, participant.fallback_name
          participants.push participant.id.chat_id
          names.push participant.fallback_name
      name = names.join(", ")
      @conversationAdd id, name, participants, sort_timestamp
    # extract messages
    data.conversation_state.forEach (conversation) =>
      events = conversation.event
      for event in events
        if event.event_type == 'REGULAR_CHAT_MESSAGE'
          @messageAdd event
        else
          #console.log 'unhandled message type'
          #console.log JSON.stringify event, null, '  '
      

status = new Status()
status.test = -> console.log 'asf'

module.exports = status

if not module.parent
  onFile = (err, data) ->
    data = data.toString()
    data = JSON.parse data
    status.loadRecentConversations data
  fs = require 'fs'
  fs.readFile 'syncrecentconversations_response.json', onFile
