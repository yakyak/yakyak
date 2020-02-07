convSelector = require '../selectors/conversations'
convReducer = require '../reducers/conversations'
convAction = require '../actions/conversations'

merge   = (t, os...) -> t[k] = v for k,v of o when v not in [null, undefined] for o in os; t

stateStore = {conversations: {}}

funcs =
    MAX_UNREAD: convSelector.MAX_UNREAD
    _reset: ()                   -> convReducer(stateStore, convAction._reset())
    _initFromConvStates: (convs) -> convReducer(stateStore, convAction._initFromConvStates(convs))
    add: (conv)                  -> convReducer(stateStore, convAction.add(conv))
    addChatMessage: (msg)        -> convReducer(stateStore, convAction.addChatMessage(msg))
    addChatMessagePlaceholder: (chat_id, {conv_id, client_generated_id, segsj, ts, uploadimage, message_action_type}) -> convReducer(stateStore, convAction.addChatMessagePlaceholder(chat_id, {conv_id, client_generated_id, segsj, ts, uploadimage, message_action_type}))
    addParticipant: (conv_id, participant) -> convReducer(stateStore, convAction.addParticipant(conv_id, participant))
    addWatermark: (ev)           -> convReducer(stateStore, convAction.addWatermark(ev))
    addTyping: (typing)          -> convReducer(stateStore, convAction.addTyping(typing))
    deleteConv: (conv_id)        -> convReducer(stateStore, convAction.deleteConv(conv_id))
    pruneTyping: (conv_id)       -> convReducer(stateStore, convAction.pruneTyping(conv_id))
    removeParticipants: ()       -> convReducer(stateStore, convAction.removeParticipants())
    rename: (conv, newname)      -> convReducer(stateStore, convAction.rename(conv, newname))
    replaceFromStates: (states)  -> convReducer(stateStore, convAction.replaceFromStates(states))
    setNotificationLevel: (conv_id, level) -> convReducer(stateStore, convAction.setNotificationLevel(conv_id, level))
    updateAtTop: (attop)         -> convReducer(stateStore, convAction.updateAtTop(attop))
    updateMetadata: (state, redraw = true) -> convReducer(stateStore, convAction.updateMetadata(state, redraw))
    updateHistory: (state)       -> convReducer(stateStore, convAction.updateHistory(state))
    updatePlaceholderImage: ({conv_id, client_generated_id, path}) -> convReducer(stateStore, convAction.updatePlaceholderImage({conv_id, client_generated_id, path}))
    toggleStar: (conv)           -> convReducer(stateStore, convAction.toggleStar(conv))
    #
    count: () -> convSelector.count(stateStore)
    findLastReadEventsByUser: (conv) -> convSelector.findLastReadEventsByUser(conv)
    isQuiet: (c) -> convSelector.isQuiet(c)
    isStarred: (c) -> convSelector.isStarred(c)
    isPureHangout: convSelector.isPureHangout
    lastChanged: (c) -> convSelector.lastChanged(c)
    list: (sort = true) -> convSelector.list(stateStore, sort)
    redraw_conversation: () -> convSelector.redraw_conversation()
    unread: (conv) -> convSelector.unread(conv)
    unreadTotal: convSelector.unreadTotal

lookup = stateStore.conversations

module.exports = merge lookup, funcs
