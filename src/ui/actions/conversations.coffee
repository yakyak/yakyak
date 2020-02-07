module.exports =
    _reset: () ->
        type: "RESET_CONVERSATIONS"
        payload: {}

    _initFromConvStates: (convs) ->
        type: "INIT_FROM_CONV_STATES"
        payload: {convs}

    add: (conv) ->
        type: "ADD_CONVERSATION"
        payload: {conversation: conv}

    addChatMessage: (msg) ->
        type: "ADD_CHAT_MESSAGE"
        payload: {msg}

    addChatMessagePlaceholder: (chat_id, {conv_id, client_generated_id, segsj, ts, uploadimage, message_action_type}) ->
        type: "ADD_CHAT_MESSAGE_PLACEHOLDER"
        payload: {chat_id, conv_id, client_generated_id, segsj, ts, uploadimage, message_action_type}

    addParticipant: (conv_id, participant) ->
        type: "ADD_PARTICIPANT"
        payload: {conv_id, participant}

    addWatermark: (ev) ->
        type: "ADD_WATERMARK"
        payload: {ev}

    addTyping: (typing) ->
        type: "ADD_TYPING"
        payload: {typing}

    deleteConv: (conv_id) ->
        type: "DELETE_CONV"
        payload: {conv_id}

    pruneTyping: (conv_id) ->
        type: "PRUNE_TYPING"
        payload: {conv_id}

    removeParticipants: (conv_id, ids) ->
        type: "REMOVE_PARTICIPANTS"
        payload: {conv_id, ids}

    rename: (conv_id, newname) ->
        type: "RENAME_CONVERSATION"
        payload: {conv_id, newName: newname}

    replaceFromStates: (states) ->
        type: "REPLACE_FROM_STATES"
        payload: {states}

    setNotificationLevel: (conv_id, level) ->
        type: "SET_NOTIFICATION_LEVEL"
        payload: {conv_id, level}

    updateAtTop: (attop) ->
        type: "UPDATE_AT_TOP"
        payload: {attop}

    updateMetadata: (state, redraw = true) ->
        type: "UPDATE_METADATA"
        payload: {state, redraw}

    updateHistory: (state) ->
        type: "UPDATE_HISTORY"
        payload: {state}

    # DEPRECATED
    updatePlaceholderImage: ({conv_id, client_generated_id, path}) ->
        type: "UPDATE_PLACEHOLDER_IMAGE"
        payload: {conv_id, client_generated_id, path}

    toggleStar: (conv) ->
        type: "TOGGLE_STAR"
        payload: {conv}
